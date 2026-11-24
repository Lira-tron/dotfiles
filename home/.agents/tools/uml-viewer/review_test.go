package main

import (
	"bytes"
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
	"testing"
)

func testGit(t *testing.T, repo string, args ...string) string {
	t.Helper()
	out, err := gitText(context.Background(), repo, args...)
	if err != nil {
		t.Fatal(err)
	}
	return out
}

// Build synthetic history in disposable test repositories, without staging or
// committing any user work and without git add, git commit, or git push.
func importHistory(t *testing.T, repo, parent string, files map[string]string) string {
	t.Helper()
	var stream bytes.Buffer
	stream.WriteString("commit refs/heads/main\ncommitter Test <test@example.invalid> 1700000000 +0000\ndata 7\nfixture\n")
	if parent != "" {
		fmt.Fprintf(&stream, "from %s\n", parent)
	}
	names := make([]string, 0, len(files))
	for name := range files {
		names = append(names, name)
	}
	sort.Strings(names)
	for _, name := range names {
		body := files[name]
		fmt.Fprintf(&stream, "M 100644 inline %q\ndata %d\n%s\n", name, len(body), body)
	}
	stream.WriteString("\ndone\n")
	cmd := exec.Command("git", "-C", repo, "fast-import", "--quiet")
	cmd.Stdin = &stream
	if out, err := cmd.CombinedOutput(); err != nil {
		t.Fatalf("fixture history: %v %s", err, out)
	}
	return testGit(t, repo, "rev-parse", "refs/heads/main")
}

func reviewRepo(t *testing.T, files map[string]string) (string, string, string) {
	t.Helper()
	parent := t.TempDir()
	remote, local := filepath.Join(parent, "remote.git"), filepath.Join(parent, "work")
	if err := os.MkdirAll(remote, 0700); err != nil {
		t.Fatal(err)
	}
	testGit(t, remote, "init", "--bare", "--quiet")
	testGit(t, remote, "symbolic-ref", "HEAD", "refs/heads/main")
	base := importHistory(t, remote, "", files)
	testGit(t, parent, "clone", "--quiet", remote, local)
	return local, remote, base
}

func writeReviewFile(t *testing.T, root, path, body string) {
	t.Helper()
	path = filepath.Join(root, path)
	if err := os.MkdirAll(filepath.Dir(path), 0700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, []byte(body), 0600); err != nil {
		t.Fatal(err)
	}
}

func stageFixtureFile(t *testing.T, root, path string) {
	t.Helper()
	hash := testGit(t, root, "hash-object", "-w", path)
	testGit(t, root, "update-index", "--add", "--cacheinfo", "100644", hash, path)
}

