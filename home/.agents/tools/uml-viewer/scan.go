package main

import (
	"bytes"
	"context"
	"crypto/sha256"
	_ "embed"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"go/ast"
	"go/format"
	"go/parser"
	"go/token"
	"io/fs"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
)

//go:embed java/Scan.java
var javaSource []byte

type scanOptions struct {
	Tests    bool
	Unpushed bool
	Base     string
}

func canonicalRoot(root string) (string, error) {
	p, err := filepath.Abs(root)
	if err != nil {
		return "", err
	}
	p, err = filepath.EvalSymlinks(p)
	if err != nil {
		return "", err
	}
	info, err := os.Stat(p)
	if err != nil {
		return "", err
	}
	if !info.IsDir() {
		return "", fmt.Errorf("project root must be a directory: %s", p)
	}
	return p, nil
}

func sourceFiles(root string, tests bool) ([]string, error) {
	var files []string
	err := filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		name := d.Name()
		if d.IsDir() {
			if path != root && (strings.HasPrefix(name, ".") || name == "vendor" ||
				name == "node_modules" || name == "target" || name == "build" ||
				name == "out" || name == "testdata" ||
				(!tests && (name == "test" || name == "tests"))) {
				return filepath.SkipDir
			}
			return nil
		}
		if !d.Type().IsRegular() || (!strings.HasSuffix(name, ".go") && !strings.HasSuffix(name, ".java")) {
			return nil
		}
		if !tests && strings.HasSuffix(name, "_test.go") {
			return nil
		}
		files = append(files, path)
		return nil
	})
	return files, err
}

func scanProject(ctx context.Context, root string, options scanOptions) (*Graph, error) {
	root, err := canonicalRoot(root)
	if err != nil {
		return nil, err
	}
	files, err := sourceFiles(root, options.Tests || options.Unpushed)
	if err != nil {
		return nil, err
	}
	g := &Graph{Version: 1, Root: root, Name: filepath.Base(root),
		Nodes: []Node{}, Edges: []Edge{}, Hashes: map[string]string{}, Warnings: []string{}}
	g.InputHash, err = projectInputHash(root)
	if err != nil {
		return nil, err
	}
	var javaFiles []string
	packages := map[string]bool{}
	for _, file := range files {
		if err := ctx.Err(); err != nil {
			return nil, err
		}
		data, err := os.ReadFile(file)
		if err != nil {
			return nil, err
		}
		if bytes.Contains(data, []byte("Code generated")) && bytes.Contains(data, []byte("DO NOT EDIT.")) {
			continue
		}
		rel, _ := filepath.Rel(root, file)
		rel = filepath.ToSlash(rel)
		g.Hashes[rel] = sourceDigest(data)
		if strings.HasSuffix(file, ".java") {
			javaFiles = append(javaFiles, file)
		} else if err := scanGo(g, rel, data, packages); err != nil {
			return nil, err
		}
	}
	if len(javaFiles) > 0 {
		if err := scanJava(ctx, g, javaFiles); err != nil {
			return nil, err
		}
	}
	// Package edges to libraries outside the project remain visible as external nodes.
	ids := map[string]bool{}
	for _, n := range g.Nodes {
		ids[n.ID] = true
	}
	for _, e := range g.Edges {
		if !ids[e.To] {
			lang, name, _ := strings.Cut(e.To, ":")
			g.Nodes = append(g.Nodes, Node{ID: e.To, Name: name, Kind: "external", Lang: lang, Package: name})
			ids[e.To] = true
		}
	}
	if len(g.Nodes) == 0 {
		g.Warnings = append(g.Warnings, "No Go or Java declarations found.")
	}
	if options.Unpushed {
		review, err := reviewScope(ctx, root, options.Base)
		if err != nil {
			return nil, err
		}
		focusReview(g, review)
	}
	finishGraph(g)
	if err := overlayMetrics(g); err != nil {
		return nil, err
	}
	return g, nil
}

// Include test sources and build descriptors: changing tests invalidates old metrics too.
func projectInputHash(root string) (string, error) {
	files, err := sourceFiles(root, true)
	if err != nil {
		return "", err
	}
	h := sha256.New()
	for _, file := range files {
		data, err := os.ReadFile(file)
		if err != nil {
			return "", err
		}
		rel, _ := filepath.Rel(root, file)
		fmt.Fprintf(h, "%s\x00%s\n", rel, sourceDigest(data))
	}
	for _, name := range []string{"go.mod", "go.sum", "go.work", "pom.xml", "Config", "build.gradle", "build.gradle.kts"} {
		data, err := os.ReadFile(filepath.Join(root, name))
		if err == nil {
			fmt.Fprintf(h, "%s\x00%s\n", name, digest(data))
		} else if !os.IsNotExist(err) {
			return "", err
		}
	}
	return hex.EncodeToString(h.Sum(nil)), nil
}

func goPackage(root, file, name string) string {
	dir := filepath.Dir(filepath.Join(root, file))
	for current := dir; ; current = filepath.Dir(current) {
		if data, err := os.ReadFile(filepath.Join(current, "go.mod")); err == nil {
			for _, line := range strings.Split(string(data), "\n") {
				fields := strings.Fields(line)
				if len(fields) >= 2 && fields[0] == "module" {
					rel, _ := filepath.Rel(current, dir)
					base := strings.Trim(fields[1], "\"")
					if rel != "." {
						base += "/" + filepath.ToSlash(rel)
					}
					return base
				}
			}
		}
		if current == root || current == filepath.Dir(current) {
			break
		}
	}
	rel, _ := filepath.Rel(root, dir)
	if rel == "." {
		return name
	}
	return filepath.ToSlash(rel) + "/" + name
}

