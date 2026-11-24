package main

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

func fixture(t *testing.T, files map[string]string) string {
	t.Helper()
	root := t.TempDir()
	for name, body := range files {
		file := filepath.Join(root, name)
		if err := os.MkdirAll(filepath.Dir(file), 0700); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(file, []byte(body), 0600); err != nil {
			t.Fatal(err)
		}
	}
	return root
}

func scanFixture(t *testing.T, root string) *Graph {
	t.Helper()
	g, err := scanProject(context.Background(), root, scanOptions{})
	if err != nil {
		t.Fatal(err)
	}
	ids := map[string]bool{}
	for _, n := range g.Nodes {
		if ids[n.ID] {
			t.Fatalf("duplicate node %s", n.ID)
		}
		ids[n.ID] = true
	}
	for _, e := range g.Edges {
		if !ids[e.From] || !ids[e.To] {
			t.Fatalf("dangling edge %+v", e)
		}
	}
	return g
}

func nodeNamed(t *testing.T, g *Graph, name, kind string) Node {
	t.Helper()
	for _, n := range g.Nodes {
		if n.Name == name && n.Kind == kind {
			return n
		}
	}
	t.Fatalf("missing %s %s", kind, name)
	return Node{}
}

func TestGoGraphSourceIdentityAndImports(t *testing.T) {
	root := fixture(t, map[string]string{
		"go.mod":            "module example.test/demo\n\ngo 1.22\n",
		"main.go":           "package demo\nimport \"example.test/demo/store\"\ntype Cache[T any] struct { value T }\nfunc (c *Cache[T]) Get() T { return c.value }\nfunc init() {}\nfunc init() {}\nvar _ store.Port\n",
		"store/port.go":     "package store\ntype Port interface { Save() error }\n",
		"main_test.go":      "package demo\nfunc excluded() {}\n",
		"vendor/ignored.go": "broken source\n",
	})
	g := scanFixture(t, root)
	n := nodeNamed(t, g, "Get", "method")
	if n.Parent != "go:example.test/demo#Cache" || n.Line != 4 || n.ReportName != "Cache.Get" {
		t.Fatalf("incorrect receiver or source location: %+v", n)
	}
	want := Edge{"go:example.test/demo", "go:example.test/demo/store", "imports"}
	found := false
	for _, e := range g.Edges {
		found = found || e == want
	}
	if !found {
		t.Fatalf("missing import edge: %+v", g.Edges)
	}
	for _, n := range g.Nodes {
		if n.Name == "excluded" {
			t.Fatal("test declarations included by default")
		}
	}
}

func TestJavaGraphOverloadsNestingAndInheritance(t *testing.T) {
	if _, err := exec.LookPath("javac"); err != nil {
		t.Skip("JDK required")
	}
	root := fixture(t, map[string]string{
		"src/main/java/demo/Port.java":  "package demo;\npublic interface Port { String get(); }\n",
		"src/main/java/demo/Store.java": "package demo;\npublic class Store implements Port {\n public String get() { return \"x\"; }\n public String get(int key) { return \"y\"; }\n private int size;\n public static class Nested { public void run() {} }\n}\n",
		"src/test/java/demo/Bad.java":   "invalid",
	})
	g := scanFixture(t, root)
	port := nodeNamed(t, g, "Port", "interface")
	store := nodeNamed(t, g, "Store", "class")
	nested := nodeNamed(t, g, "Nested", "class")
	if nested.Parent != store.ID {
		t.Fatalf("nested class parent %+v", nested)
	}
	found := false
	for _, e := range g.Edges {
		found = found || e == (Edge{store.ID, port.ID, "implements"})
	}
	if !found {
		t.Fatalf("missing implements edge %+v", g.Edges)
	}
	count := 0
	for _, n := range g.Nodes {
		if n.Name == "get" && n.Parent == store.ID {
			count++
		}
	}
	if count != 2 {
		t.Fatalf("lost overloaded methods: %d", count)
	}
	_, err := crapRecords(g, "java", "CRAP Report\nget demo.Store 1 100.0% 1.0\n")
	if err == nil || !strings.Contains(err.Error(), "ambiguous") {
		t.Fatalf("ambiguous report should be refused: %v", err)
	}
}