func TestUnpushedReviewIncludesAllLocalChangeKinds(t *testing.T) {
	files := map[string]string{
		"go.mod":       "module example.test/review\n\ngo 1.22\n",
		".gitignore":   "ignored.go\n",
		"committed.go": "package review\nfunc Committed() int { return 1 }\n",
		"staged.go":    "package review\nfunc Staged() int { return 1 }\n",
		"dirty.go":     "package review\nfunc Dirty() int { return 1 }\n",
		"removed.go":   "package review\nfunc Removed() {}\n",
		"old.go":       "package review\nfunc Renamed() {}\n",
		"unchanged.go": "package review\nfunc Unchanged() {}\n",
	}
	root, _, base := reviewRepo(t, files)
	newBody := "package review\nfunc Committed() int { return 2 }\n"
	importHistory(t, root, base, map[string]string{"committed.go": newBody})
	testGit(t, root, "read-tree", "HEAD")
	writeReviewFile(t, root, "committed.go", newBody)
	writeReviewFile(t, root, "staged.go", "package review\nfunc Staged() int { return 2 }\n")
	stageFixtureFile(t, root, "staged.go")
	writeReviewFile(t, root, "dirty.go", "package review\nfunc Dirty() int { return 3 }\n")
	if err := os.Remove(filepath.Join(root, "removed.go")); err != nil {
		t.Fatal(err)
	}
	if err := os.Rename(filepath.Join(root, "old.go"), filepath.Join(root, "renamed.go")); err != nil {
		t.Fatal(err)
	}
	testGit(t, root, "update-index", "--force-remove", "old.go")
	stageFixtureFile(t, root, "renamed.go")
	writeReviewFile(t, root, "new space.go", "package review\nfunc NewCode() {}\n")
	writeReviewFile(t, root, "changed_test.go", "package review\nfunc ChangedTest() {}\n")
	writeReviewFile(t, root, "ignored.go", "package review\nfunc Ignored() {}\n")
	baseRef, err := fetchReviewBase(context.Background(), root, "")
	if err != nil {
		t.Fatal(err)
	}
	g, err := scanProject(context.Background(), root, scanOptions{Unpushed: true, Base: baseRef})
	if err != nil {
		t.Fatal(err)
	}
	if g.Review.LocalCommits != 1 || g.Review.BaseRef != "origin/main" || g.Review.MergeBase != base {
		t.Fatalf("wrong baseline: %+v", g.Review)
	}
	changes := map[string]ChangedFile{}
	for _, f := range g.Review.Files {
		changes[f.Path] = f
	}
	for file, status := range map[string]string{
		"committed.go": "modified", "staged.go": "modified", "dirty.go": "modified",
		"removed.go": "deleted", "renamed.go": "renamed", "new space.go": "untracked",
		"changed_test.go": "untracked",
	} {
		if changes[file].Status != status {
			t.Errorf("%s: got %+v, want %s", file, changes[file], status)
		}
	}
	if changes["renamed.go"].OldPath != "old.go" || len(changes) != 7 {
		t.Fatalf("incorrect selection: %+v", changes)
	}
	for _, n := range g.Nodes {
		if n.Name == "Unchanged" || n.Name == "Ignored" || n.Name == "Removed" {
			t.Fatalf("unrelated/deleted source declaration leaked into graph: %+v", n)
		}
	}
	nodeNamed(t, g, "ChangedTest", "function")
	nodeNamed(t, g, "removed.go", "deleted file")
}

func TestUpstreamOnlyChangesAreNotReviewed(t *testing.T) {
	root, remote, base := reviewRepo(t, map[string]string{"a.go": "package a\nfunc A() {}\n"})
	upstream := importHistory(t, remote, base, map[string]string{"remote.go": "package a\nfunc RemoteOnly() {}\n"})
	ref, err := fetchReviewBase(context.Background(), root, "")
	if err != nil {
		t.Fatal(err)
	}
	scope, err := reviewScope(context.Background(), root, ref)
	if err != nil {
		t.Fatal(err)
	}
	if scope.BaseCommit != upstream || scope.MergeBase != base || scope.LocalCommits != 0 || len(scope.Files) != 0 {
		t.Fatalf("remote-only changes were attributed locally: %+v", scope)
	}
	// A local commit on the other side of the divergence is still included.
	importHistory(t, root, base, map[string]string{"local.go": "package a\nfunc Local() {}\n"})
	testGit(t, root, "read-tree", "HEAD")
	writeReviewFile(t, root, "local.go", "package a\nfunc Local() {}\n")
	scope, err = reviewScope(context.Background(), root, ref)
	if err != nil || len(scope.Files) != 1 || scope.Files[0].Path != "local.go" || scope.LocalCommits != 1 {
		t.Fatalf("diverged branch scope: %+v %v", scope, err)
	}
}

