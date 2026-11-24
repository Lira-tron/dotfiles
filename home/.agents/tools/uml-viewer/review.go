package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"os/exec"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
)

type ChangedFile struct {
	Path      string `json:"path"`
	Status    string `json:"status"`
	OldPath   string `json:"old_path,omitempty"`
	IndexOnly bool   `json:"index_only,omitempty"`
}

type Review struct {
	BaseRef      string        `json:"base_ref"`
	BaseCommit   string        `json:"base_commit"`
	MergeBase    string        `json:"merge_base"`
	Head         string        `json:"head"`
	LocalCommits int           `json:"local_commits"`
	Files        []ChangedFile `json:"files"`
	Fingerprint  string        `json:"fingerprint"`
}

func gitOutput(ctx context.Context, root string, args ...string) ([]byte, error) {
	cmd := exec.CommandContext(ctx, "git", append([]string{"-C", root}, args...)...)
	var out, stderr bytes.Buffer
	cmd.Stdout, cmd.Stderr = &out, &stderr
	if err := cmd.Run(); err != nil {
		return nil, fmt.Errorf("git %s: %w: %s", strings.Join(args, " "), err, strings.TrimSpace(stderr.String()))
	}
	return out.Bytes(), nil
}

func gitText(ctx context.Context, root string, args ...string) (string, error) {
	out, err := gitOutput(ctx, root, args...)
	return strings.TrimSpace(string(out)), err
}

func reviewBase(ctx context.Context, root, base string) (string, error) {
	if _, err := gitText(ctx, root, "rev-parse", "--show-toplevel"); err != nil {
		return "", fmt.Errorf("--unpushed requires a Git repository: %w", err)
	}
	if base == "" {
		var err error
		base, err = gitText(ctx, root, "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{upstream}")
		if err != nil {
			return "", fmt.Errorf("no upstream branch is configured; use --unpushed --base <remote/branch> to choose a review baseline")
		}
	}
	// Resolve to a commit before accepting the user-supplied ref as a diff argument.
	if _, err := gitText(ctx, root, "rev-parse", "--verify", "--end-of-options", base+"^{commit}"); err != nil {
		return "", fmt.Errorf("invalid review baseline %q: %w", base, err)
	}
	return base, nil
}

// Fetch once at CLI startup. Browser polling only reads local Git state.
func fetchReviewBase(ctx context.Context, root, base string) (string, error) {
	base, err := reviewBase(ctx, root, base)
	if err != nil {
		return "", err
	}
	full, err := gitText(ctx, root, "rev-parse", "--symbolic-full-name", "--verify", "--end-of-options", base)
	if err != nil {
		return "", err
	}
	if strings.HasPrefix(full, "refs/remotes/") {
		remotes, err := gitText(ctx, root, "remote")
		if err != nil {
			return "", err
		}
		remote := ""
		for _, name := range strings.Split(remotes, "\n") {
			if name != "" && strings.HasPrefix(full, "refs/remotes/"+name+"/") && len(name) > len(remote) {
				remote = name
			}
		}
		if remote == "" {
			return "", fmt.Errorf("cannot identify the remote for %s", base)
		}
		if _, err := gitOutput(ctx, root, "fetch", "--no-tags", remote); err != nil {
			return "", fmt.Errorf("could not refresh %s; review cancelled instead of using stale remote state: %w", base, err)
		}
	}
	return base, nil
}

func reviewScope(ctx context.Context, root, base string) (*Review, error) {
	base, err := reviewBase(ctx, root, base)
	if err != nil {
		return nil, err
	}
	repo, err := gitText(ctx, root, "rev-parse", "--show-toplevel")
	if err != nil {
		return nil, err
	}
	r := &Review{BaseRef: base, Files: []ChangedFile{}}
	if r.BaseCommit, err = gitText(ctx, repo, "rev-parse", "--verify", "--end-of-options", base+"^{commit}"); err != nil {
		return nil, err
	}
	if r.Head, err = gitText(ctx, repo, "rev-parse", "--verify", "HEAD"); err != nil {
		return nil, fmt.Errorf("review requires an initial commit: %w", err)
	}
	if r.MergeBase, err = gitText(ctx, repo, "merge-base", r.BaseCommit, r.Head); err != nil {
		return nil, fmt.Errorf("baseline and HEAD have no common ancestor: %w", err)
	}
	count, err := gitText(ctx, repo, "rev-list", "--count", r.BaseCommit+".."+r.Head)
	if err != nil {
		return nil, err
	}
	r.LocalCommits, err = strconv.Atoi(count)
	if err != nil {
		return nil, err
	}
	changes := map[string]ChangedFile{}
	for _, cached := range []bool{false, true} {
		args := []string{"diff", "--no-ext-diff", "--no-textconv", "--no-relative", "--name-status", "-z", "--find-renames"}
		if cached {
			args = append(args, "--cached")
		}
		args = append(args, r.MergeBase, "--")
		out, err := gitOutput(ctx, repo, args...)
		if err != nil {
			return nil, err
		}
		files, err := parseChangedFiles(out)
		if err != nil {
			return nil, err
		}
		for _, file := range files {
			file.IndexOnly = cached
			if _, exists := changes[file.Path]; !exists {
				changes[file.Path] = file
			}
		}
	}
	untracked, err := gitOutput(ctx, repo, "ls-files", "--others", "--exclude-standard", "-z")
	if err != nil {
		return nil, err
	}
	for _, path := range strings.Split(string(untracked), "\x00") {
		if path != "" {
			if _, exists := changes[path]; !exists {
				changes[path] = ChangedFile{Path: path, Status: "untracked"}
			}
		}
	}
	relative := func(path string) (string, bool) {
		if path == "" {
			return "", false
		}
		rel, err := filepath.Rel(root, filepath.Join(repo, filepath.FromSlash(path)))
		ok := err == nil && rel != ".." && !strings.HasPrefix(rel, ".."+string(filepath.Separator))
		return filepath.ToSlash(rel), ok && (strings.HasSuffix(rel, ".go") || strings.HasSuffix(rel, ".java"))
	}
	for _, file := range changes {
		path, inRoot := relative(file.Path)
		old, oldInRoot := relative(file.OldPath)
		if !inRoot {
			if !oldInRoot {
				continue
			}
			file.Path, file.Status, file.OldPath = old, "deleted", ""
		} else {
			file.Path = path
			if oldInRoot {
				file.OldPath = old
			} else {
				file.OldPath = ""
			}
		}
		r.Files = append(r.Files, file)
	}
	sort.Slice(r.Files, func(i, j int) bool { return r.Files[i].Path < r.Files[j].Path })
	data, err := json.Marshal(r)
	if err != nil {
		return nil, err
	}
	r.Fingerprint = digest(data)
	return r, nil
}

