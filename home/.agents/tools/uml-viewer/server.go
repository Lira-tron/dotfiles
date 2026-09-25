package main

import (
	"context"
	"crypto/rand"
	_ "embed"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"time"
)

//go:embed web/index.html
var page []byte

type Policy struct {
	Proposals []Proposal     `json:"proposals"`
	Levels    map[string]int `json:"levels"`
}

type Proposal struct {
	ID     string            `json:"id"`
	Name   string            `json:"name"`
	Groups map[string]string `json:"groups"`
	Omit   []string          `json:"omit"`
}

type Request struct {
	ID        string `json:"id"`
	CreatedAt string `json:"created_at"`
	Action    string `json:"action"`
	Target    string `json:"target"`
	Prompt    string `json:"prompt"`
	Proposal  string `json:"proposal"`
}

type viewer struct {
	mu      sync.Mutex
	graph   *Graph
	options scanOptions
	token   string
}

func (v *viewer) handler() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/" || r.Method != http.MethodGet {
			http.NotFound(w, r)
			return
		}
		w.Header().Set("Content-Type", "text/html; charset=utf-8")
		w.Header().Set("Content-Security-Policy", "default-src 'self'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; connect-src 'self'; img-src 'self' data:; frame-ancestors 'none'")
		w.Write(page)
	})
	mux.HandleFunc("/api/", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Cache-Control", "no-store")
		w.Header().Set("X-Content-Type-Options", "nosniff")
		if r.Header.Get("Authorization") != "Bearer "+v.token {
			http.Error(w, "viewer session token required", http.StatusUnauthorized)
			return
		}
		v.mu.Lock()
		defer v.mu.Unlock()
		if err := v.api(w, r); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
		}
	})
	return mux
}

func reply(w http.ResponseWriter, value any) error {
	w.Header().Set("Content-Type", "application/json")
	return json.NewEncoder(w).Encode(value)
}

func decodeBody(w http.ResponseWriter, r *http.Request, value any) error {
	r.Body = http.MaxBytesReader(w, r.Body, 1<<20)
	d := json.NewDecoder(r.Body)
	d.DisallowUnknownFields()
	return d.Decode(value)
}

func (v *viewer) api(w http.ResponseWriter, r *http.Request) error {
	dir := stateDir(v.graph.Root)
	switch r.Method + " " + r.URL.Path {
	case "GET /api/graph":
		hash, err := projectInputHash(v.graph.Root)
		if err != nil {
			return err
		}
		reviewChanged := false
		if v.options.Unpushed {
			scope, err := reviewScope(r.Context(), v.graph.Root, v.options.Base)
			if err != nil {
				return err
			}
			reviewChanged = v.graph.Review == nil || scope.Fingerprint != v.graph.Review.Fingerprint
		}
		if hash != v.graph.InputHash || reviewChanged {
			g, scanErr := scanProject(r.Context(), v.graph.Root, v.options)
			if scanErr != nil {
				return scanErr
			}
			v.graph = g
		}
		for i := range v.graph.Nodes {
			v.graph.Nodes[i].Metrics = nil
		}
		if err := overlayMetrics(v.graph); err != nil {
			return err
		}
		return reply(w, v.graph)
	case "POST /api/scan":
		g, err := scanProject(r.Context(), v.graph.Root, v.options)
		if err != nil {
			return err
		}
		v.graph = g
		return reply(w, g)
	case "GET /api/source":
		file := r.URL.Query().Get("file")
		if _, ok := v.graph.Hashes[file]; !ok {
			return fmt.Errorf("file is not in this project's source graph")
		}
		path, err := filepath.EvalSymlinks(filepath.Join(v.graph.Root, filepath.FromSlash(file)))
		if err != nil {
			return err
		}
		rel, err := filepath.Rel(v.graph.Root, path)
		if err != nil || rel == ".." || strings.HasPrefix(rel, ".."+string(filepath.Separator)) {
			return fmt.Errorf("source path leaves project root")
		}
		f, err := os.Open(path)
		if err != nil {
			return err
		}
		defer f.Close()
		b, err := io.ReadAll(io.LimitReader(f, 3<<20+1))
		if err != nil {
			return err
		}
		if len(b) > 3<<20 {
			return fmt.Errorf("source exceeds 3 MiB")
		}
		return reply(w, map[string]string{"file": file, "body": string(b)})
	case "GET /api/policy":
		p, err := loadPolicy(v.graph.Root)
		if err != nil {
			return err
		}
		return reply(w, p)
	case "POST /api/policy":
		var p Policy
		if err := decodeBody(w, r, &p); err != nil {
			return err
		}
		if err := validatePolicy(p); err != nil {
			return err
		}
		if err := writeJSON(filepath.Join(dir, "policy.json"), p); err != nil {
			return err
		}
		return reply(w, p)
	case "GET /api/requests":
		requests, err := loadRequests(v.graph.Root)
		if err != nil {
			return err
		}
		return reply(w, requests)
	case "POST /api/requests":
		var request Request
		if err := decodeBody(w, r, &request); err != nil {
			return err
		}
		switch request.Action {
		case "inspect", "refresh-crap", "refresh-mutation", "proposal":
		default:
			return fmt.Errorf("unsupported request action")
		}
		request.ID = strconv.FormatInt(time.Now().UnixNano(), 10)
		request.CreatedAt = time.Now().UTC().Format(time.RFC3339)
		if err := writeJSON(filepath.Join(dir, "requests", request.ID+".json"), request); err != nil {
			return err
		}
		return reply(w, request)
	}
	http.NotFound(w, r)
	return nil
}

