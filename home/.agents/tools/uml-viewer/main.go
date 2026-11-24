package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"math"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"strings"
)

const usage = `UML viewer for Go and Java — no Clojure runtime.

  uml-viewer scan     [--root DIR] [--tests] [--unpushed] [--base REF] [--out FILE]
  uml-viewer serve    [--root DIR] [--tests] [--unpushed] [--base REF] [--port 8765]
  uml-viewer measure  [--root DIR] --tool TOOL -- TOOL_ARGUMENTS...
  uml-viewer import   [--root DIR] --kind crap|mutation --snapshot FILE
  uml-viewer policy   [--root DIR] [--from FILE]
  uml-viewer requests [--root DIR] [--ack ID]
  uml-viewer status   [--root DIR]

TOOL is crap4go, crap4java, mutate4go, or mutate4java, installed through
~/.agents/tools/quality-gates/bin/quality-tool. measure executes that tool.
scan and serve only read project sources. State and results go to the user cache.
Java source analysis requires a JDK 17+; Go analysis needs no project build.
--unpushed fetches the upstream remote once, then reviews local commits and
staged/unstaged/untracked Go/Java changes. --base chooses an explicit baseline.
`

func main() {
	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
	defer cancel()
	if err := run(ctx, os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, err)
		var exit *exec.ExitError
		if errors.As(err, &exit) {
			os.Exit(exit.ExitCode())
		}
		os.Exit(1)
	}
}

func run(ctx context.Context, args []string) error {
	if len(args) == 0 || args[0] == "--help" || args[0] == "help" {
		fmt.Print(usage)
		return nil
	}
	command := args[0]
	f := flag.NewFlagSet(command, flag.ContinueOnError)
	rootFlag := f.String("root", ".", "project root")
	tests := f.Bool("tests", false, "include tests")
	unpushed := f.Bool("unpushed", false, "focus on local changes relative to upstream")
	base := f.String("base", "", "explicit review baseline (with --unpushed)")
	out := f.String("out", "", "graph output file (default stdout)")
	port := f.Int("port", 8765, "loopback HTTP port; 0 chooses a free port")
	tool := f.String("tool", "", "quality tool")
	kind := f.String("kind", "", "crap or mutation")
	snapshot := f.String("snapshot", "", "JSON result snapshot")
	from := f.String("from", "", "policy JSON file")
	ack := f.String("ack", "", "handled request ID")
	if err := f.Parse(args[1:]); err != nil {
		return err
	}
	root, err := canonicalRoot(*rootFlag)
	if err != nil {
		return err
	}
	if command != "measure" && len(f.Args()) != 0 {
		return fmt.Errorf("unexpected arguments: %v", f.Args())
	}
	if *base != "" && !*unpushed {
		return fmt.Errorf("--base requires --unpushed")
	}
	if *unpushed && command != "scan" && command != "serve" {
		return fmt.Errorf("--unpushed is supported by scan and serve")
	}
	switch command {
	case "scan", "serve":
		options := scanOptions{Tests: *tests, Unpushed: *unpushed, Base: *base}
		if options.Unpushed {
			options.Base, err = fetchReviewBase(ctx, root, options.Base)
			if err != nil {
				return err
			}
		}
		g, err := scanProject(ctx, root, options)
		if err != nil {
			return err
		}
		if command == "serve" {
			return serve(ctx, g, options, *port)
		}
		if *out != "" {
			return writeJSON(*out, g)
		}
		return printJSON(g)
	case "measure":
		return measure(ctx, root, *tool, f.Args())
	case "import":
		if (*kind != "crap" && *kind != "mutation") || *snapshot == "" {
			return fmt.Errorf("import requires --kind crap|mutation and --snapshot FILE")
		}
		var s Snapshot
		if err := readJSON(*snapshot, &s); err != nil {
			return err
		}
		if s.Version != 1 {
			return fmt.Errorf("unsupported snapshot version")
		}
		g, err := scanProject(ctx, root, scanOptions{})
		if err != nil {
			return err
		}
		if err := validateRecords(g, *kind, s.Records); err != nil {
			return err
		}
		return saveMetrics(root, *kind, s.Records)
	case "policy":
		if *from != "" {
			var p Policy
			if err := readJSON(*from, &p); err != nil {
				return err
			}
			if err := validatePolicy(p); err != nil {
				return err
			}
			return writeJSON(filepath.Join(stateDir(root), "policy.json"), p)
		}
		p, err := loadPolicy(root)
		if err != nil {
			return err
		}
		return printJSON(p)
	case "requests":
		if *ack != "" {
			if strings.Trim(*ack, "0123456789") != "" {
				return fmt.Errorf("request ID must contain only digits")
			}
			return os.Remove(filepath.Join(stateDir(root), "requests", *ack+".json"))
		}
		r, err := loadRequests(root)
		if err != nil {
			return err
		}
		return printJSON(r)
	case "status":
		var info map[string]any
		if err := readJSON(filepath.Join(stateDir(root), "server.json"), &info); err != nil {
			return err
		}
		info["state_dir"] = stateDir(root)
		info["note"] = "Last launched server; this does not prove the process is still running."
		return printJSON(info)
	default:
		return fmt.Errorf("unknown command %q\n%s", command, usage)
	}
}