func TestReviewTracksNewlyPublishedCommitsAndMissingUpstream(t *testing.T) {
	root, remote, base := reviewRepo(t, map[string]string{"a.go": "package a\nfunc A() {}\n"})
	importHistory(t, root, base, map[string]string{"b.go": "package a\nfunc B() {}\n"})
	testGit(t, root, "read-tree", "HEAD")
	writeReviewFile(t, root, "b.go", "package a\nfunc B() {}\n")
	before, err := reviewScope(context.Background(), root, "")
	if err != nil {
		t.Fatal(err)
	}
	// The disposable remote pulls the commit; no push command is used.
	testGit(t, remote, "fetch", "--quiet", root, "main:refs/heads/main")
	ref, err := fetchReviewBase(context.Background(), root, "")
	if err != nil {
		t.Fatal(err)
	}
	after, err := reviewScope(context.Background(), root, ref)
	if err != nil || len(after.Files) != 0 || after.Fingerprint == before.Fingerprint {
		t.Fatalf("published commit retained: %+v %v", after, err)
	}
	testGit(t, root, "branch", "--unset-upstream")
	if _, err := fetchReviewBase(context.Background(), root, ""); err == nil || !strings.Contains(err.Error(), "--base") {
		t.Fatalf("missing upstream should request a baseline: %v", err)
	}
	if _, err := fetchReviewBase(context.Background(), root, "origin/main"); err != nil {
		t.Fatalf("explicit baseline failed: %v", err)
	}
	testGit(t, root, "remote", "set-url", "origin", filepath.Join(t.TempDir(), "missing"))
	if _, err := fetchReviewBase(context.Background(), root, "origin/main"); err == nil || !strings.Contains(err.Error(), "review cancelled") {
		t.Fatalf("fetch failure was hidden: %v", err)
	}
}

func TestReviewRootScopeAndIndexOnlyChange(t *testing.T) {
	root, _, _ := reviewRepo(t, map[string]string{
		"go.mod":      "module example.test/review\n\ngo 1.22\n",
		"module/x.go": "package module\nfunc X() {}\n",
		"other/y.go":  "package other\nfunc Y() {}\n",
	})
	writeReviewFile(t, root, "module/x.go", "package module\nfunc X() { println(1) }\n")
	stageFixtureFile(t, root, "module/x.go")
	writeReviewFile(t, root, "module/x.go", "package module\nfunc X() {}\n")
	writeReviewFile(t, root, "other/y.go", "package other\nfunc Y() { println(2) }\n")
	scope, err := reviewScope(context.Background(), filepath.Join(root, "module"), "origin/main")
	if err != nil || len(scope.Files) != 1 || scope.Files[0].Path != "x.go" || !scope.Files[0].IndexOnly {
		t.Fatalf("subdirectory/index-only scope: %+v %v", scope, err)
	}
}

func TestReviewJavaFilesAndEmptyGraph(t *testing.T) {
	if _, err := exec.LookPath("javac"); err != nil {
		t.Skip("JDK required")
	}
	root, _, _ := reviewRepo(t, map[string]string{
		"src/main/java/demo/A.java": "package demo;\npublic class A { public int count() { return 1; } }\n",
		"src/main/java/demo/B.java": "package demo;\npublic class B {}\n",
	})
	clean, err := scanProject(context.Background(), root, scanOptions{Unpushed: true})
	if err != nil || len(clean.Nodes) != 0 || clean.Edges == nil {
		t.Fatalf("clean review should be an empty JSON graph: %+v %v", clean, err)
	}
	writeReviewFile(t, root, "src/main/java/demo/A.java", "package demo;\npublic class A { public int count() { return 2; } }\n")
	g, err := scanProject(context.Background(), root, scanOptions{Unpushed: true})
	if err != nil {
		t.Fatal(err)
	}
	a := nodeNamed(t, g, "A", "class")
	if a.Change != "modified" {
		t.Fatalf("Java change status: %+v", a)
	}
	for _, n := range g.Nodes {
		if n.Name == "B" {
			t.Fatal("unchanged Java class leaked into review")
		}
	}
}

func TestParseGitNamesPreservesWhitespace(t *testing.T) {
	files, err := parseChangedFiles([]byte("R100\x00old name.go\x00new\nname.go\x00M\x00tab\tname.java\x00"))
	if err != nil || len(files) != 2 || files[0].Path != "new\nname.go" || files[1].Path != "tab\tname.java" {
		t.Fatalf("NUL-separated Git paths corrupted: %+v %v", files, err)
	}
}