func loadPolicy(root string) (Policy, error) {
	p := Policy{Proposals: []Proposal{}, Levels: map[string]int{}}
	err := readJSON(filepath.Join(stateDir(root), "policy.json"), &p)
	if os.IsNotExist(err) {
		err = nil
	}
	return p, err
}

func validatePolicy(p Policy) error {
	seen := map[string]bool{}
	for _, proposal := range p.Proposals {
		if proposal.ID == "" || strings.TrimSpace(proposal.Name) == "" || seen[proposal.ID] {
			return fmt.Errorf("proposals require unique IDs and nonempty names")
		}
		seen[proposal.ID] = true
	}
	return nil
}

func loadRequests(root string) ([]Request, error) {
	requests := []Request{}
	paths, err := filepath.Glob(filepath.Join(stateDir(root), "requests", "*.json"))
	if err != nil {
		return nil, err
	}
	for _, path := range paths {
		var r Request
		if err := readJSON(path, &r); err != nil {
			return nil, err
		}
		requests = append(requests, r)
	}
	return requests, nil
}

func serve(ctx context.Context, g *Graph, options scanOptions, port int) error {
	listener, err := net.Listen("tcp", fmt.Sprintf("127.0.0.1:%d", port))
	if err != nil {
		return err
	}
	token := make([]byte, 24)
	if _, err := rand.Read(token); err != nil {
		listener.Close()
		return err
	}
	v := &viewer{graph: g, options: options, token: hex.EncodeToString(token)}
	server := &http.Server{Handler: v.handler(), ReadHeaderTimeout: 5 * time.Second, IdleTimeout: 60 * time.Second}
	url := "http://" + listener.Addr().String() + "/#" + v.token
	info := map[string]any{"url": url, "root": g.Root, "pid": os.Getpid(),
		"unpushed": options.Unpushed, "base": options.Base}
	if err := writeJSON(filepath.Join(stateDir(g.Root), "server.json"), info); err != nil {
		listener.Close()
		return err
	}
	fmt.Println("UML viewer:", url)
	fmt.Println("Project:", g.Root)
	fmt.Println("Agent requests:", filepath.Join(stateDir(g.Root), "requests"))
	go func() {
		<-ctx.Done()
		shutdown, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		_ = server.Shutdown(shutdown)
	}()
	err = server.Serve(listener)
	if err == http.ErrServerClosed {
		return nil
	}
	return err
}