func TestParseErrorsSurface(t *testing.T) {
	root := fixture(t, map[string]string{"bad.go": "package x\nfunc broken("})
	_, err := scanProject(context.Background(), root, scanOptions{})
	if err == nil {
		t.Fatal("syntax error hidden")
	}
}

func TestCrapAndMutationReportsPersistAndBecomeStale(t *testing.T) {
	t.Setenv("XDG_CACHE_HOME", t.TempDir())
	root := fixture(t, map[string]string{
		"go.mod":      "module example.test/demo\n\ngo 1.22\n",
		"foo.go":      "package demo\nfunc Foo(v int) int {\n if v > 1 { return 1 }\n return 0\n}\n",
		"foo_test.go": "package demo\n",
	})
	g := scanFixture(t, root)
	crap, err := crapRecords(g, "go", "CRAP Report\n===========\nFunction Package CC Cov% CRAP\nFoo demo 2 75.0% 2.1\n")
	if err != nil || len(crap) != 1 || *crap[0].Values.Coverage != 75 {
		t.Fatalf("CRAP parse: %+v %v", crap, err)
	}
	report := "Uncovered mutations:\n  line 4 0 -> 1 Foo\n[1/2] killed line 3 > -> <=: Foo\n[2/2] worker-1 survived line 3 1 -> 0: Foo\n\nMutation Report\nKilled: 1\nSurvived: 1\nUncovered: 1\nSurvivors:\n  line 3 1 -> 0 Foo\n"
	mutation, err := mutationRecords(g, "go", "foo.go", report)
	if err != nil || len(mutation) != 1 {
		t.Fatalf("mutation parse: %+v %v", mutation, err)
	}
	m := mutation[0].Values
	if *m.Killed != 1 || *m.Survived != 1 || *m.Uncovered != 1 {
		t.Fatalf("double counted or lost results: %+v", m)
	}
	if err := saveMetrics(root, "crap", crap); err != nil {
		t.Fatal(err)
	}
	if err := saveMetrics(root, "mutation", mutation); err != nil {
		t.Fatal(err)
	}
	fresh := nodeNamed(t, scanFixture(t, root), "Foo", "function").Metrics
	if fresh == nil || fresh.Stale || *fresh.Survived != 1 || *fresh.CRAP != 2.1 {
		t.Fatalf("fresh merged overlay: %+v", fresh)
	}
	// Updating a test invalidates result provenance even with unchanged source.
	os.WriteFile(filepath.Join(root, "foo_test.go"), []byte("package demo\n// changed tests\n"), 0600)
	stale := nodeNamed(t, scanFixture(t, root), "Foo", "function").Metrics
	if stale == nil || !stale.Stale {
		t.Fatalf("test edit did not stale results: %+v", stale)
	}
}

func TestJavaMutationUsesNarrowestSourceScope(t *testing.T) {
	g := &Graph{Hashes: map[string]string{"src/X.java": "hash"}, InputHash: "inputs",
		Nodes: []Node{{ID: "type", Lang: "java", File: "src/X.java", Line: 1, EndLine: 9, Kind: "class"},
			{ID: "method", Lang: "java", File: "src/X.java", Line: 3, EndLine: 6, Kind: "method"}}}
	report := "KILLED src/X.java:4 true -> false (20 ms)\nSURVIVED src/X.java:5 + -> - (18 ms)\nUNCOVERED src/X.java:6 0 -> 1\nCoverage: 1 uncovered sites skipped.\nSummary: 1 killed, 1 survived, 2 total.\n"
	records, err := mutationRecords(g, "java", "", report)
	if err != nil || len(records) != 1 || records[0].NodeID != "method" || *records[0].Values.Survived != 1 {
		t.Fatalf("Java results: %+v %v", records, err)
	}
}

func TestIncompleteMutationReportIsRefused(t *testing.T) {
	g := &Graph{Hashes: map[string]string{"x.go": "hash"}, Nodes: []Node{
		{ID: "F", Lang: "go", File: "x.go", Line: 1, EndLine: 5, Kind: "function"},
	}}
	_, err := mutationRecords(g, "go", "x.go", "[1/2] killed line 3 x: F\nMutation Report\nKilled: 2\nSurvived: 0\nUncovered: 0\n")
	if err == nil || !strings.Contains(err.Error(), "do not match") {
		t.Fatalf("incomplete result data accepted: %v", err)
	}
}

