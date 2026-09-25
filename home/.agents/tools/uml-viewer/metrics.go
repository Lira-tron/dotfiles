package main

import (
	"fmt"
	"math"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"time"
)

func overlayMetrics(g *Graph) error {
	for _, kind := range []string{"crap", "mutation"} {
		var snapshot Snapshot
		if err := readJSON(filepath.Join(stateDir(g.Root), kind+".json"), &snapshot); err != nil {
			if os.IsNotExist(err) {
				continue
			}
			return err
		}
		for _, r := range snapshot.Records {
			for i := range g.Nodes {
				n := &g.Nodes[i]
				if n.File != r.File || n.Line != r.Line || (r.NodeID != "" && n.ID != r.NodeID) {
					continue
				}
				if n.Metrics == nil {
					n.Metrics = &Metrics{}
				}
				m := n.Metrics
				m.Stale = m.Stale || r.Hash == "" || r.Hash != g.Hashes[r.File] ||
					r.InputHash == "" || r.InputHash != g.InputHash
				if kind == "crap" {
					m.CC, m.Coverage, m.CRAP = r.Values.CC, r.Values.Coverage, r.Values.CRAP
				} else {
					m.Killed, m.Survived, m.Uncovered = r.Values.Killed, r.Values.Survived, r.Values.Uncovered
				}
			}
		}
	}
	return nil
}

func saveMetrics(root, kind string, records []MetricRecord) error {
	path := filepath.Join(stateDir(root), kind+".json")
	var old Snapshot
	if err := readJSON(path, &old); err != nil && !os.IsNotExist(err) {
		return err
	}
	byKey := map[string]MetricRecord{}
	for _, r := range append(old.Records, records...) {
		byKey[fmt.Sprintf("%s:%d:%s", r.File, r.Line, r.NodeID)] = r
	}
	s := Snapshot{Version: 1, CreatedAt: time.Now().UTC().Format(time.RFC3339)}
	for _, r := range byKey {
		s.Records = append(s.Records, r)
	}
	sort.Slice(s.Records, func(i, j int) bool {
		a, b := s.Records[i], s.Records[j]
		return a.File < b.File || (a.File == b.File && a.Line < b.Line)
	})
	return writeJSON(path, s)
}

func metricNumber(s string) (*float64, error) {
	if s == "N/A" {
		return nil, nil
	}
	v, err := strconv.ParseFloat(strings.TrimSuffix(s, "%"), 64)
	if err != nil || math.IsNaN(v) || math.IsInf(v, 0) || v < 0 {
		return nil, fmt.Errorf("invalid metric: %q", s)
	}
	return &v, nil
}

func crapRecords(g *Graph, lang, report string) ([]MetricRecord, error) {
	var records []MetricRecord
	inReport := false
	for _, line := range strings.Split(report, "\n") {
		if strings.TrimSpace(line) == "CRAP Report" {
			inReport = true
			continue
		}
		fields := strings.Fields(line)
		if !inReport || len(fields) != 5 {
			continue
		}
		if fields[2] == "CC" {
			continue
		}
		cc, err := metricNumber(fields[2])
		if err != nil {
			continue
		}
		cov, err := metricNumber(fields[3])
		if err != nil {
			return nil, err
		}
		crap, err := metricNumber(fields[4])
		if err != nil {
			return nil, err
		}
		if cov != nil && *cov > 100 {
			return nil, fmt.Errorf("coverage exceeds 100: %s", line)
		}
		var matches []Node
		for _, n := range g.Nodes {
			if n.Lang == lang && n.ReportName == fields[0] && n.ReportOwner == fields[1] {
				matches = append(matches, n)
			}
		}
		if len(matches) > 1 {
			return nil, fmt.Errorf("ambiguous CRAP row %s.%s: report omits overload/path identity; use a snapshot with file and line", fields[1], fields[0])
		}
		if len(matches) == 1 {
			n := matches[0]
			records = append(records, MetricRecord{NodeID: n.ID, File: n.File, Line: n.Line, Hash: g.Hashes[n.File], InputHash: g.InputHash,
				Values: Metrics{CC: cc, Coverage: cov, CRAP: crap}})
		}
	}
	if !inReport {
		return nil, fmt.Errorf("no CRAP report found")
	}
	return records, nil
}

