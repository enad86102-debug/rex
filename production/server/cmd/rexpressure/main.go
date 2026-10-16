// rexpressure exercises the real TLS HTTP boundary on an isolated temporary
// store. It never targets a public service or prints account credentials.
package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"runtime"
	"sort"
	"sync"
	"time"

	"rex/production/server/internal/api"
	"rex/production/server/internal/service"
)

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func run() error {
	sources := flag.String("sources", "shared", "shared or distinct real loopback TCP source addresses")
	interval := flag.Duration("interval", 0, "optional per-worker request interval, at most 1s")
	flag.Parse()
	if (*sources != "shared" && *sources != "distinct") || *interval < 0 || *interval > time.Second {
		return fmt.Errorf("invalid sources mode")
	}
	dir, err := os.MkdirTemp("", "rex-pressure-")
	if err != nil {
		return err
	}
	defer os.RemoveAll(dir)
	path := filepath.Join(dir, "state.json")
	s, err := service.Open(path)
	if err != nil {
		return err
	}
	g, err := s.NewGuest()
	if err != nil {
		return err
	}
	table, err := s.Act(g.Token, "create", "", service.Command{ActionID: "pressure-create-0001", Game: "tarneeb"})
	if err != nil {
		return err
	}
	command, err := json.Marshal(service.Command{ActionID: "pressure-ready-00001", ExpectedVersion: table.Version, Ready: true})
	if err != nil {
		return err
	}
	server := httptest.NewTLSServer(api.New(s))
	defer server.Close()
	client := server.Client()
	client.Timeout = 5 * time.Second
	defer client.CloseIdleConnections()
	const workers, count = 64, 4096
	type result struct {
		Status   int
		Duration time.Duration
		Health   bool
		Err      bool
	}
	results := make(chan result, count)
	var before, after runtime.MemStats
	runtime.ReadMemStats(&before)
	started := time.Now()
	var wg sync.WaitGroup
	for worker := 0; worker < workers; worker++ {
		wg.Add(1)
		go func(worker int) {
			defer wg.Done()
			workerClient := client
			if *sources == "distinct" {
				transport := client.Transport.(*http.Transport).Clone()
				dialer := &net.Dialer{Timeout: 5 * time.Second, LocalAddr: &net.TCPAddr{IP: net.ParseIP(fmt.Sprintf("127.0.0.%d", worker+2))}}
				transport.DialContext = dialer.DialContext
				workerClient = &http.Client{Transport: transport, Timeout: 5 * time.Second}
				defer workerClient.CloseIdleConnections()
			}
			for i := worker; i < count; i += workers {
				method, route := "GET", "/v1/tables/"+table.ID
				var body io.Reader
				health := i%8 == 0
				if health {
					route = "/healthz"
				} else if i%4 == 1 {
					method, route, body = "POST", route+"/ready", bytes.NewReader(command)
				}
				req, e := http.NewRequest(method, server.URL+route, body)
				if e != nil {
					results <- result{Err: true}
					continue
				}
				req.Header.Set("Authorization", "Bearer "+g.Token)
				if body != nil {
					req.Header.Set("Content-Type", "application/json")
				}
				t := time.Now()
				response, e := workerClient.Do(req)
				r := result{Duration: time.Since(t), Health: health, Err: e != nil}
				if e == nil {
					r.Status = response.StatusCode
					_, e = io.Copy(io.Discard, io.LimitReader(response.Body, 65537))
					closeErr := response.Body.Close()
					r.Err = e != nil || closeErr != nil
				}
				r.Duration = time.Since(t)
				results <- r
				if *interval > 0 && i+workers < count {
					time.Sleep(*interval)
				}
			}
		}(worker)
	}
	wg.Wait()
	close(results)
	elapsed := time.Since(started)
	runtime.ReadMemStats(&after)
	statuses := map[int]int{}
	failures, unhealthy := 0, 0
	latencies := make([]float64, 0, count)
	for r := range results {
		statuses[r.Status]++
		latencies = append(latencies, float64(r.Duration.Microseconds())/1000)
		if r.Err || (r.Status != 200 && r.Status != 429 && r.Status != 503) {
			failures++
		}
		if r.Health && (r.Err || r.Status != 200) {
			unhealthy++
		}
	}
	sort.Float64s(latencies)
	restored, e := service.Open(path)
	if e != nil {
		return e
	}
	final, e := restored.Table(g.Token, table.ID)
	if e != nil {
		return e
	}
	consistent := final.Version == table.Version+1 && final.Seats[0].Ready
	report := map[string]any{
		"scenario":               "isolated TLS waiting-room read + duplicate ready burst",
		"source_mode":            *sources,
		"per_worker_interval_ms": interval.Milliseconds(),
		"go_version":             runtime.Version(), "platform": runtime.GOOS + "/" + runtime.GOARCH, "logical_cpus": runtime.NumCPU(),
		"workers": workers, "requests": count, "seconds": elapsed.Seconds(),
		"responses_per_second": float64(count) / elapsed.Seconds(), "status_counts": statuses,
		"latency_ms_all_statuses":          map[string]float64{"p50": latencies[count/2], "p95": latencies[count*95/100], "p99": latencies[count*99/100]},
		"transport_or_unexpected_failures": failures, "health_failures": unhealthy,
		"heap_alloc_bytes_before": before.HeapAlloc, "heap_alloc_bytes_after": after.HeapAlloc,
		"total_allocated_bytes":                       after.TotalAlloc - before.TotalAlloc,
		"exactly_one_ready_effect_survives_reopen":    consistent,
		"not_a_gameplay_or_player_capacity_benchmark": true,
	}
	encoder := json.NewEncoder(os.Stdout)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(report); err != nil {
		return err
	}
	if failures > 0 || unhealthy > 0 || !consistent || (*sources == "shared" && statuses[429] == 0) || (*sources == "distinct" && statuses[200] != count) || elapsed > 30*time.Second+64*(*interval) {
		return fmt.Errorf("pressure invariants failed; inspect redacted report")
	}
	return nil
}