func TestManifestDoesNotInvalidateSourceButStringsStillDo(t *testing.T) {
	base := "package demo\nfunc Foo() {}\n"
	withManifest := base + "\n// mutate4go-manifest-begin\n// {}\n// mutate4go-manifest-end\n"
	if sourceDigest([]byte(base)) != sourceDigest([]byte(withManifest)) {
		t.Fatal("manifest-only change invalidated source")
	}
	a := "package demo\nvar x=`\n// mutate4go-manifest-begin\nold`\n"
	b := strings.Replace(a, "old", "new", 1)
	if sourceDigest([]byte(a)) == sourceDigest([]byte(b)) {
		t.Fatal("marker inside a string swallowed a source change")
	}
}

func TestHTTPAuthenticationSourceBoundaryAndRequests(t *testing.T) {
	t.Setenv("XDG_CACHE_HOME", t.TempDir())
	root := fixture(t, map[string]string{"demo.go": "package demo\nfunc Foo() {}\n"})
	v := &viewer{graph: scanFixture(t, root), token: "test-token"}
	server := httptest.NewServer(v.handler())
	defer server.Close()
	request := func(method, path, body, token string) *http.Response {
		t.Helper()
		req, _ := http.NewRequest(method, server.URL+path, strings.NewReader(body))
		req.Header.Set("Authorization", "Bearer "+token)
		r, err := http.DefaultClient.Do(req)
		if err != nil {
			t.Fatal(err)
		}
		t.Cleanup(func() { r.Body.Close() })
		return r
	}
	if r := request("GET", "/api/graph", "", "wrong"); r.StatusCode != 401 {
		t.Fatalf("unauthenticated graph status %d", r.StatusCode)
	}
	if r := request("GET", "/api/source?file=../secret", "", "test-token"); r.StatusCode != 400 {
		t.Fatalf("traversal status %d", r.StatusCode)
	}
	if r := request("GET", "/api/source?file=demo.go", "", "test-token"); r.StatusCode != 200 {
		t.Fatalf("valid source status %d", r.StatusCode)
	}
	r := request("POST", "/api/requests", `{"action":"inspect","target":"go:demo","prompt":"","proposal":""}`, "test-token")
	var queued Request
	if err := json.NewDecoder(r.Body).Decode(&queued); err != nil || queued.ID == "" {
		t.Fatalf("queue request: %+v %v", queued, err)
	}
	got, err := loadRequests(root)
	if err != nil || len(got) != 1 || got[0].ID != queued.ID {
		t.Fatalf("persisted inbox %+v %v", got, err)
	}
	outside := fixture(t, map[string]string{"secret": "private"})
	os.Remove(filepath.Join(root, "demo.go"))
	os.Symlink(filepath.Join(outside, "secret"), filepath.Join(root, "demo.go"))
	if r := request("GET", "/api/source?file=demo.go", "", "test-token"); r.StatusCode != 400 {
		t.Fatalf("symlink escape status %d", r.StatusCode)
	}
}

func TestSnapshotValidationAndUnknownProvenance(t *testing.T) {
	t.Setenv("XDG_CACHE_HOME", t.TempDir())
	root := fixture(t, map[string]string{"x.go": "package x\nfunc F() {}\n"})
	g := scanFixture(t, root)
	n := nodeNamed(t, g, "F", "function")
	value := 3.0
	r := MetricRecord{NodeID: n.ID, File: n.File, Line: n.Line, Values: Metrics{CRAP: &value}}
	if err := validateRecords(g, "crap", []MetricRecord{r}); err != nil {
		t.Fatal(err)
	}
	if err := saveMetrics(root, "crap", []MetricRecord{r}); err != nil {
		t.Fatal(err)
	}
	if m := nodeNamed(t, scanFixture(t, root), "F", "function").Metrics; m == nil || !m.Stale {
		t.Fatalf("missing provenance presented as fresh: %+v", m)
	}
	value = -1
	if err := validateRecords(g, "crap", []MetricRecord{r}); err == nil {
		t.Fatal("negative CRAP accepted")
	}
}