func printJSON(value any) error {
	e := json.NewEncoder(os.Stdout)
	e.SetIndent("", "  ")
	return e.Encode(value)
}

func measure(ctx context.Context, root, tool string, args []string) error {
	lang, kind := "go", "crap"
	switch tool {
	case "crap4go":
	case "crap4java":
		lang = "java"
	case "mutate4go":
		kind = "mutation"
	case "mutate4java":
		lang, kind = "java", "mutation"
	default:
		return fmt.Errorf("unsupported quality tool %q", tool)
	}
	g, err := scanProject(ctx, root, scanOptions{})
	if err != nil {
		return err
	}
	home, err := os.UserHomeDir()
	if err != nil {
		return err
	}
	manager := filepath.Join(home, ".agents", "tools", "quality-gates", "bin", "quality-tool")
	path, err := exec.CommandContext(ctx, manager, "path", tool).Output()
	if err != nil {
		return fmt.Errorf("locate %s with quality-tool: %w", tool, err)
	}
	bin := strings.TrimSpace(string(path))
	if _, err := os.Stat(bin); err != nil {
		return fmt.Errorf("%s is not installed; run %s ensure %s first", tool, manager, tool)
	}
	cmd := exec.CommandContext(ctx, bin, args...)
	cmd.Dir = root
	var report bytes.Buffer
	cmd.Stdout = io.MultiWriter(os.Stdout, &report)
	cmd.Stderr = os.Stderr
	runErr := cmd.Run()
	if cmd.ProcessState == nil {
		return runErr
	}
	code := cmd.ProcessState.ExitCode()
	// These exits are quality verdicts, not failed executions.
	if runErr != nil && !(tool == "crap4java" && code == 2) && !(tool == "mutate4java" && code == 3) {
		return runErr
	}
	var records []MetricRecord
	if kind == "crap" {
		records, err = crapRecords(g, lang, report.String())
	} else {
		source := ""
		for _, arg := range args {
			if strings.HasSuffix(arg, "."+map[string]string{"go": "go", "java": "java"}[lang]) {
				source = arg
				break
			}
		}
		if filepath.IsAbs(source) {
			source, err = filepath.Rel(root, source)
			if err != nil {
				return err
			}
		}
		records, err = mutationRecords(g, lang, filepath.ToSlash(filepath.Clean(source)), report.String())
	}
	if err != nil {
		return fmt.Errorf("tool ran, but metric import failed: %w", err)
	}
	// Keep pre-run source hashes; concurrent edits make the results stale.
	if err := saveMetrics(root, kind, records); err != nil {
		return err
	}
	fmt.Fprintf(os.Stderr, "Saved %d %s result records in %s\n", len(records), kind, stateDir(root))
	if runErr != nil {
		return runErr
	}
	if tool == "mutate4go" {
		for _, r := range records {
			if r.Values.Survived != nil && *r.Values.Survived > 0 {
				return fmt.Errorf("mutation gate failed: surviving mutants")
			}
		}
	}
	return nil
}

func validateRecords(g *Graph, kind string, records []MetricRecord) error {
	for _, r := range records {
		if _, exists := g.Hashes[r.File]; !exists || r.Line < 1 {
			return fmt.Errorf("unknown source location %s:%d", r.File, r.Line)
		}
		found := 0
		for _, n := range g.Nodes {
			if n.File == r.File && n.Line == r.Line && (r.NodeID == "" || r.NodeID == n.ID) {
				found++
			}
		}
		if found != 1 {
			return fmt.Errorf("expected one declaration at %s:%d; found %d (supply node_id)", r.File, r.Line, found)
		}
		for _, n := range []*float64{r.Values.CC, r.Values.Coverage, r.Values.CRAP} {
			if n != nil && (*n < 0 || math.IsNaN(*n) || math.IsInf(*n, 0)) {
				return fmt.Errorf("invalid metric at %s:%d", r.File, r.Line)
			}
		}
		for _, n := range []*int{r.Values.Killed, r.Values.Survived, r.Values.Uncovered} {
			if n != nil && *n < 0 {
				return fmt.Errorf("negative mutation count")
			}
		}
		if r.Values.Coverage != nil && *r.Values.Coverage > 100 {
			return fmt.Errorf("coverage must be a percentage from 0 to 100")
		}
		if kind == "crap" && r.Values.CC == nil && r.Values.CRAP == nil && r.Values.Coverage == nil {
			return fmt.Errorf("CRAP record has no CRAP/CC/coverage data")
		}
		if kind == "mutation" && r.Values.Killed == nil && r.Values.Survived == nil && r.Values.Uncovered == nil {
			return fmt.Errorf("mutation record has no counts")
		}
	}
	return nil
}
