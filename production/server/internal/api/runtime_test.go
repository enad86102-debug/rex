package api

import (
	"encoding/json"
	"io"
	"net/http/httptest"
	"path/filepath"
	"strings"
	"testing"

	"rex/production/server/internal/service"
)

func TestRuntimeCountersRequireAdminAndBoundedValues(t *testing.T) {
	s, err := service.Open(filepath.Join(t.TempDir(), "state.json"))
	if err != nil {
		t.Fatal(err)
	}
	g, err := s.NewGuest()
	if err != nil {
		t.Fatal(err)
	}
	secret := strings.Repeat("ops-secret-only-for-test", 2)
	if w := httptest.NewRecorder(); true {
		New(s).ServeHTTP(w, httptest.NewRequest("GET", "/v1/admin/runtime", nil))
		if w.Code != 404 {
			t.Fatal("runtime route exposed by default")
		}
	}
	h := New(s, Options{AdminToken: secret, MaxInFlight: 1})
	for _, headers := range [][]string{nil, {g.Token}, {secret, g.Token}} {
		r := httptest.NewRequest("GET", "/v1/admin/runtime", nil)
		for _, token := range headers {
			r.Header.Add("Authorization", "Bearer "+token)
		}
		w := httptest.NewRecorder()
		h.ServeHTTP(w, r)
		if w.Code != 401 {
			t.Fatalf("non-admin runtime access: %d", w.Code)
		}
	}
	reader, writer := io.Pipe()
	defer reader.Close()
	defer writer.Close()
	slow := httptest.NewRequest("POST", "/v1/guests", reader)
	slow.Header.Set("Content-Type", "application/json")
	done := make(chan struct{})
	go func() { defer close(done); h.ServeHTTP(httptest.NewRecorder(), slow) }()
	if _, err := writer.Write([]byte("{")); err != nil {
		t.Fatal(err)
	}
	w := httptest.NewRecorder()
	h.ServeHTTP(w, httptest.NewRequest("GET", "/v1/me", nil))
	if w.Code != 503 {
		t.Fatal("admission not measured")
	}
	if err := writer.Close(); err != nil {
		t.Fatal(err)
	}
	<-done
	for i := 0; i < 6; i++ {
		r := httptest.NewRequest("POST", "/v1/guests", strings.NewReader(`{}`))
		r.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()
		h.ServeHTTP(w, r)
		if i == 5 && w.Code != 429 {
			t.Fatal("rate limiter not measured")
		}
	}
	for i := 0; i < 181; i++ {
		w := httptest.NewRecorder()
		h.ServeHTTP(w, httptest.NewRequest("GET", "/v1/me", nil))
		if i == 180 && w.Code != 429 {
			t.Fatal("public request bucket did not fill")
		}
	}
	r := httptest.NewRequest("GET", "/v1/admin/runtime", nil)
	r.Header.Set("Authorization", "Bearer "+secret)
	w = httptest.NewRecorder()
	h.ServeHTTP(w, r)
	if w.Code != 200 {
		t.Fatalf("admin runtime: %d", w.Code)
	}
	var data map[string]int
	if err := json.Unmarshal(w.Body.Bytes(), &data); err != nil {
		t.Fatal(err)
	}
	if data["max_in_flight"] != 1 || data["overloaded_total"] < 1 || data["rate_limited_total"] < 1 || data["rate_limit_buckets"] > 10000 {
		t.Fatal("missing or unbounded counters")
	}
	for _, sensitive := range []string{g.Token, g.Me.Player.ID, secret} {
		if strings.Contains(w.Body.String(), sensitive) {
			t.Fatal("runtime disclosed identity or credentials")
		}
	}
}