func goText(fset *token.FileSet, node any) string {
	var b bytes.Buffer
	_ = format.Node(&b, fset, node)
	return b.String()
}

func receiverName(expr ast.Expr) string {
	switch x := expr.(type) {
	case *ast.Ident:
		return x.Name
	case *ast.StarExpr:
		return receiverName(x.X)
	case *ast.IndexExpr:
		return receiverName(x.X)
	case *ast.IndexListExpr:
		return receiverName(x.X)
	}
	return ""
}

func scanGo(g *Graph, file string, data []byte, packages map[string]bool) error {
	fset := token.NewFileSet()
	tree, err := parser.ParseFile(fset, file, data, parser.SkipObjectResolution)
	if err != nil {
		return err
	}
	pkg := goPackage(g.Root, file, tree.Name.Name)
	pid := "go:" + pkg
	if !packages[pid] {
		g.Nodes = append(g.Nodes, Node{ID: pid, Name: pkg, Kind: "package", Lang: "go", Package: pkg})
		packages[pid] = true
	}
	for _, im := range tree.Imports {
		path, err := strconv.Unquote(im.Path.Value)
		if err != nil {
			return err
		}
		g.Edges = append(g.Edges, Edge{From: pid, To: "go:" + path, Kind: "imports"})
	}
	for _, decl := range tree.Decls {
		switch d := decl.(type) {
		case *ast.GenDecl:
			for _, spec := range d.Specs {
				t, ok := spec.(*ast.TypeSpec)
				if !ok {
					continue
				}
				kind := "type"
				switch t.Type.(type) {
				case *ast.StructType:
					kind = "struct"
				case *ast.InterfaceType:
					kind = "interface"
				}
				n := Node{ID: pid + "#" + t.Name.Name, Name: t.Name.Name, Kind: kind,
					Lang: "go", Package: pkg, Parent: pid, File: file,
					Line: fset.Position(t.Pos()).Line, EndLine: fset.Position(t.End()).Line,
					Public: t.Name.IsExported(), Signature: goText(fset, t)}
				g.Nodes = append(g.Nodes, n)
			}
		case *ast.FuncDecl:
			parent, name, kind := pid, d.Name.Name, "function"
			reportName := name
			if d.Recv != nil && len(d.Recv.List) > 0 {
				parent = pid + "#" + receiverName(d.Recv.List[0].Type)
				kind = "method"
				reportName = receiverName(d.Recv.List[0].Type) + "." + name
			}
			g.Nodes = append(g.Nodes, Node{ID: parent + "#" + name + "@" + file + ":" + strconv.Itoa(fset.Position(d.Pos()).Line),
				Name: name, Kind: kind, Lang: "go", Package: pkg, Parent: parent,
				File: file, Line: fset.Position(d.Pos()).Line, EndLine: fset.Position(d.End()).Line,
				Signature: strings.Replace(goText(fset, d.Type), "func", "func "+name, 1), Public: d.Name.IsExported(),
				ReportName: reportName, ReportOwner: tree.Name.Name})
		}
	}
	return nil
}

func scanJava(ctx context.Context, g *Graph, files []string) error {
	cache, err := os.UserCacheDir()
	if err != nil {
		return err
	}
	dir := filepath.Join(cache, "agent-tools", "uml-viewer", "java", digest(javaSource)[:16])
	class := filepath.Join(dir, "Scan.class")
	if _, err := os.Stat(class); os.IsNotExist(err) {
		if err := os.MkdirAll(dir, 0700); err != nil {
			return err
		}
		source := filepath.Join(dir, "Scan.java")
		if err := os.WriteFile(source, javaSource, 0600); err != nil {
			return err
		}
		cmd := exec.CommandContext(ctx, "javac", "-d", dir, source)
		if output, err := cmd.CombinedOutput(); err != nil {
			return fmt.Errorf("Java analysis needs a JDK 17+ (javac): %w\n%s", err, output)
		}
	}
	// Paths travel over stdin, avoiding OS argument length limits in large packages.
	cmd := exec.CommandContext(ctx, "java", "-cp", dir, "Scan", g.Root)
	cmd.Stdin = strings.NewReader(strings.Join(files, "\n") + "\n")
	var out, stderr bytes.Buffer
	cmd.Stdout, cmd.Stderr = &out, &stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("Java scanner: %w\n%s", err, stderr.String())
	}
	var result struct {
		Nodes    []Node   `json:"nodes"`
		Edges    []Edge   `json:"edges"`
		Warnings []string `json:"warnings"`
	}
	if err := json.Unmarshal(out.Bytes(), &result); err != nil {
		return fmt.Errorf("Java scanner output: %w", err)
	}
	g.Nodes = append(g.Nodes, result.Nodes...)
	g.Edges = append(g.Edges, result.Edges...)
	g.Warnings = append(g.Warnings, result.Warnings...)
	return nil
}