func parseChangedFiles(data []byte) ([]ChangedFile, error) {
	parts := strings.Split(strings.TrimSuffix(string(data), "\x00"), "\x00")
	var files []ChangedFile
	for i := 0; i < len(parts) && parts[i] != ""; {
		status := parts[i]
		i++
		if i >= len(parts) {
			return nil, fmt.Errorf("incomplete Git name-status record")
		}
		file := ChangedFile{Path: parts[i]}
		i++
		switch status[0] {
		case 'A':
			file.Status = "added"
		case 'D':
			file.Status = "deleted"
		case 'M', 'T':
			file.Status = "modified"
		case 'R', 'C':
			if i >= len(parts) {
				return nil, fmt.Errorf("incomplete Git rename record")
			}
			file.Status, file.OldPath, file.Path = "renamed", file.Path, parts[i]
			i++
		case 'U':
			return nil, fmt.Errorf("resolve the merge conflict in %s before opening a review", file.Path)
		default:
			return nil, fmt.Errorf("unsupported Git file status %s", status)
		}
		files = append(files, file)
	}
	return files, nil
}

func focusReview(g *Graph, review *Review) {
	g.Review = review
	files := map[string]ChangedFile{}
	for _, file := range review.Files {
		files[file.Path] = file
	}
	byID, keep := map[string]Node{}, map[string]bool{}
	for _, node := range g.Nodes {
		byID[node.ID] = node
		if change, exists := files[node.File]; exists && change.Status != "deleted" {
			keep[node.ID] = true
		}
	}
	for id := range keep {
		for parent := byID[id].Parent; parent != "" && !keep[parent]; parent = byID[parent].Parent {
			keep[parent] = true
		}
	}
	edges := []Edge{}
	contextNodes := map[string]bool{}
	for _, edge := range g.Edges {
		if keep[edge.From] || keep[edge.To] {
			edges = append(edges, edge)
			for _, id := range []string{edge.From, edge.To} {
				if !keep[id] {
					contextNodes[id] = true
				}
			}
		}
	}
	nodes := []Node{}
	for _, node := range g.Nodes {
		if keep[node.ID] {
			if change, exists := files[node.File]; exists {
				node.Change = change.Status
			} else {
				node.Change = "context"
				if node.Kind == "package" {
					node.Change = "changed contents"
				}
			}
			nodes = append(nodes, node)
		} else if contextNodes[node.ID] {
			// Dependency context has no members or source body in the focused graph.
			nodes = append(nodes, Node{ID: node.ID, Name: node.Name, Lang: node.Lang,
				Kind: "external", Package: node.Package, Change: "context"})
		}
	}
	for _, file := range review.Files {
		lang := strings.TrimPrefix(filepath.Ext(file.Path), ".")
		if file.Status == "deleted" {
			nodes = append(nodes, Node{ID: "deleted:" + file.Path, Name: file.Path,
				Lang: lang, Kind: "deleted file", Change: "deleted",
				Signature: "Deleted relative to " + review.BaseRef})
			continue
		}
		hasDeclaration := false
		for _, node := range nodes {
			hasDeclaration = hasDeclaration || node.File == file.Path
		}
		if !hasDeclaration {
			node := Node{ID: "changed-file:" + file.Path, Name: file.Path,
				Lang: lang, Kind: "changed file", Change: file.Status}
			if _, scanned := g.Hashes[file.Path]; scanned {
				node.File, node.Line, node.EndLine = file.Path, 1, 1
			} else {
				node.Signature = "Outside the scanner's source filters; listed for review completeness."
			}
			nodes = append(nodes, node)
		}
	}
	if len(review.Files) == 0 {
		g.Warnings = append(g.Warnings, "No local Go or Java file changes relative to "+review.BaseRef+".")
	}
	g.Nodes, g.Edges = nodes, edges
}
