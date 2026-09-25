package main

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"time"
)

type Node struct {
	ID          string   `json:"id"`
	Name        string   `json:"name"`
	Kind        string   `json:"kind"`
	Lang        string   `json:"lang"`
	Package     string   `json:"package"`
	Parent      string   `json:"parent,omitempty"`
	File        string   `json:"file,omitempty"`
	Line        int      `json:"line,omitempty"`
	EndLine     int      `json:"end_line,omitempty"`
	Signature   string   `json:"signature,omitempty"`
	Public      bool     `json:"public,omitempty"`
	ReportName  string   `json:"report_name,omitempty"`
	ReportOwner string   `json:"report_owner,omitempty"`
	Metrics     *Metrics `json:"metrics,omitempty"`
	Change      string   `json:"change,omitempty"`
}

type Edge struct {
	From string `json:"from"`
	To   string `json:"to"`
	Kind string `json:"kind"`
}

type Graph struct {
	Version   int               `json:"version"`
	Root      string            `json:"root"`
	Name      string            `json:"name"`
	ScannedAt string            `json:"scanned_at"`
	Nodes     []Node            `json:"nodes"`
	Edges     []Edge            `json:"edges"`
	Hashes    map[string]string `json:"hashes"`
	InputHash string            `json:"input_hash"`
	Warnings  []string          `json:"warnings"`
	Review    *Review           `json:"review,omitempty"`
}

type Metrics struct {
	CC        *float64 `json:"cc,omitempty"`
	Coverage  *float64 `json:"coverage,omitempty"`
	CRAP      *float64 `json:"crap,omitempty"`
	Killed    *int     `json:"killed,omitempty"`
	Survived  *int     `json:"survived,omitempty"`
	Uncovered *int     `json:"uncovered,omitempty"`
	Stale     bool     `json:"stale"`
}

// Metric records identify a declaration by path and start line, never name alone.
type MetricRecord struct {
	NodeID    string  `json:"node_id,omitempty"`
	File      string  `json:"file"`
	Line      int     `json:"line"`
	Hash      string  `json:"hash"`
	InputHash string  `json:"input_hash,omitempty"`
	Values    Metrics `json:"values"`
}

type Snapshot struct {
	Version   int            `json:"version"`
	CreatedAt string         `json:"created_at"`
	Records   []MetricRecord `json:"records"`
}

func digest(data []byte) string {
	sum := sha256.Sum256(data)
	return hex.EncodeToString(sum[:])
}

func sourceDigest(data []byte) string {
	for _, markers := range [][2]string{
		{"\n// mutate4go-manifest-begin", "// mutate4go-manifest-end"},
		{"\n/* mutate4java-manifest", "*/"},
	} {
		if i := bytes.LastIndex(data, []byte(markers[0])); i >= 0 &&
			bytes.HasSuffix(bytes.TrimSpace(data), []byte(markers[1])) {
			data = data[:i]
		}
	}
	return digest(bytes.TrimSpace(data))
}

func writeJSON(path string, value any) error {
	data, err := json.MarshalIndent(value, "", "  ")
	if err != nil {
		return err
	}
	if err := os.MkdirAll(filepath.Dir(path), 0700); err != nil {
		return err
	}
	f, err := os.CreateTemp(filepath.Dir(path), ".uml-*.tmp")
	if err != nil {
		return err
	}
	defer os.Remove(f.Name())
	if _, err = f.Write(append(data, '\n')); err != nil {
		f.Close()
		return err
	}
	if err = f.Close(); err != nil {
		return err
	}
	return os.Rename(f.Name(), path)
}

func stateDir(root string) string {
	cache, err := os.UserCacheDir()
	if err != nil {
		cache = os.TempDir()
	}
	return filepath.Join(cache, "agent-tools", "uml-viewer", digest([]byte(root))[:20])
}

func readJSON(path string, value any) error {
	b, err := os.ReadFile(path)
	if err != nil {
		return err
	}
	if err := json.Unmarshal(b, value); err != nil {
		return fmt.Errorf("%s: %w", path, err)
	}
	return nil
}

func finishGraph(g *Graph) {
	sort.Slice(g.Nodes, func(i, j int) bool { return g.Nodes[i].ID < g.Nodes[j].ID })
	sort.Slice(g.Edges, func(i, j int) bool {
		a, b := g.Edges[i], g.Edges[j]
		return a.From+"\000"+a.To+"\000"+a.Kind < b.From+"\000"+b.To+"\000"+b.Kind
	})
	unique := g.Edges[:0]
	for _, e := range g.Edges {
		if len(unique) == 0 || unique[len(unique)-1] != e {
			unique = append(unique, e)
		}
	}
	g.Edges = unique
	g.ScannedAt = time.Now().UTC().Format(time.RFC3339)
}
