package api

import (
	"io"
	"net/http/httptest"
	"path/filepath"
	"testing"
	"time"

	"rex/production/server/internal/service"
)

func TestOverloadRejectsBeforeReadingBodyAndRecovers(t *testing.T) {
	s, err := service.Open(filepath.Join(t.TempDir(), "state.json"))
	if err != nil {
		t.Fatal(err)
	}
	h := New(s, Options{MaxInFlight: 1})
	reader, writer := io.Pipe()
	defer reader.Close()
	defer writer.Close()
	r := httptest.NewRequest("POST", "/v1/guests", reader)
	r.Header.Set("Content-Type", "application/json")
	done := make(chan struct{})
	go func() { defer close(done); h.ServeHTTP(httptest.NewRecorder(), r) }()
	// A pipe read proves the first request holds the admission slot.
	if _, err := writer.Write([]byte("{")); err != nil {
		t.Fatal(err)
	}
	w := httptest.NewRecorder()
	h.ServeHTTP(w, httptest.NewRequest("POST", "/v1/guests", nil))
	if w.Code != 503 || w.Header().Get("Retry-After") != "1" {
		t.Fatalf("overload: %d", w.Code)
	}
	w = httptest.NewRecorder()
	h.ServeHTTP(w, httptest.NewRequest("GET", "/healthz", nil))
	if w.Code != 200 {
		t.Fatal("health blocked by slow body")
	}
	if err := writer.Close(); err != nil {
		t.Fatal(err)
	}
	select {
	case <-done:
	case <-time.After(3 * time.Second):
		t.Fatal("slot not released")
	}
	w = httptest.NewRecorder()
	h.ServeHTTP(w, httptest.NewRequest("GET", "/v1/me", nil))
	if w.Code != 401 {
		t.Fatalf("did not recover: %d", w.Code)
	}
}

func TestLimiterCardinalityBoundAndExpiredRecovery(t *testing.T) {
	h := &handler{buckets: make(map[string]bucket), nextSweep: time.Now().Add(time.Minute)}
	for i := 0; i < 10000; i++ {
		h.buckets[time.Unix(int64(i), 0).String()] = bucket{At: time.Now()}
	}
	r := httptest.NewRequest("GET", "/v1/me", nil)
	r.RemoteAddr = "192.0.2.20:1234"
	if h.allow(r) || len(h.buckets) != 10000 {
		t.Fatal("unbounded limiter")
	}
	for key, b := range h.buckets {
		b.At = time.Now().Add(-2 * time.Minute)
		h.buckets[key] = b
	}
	h.nextSweep = time.Time{}
	if !h.allow(r) || len(h.buckets) != 1 {
		t.Fatal("expired capacity not recovered")
	}
}