var goResult = regexp.MustCompile(`^\[\d+/\d+\] (?:worker-\d+ )?(killed|survived|timeout) line (\d+) `)
var goUncovered = regexp.MustCompile(`^\s+line (\d+) `)
var javaResult = regexp.MustCompile(`^(KILLED|SURVIVED|UNCOVERED) (.+):(\d+) `)
var javaSummary = regexp.MustCompile(`(?m)^Summary: (\d+) killed, (\d+) survived, (\d+) total\.$`)
var javaUncoveredCount = regexp.MustCompile(`(?m)^Coverage: (\d+) uncovered sites skipped\.$`)

func mutationRecords(g *Graph, lang, source, report string) ([]MetricRecord, error) {
	counts := map[string]*MetricRecord{}
	add := func(file string, line int, status string) error {
		var match *Node
		for i := range g.Nodes {
			n := &g.Nodes[i]
			if n.File != file || n.Line > line || n.EndLine < line || n.Lang != lang {
				continue
			}
			if n.Kind != "function" && n.Kind != "method" && n.Kind != "constructor" && n.Kind != "field" {
				continue
			}
			if match == nil || n.EndLine-n.Line < match.EndLine-match.Line {
				match = n
			}
		}
		if match == nil {
			return fmt.Errorf("cannot locate mutation result at %s:%d", file, line)
		}
		r := counts[match.ID]
		if r == nil {
			r = &MetricRecord{NodeID: match.ID, File: file, Line: match.Line, Hash: g.Hashes[file], InputHash: g.InputHash,
				Values: Metrics{Killed: new(int), Survived: new(int), Uncovered: new(int)}}
			counts[match.ID] = r
		}
		switch strings.ToLower(status) {
		case "killed", "timeout":
			*r.Values.Killed++
		case "survived":
			*r.Values.Survived++
		case "uncovered":
			*r.Values.Uncovered++
		}
		return nil
	}
	uncoveredSection := false
	for _, line := range strings.Split(report, "\n") {
		var file, status, number string
		if lang == "go" {
			if strings.TrimSpace(line) == "Uncovered mutations:" {
				uncoveredSection = true
				continue
			}
			if m := goResult.FindStringSubmatch(line); m != nil {
				status, number, file = m[1], m[2], source
				uncoveredSection = false
			} else if m := goUncovered.FindStringSubmatch(line); m != nil && uncoveredSection {
				status, number, file = "uncovered", m[1], source
			} else if strings.TrimSpace(line) != "" {
				uncoveredSection = false
			}
		} else if m := javaResult.FindStringSubmatch(line); m != nil {
			status, file, number = m[1], filepath.ToSlash(filepath.Clean(m[2])), m[3]
		}
		if status != "" {
			n, _ := strconv.Atoi(number)
			if err := add(file, n, status); err != nil {
				return nil, err
			}
		}
	}
	if (lang == "go" && !strings.Contains(report, "Mutation Report")) ||
		(lang == "java" && !strings.Contains(report, "Summary:")) {
		return nil, fmt.Errorf("no completed mutation report found (scan-only output has no results)")
	}
	var records []MetricRecord
	for _, r := range counts {
		records = append(records, *r)
	}
	if err := verifyMutationTotals(lang, report, records); err != nil {
		return nil, err
	}
	// A differential no-op supplies no fresh results, so preserve earlier snapshots.
	return records, nil
}

func verifyMutationTotals(lang, report string, records []MetricRecord) error {
	actual := [3]int{}
	for _, r := range records {
		actual[0] += *r.Values.Killed
		actual[1] += *r.Values.Survived
		actual[2] += *r.Values.Uncovered
	}
	expected := [3]int{}
	if lang == "go" {
		for i, label := range []string{"Killed", "Survived", "Uncovered"} {
			m := regexp.MustCompile(`(?m)^` + label + `: (\d+)$`).FindStringSubmatch(report)
			if m == nil {
				return fmt.Errorf("missing mutation summary count: %s", label)
			}
			expected[i], _ = strconv.Atoi(m[1])
		}
	} else {
		m, u := javaSummary.FindStringSubmatch(report), javaUncoveredCount.FindStringSubmatch(report)
		if m == nil || u == nil {
			return fmt.Errorf("missing Java mutation summary counts")
		}
		expected[0], _ = strconv.Atoi(m[1])
		expected[1], _ = strconv.Atoi(m[2])
		expected[2], _ = strconv.Atoi(u[1])
		total, _ := strconv.Atoi(m[3])
		if total != expected[0]+expected[1] {
			return fmt.Errorf("inconsistent Java mutation summary")
		}
	}
	if actual != expected {
		return fmt.Errorf("parsed mutation counts %v do not match report summary %v; results not imported", actual, expected)
	}
	return nil
}
