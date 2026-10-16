package api

import (
	"bytes"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"path/filepath"
	"strings"
	"testing"

	"rex/production/server/internal/service"
)

func request(t *testing.T, client *http.Client, base, method, path, token string, body any) (int, []byte) {
	t.Helper()
	var reader io.Reader
	if body != nil {
		b, err := json.Marshal(body)
		if err != nil {
			t.Fatal(err)
		}
		reader = bytes.NewReader(b)
	}
	req, err := http.NewRequest(method, base+path, reader)
	if err != nil {
		t.Fatal(err)
	}
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	resp, err := client.Do(req)
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()
	data, err := io.ReadAll(resp.Body)
	if err != nil {
		t.Fatal(err)
	}
	if resp.Header.Get("Cache-Control") != "no-store" {
		t.Fatal("sensitive response cacheable")
	}
	return resp.StatusCode, data
}

func TestRealHTTPClientsFourSeatsAndRecovery(t *testing.T) {
	path := filepath.Join(t.TempDir(), "state.json")
	s, err := service.Open(path)
	if err != nil {
		t.Fatal(err)
	}
	server := httptest.NewTLSServer(New(s))
	defer server.Close()
	var guests [4]service.Guest
	clients := make([]*http.Client, 4)
	for i := range guests {
		// Independent connection pools represent real network clients, not local
		// simulation seats. This does not replace Android device validation.
		clients[i] = &http.Client{Transport: server.Client().Transport.(*http.Transport).Clone()}
		defer clients[i].CloseIdleConnections()
		status, data := request(t, clients[i], server.URL, "POST", "/v1/guests", "", map[string]any{})
		if status != 201 {
			t.Fatalf("guest: %d %s", status, data)
		}
		if err := json.Unmarshal(data, &guests[i]); err != nil {
			t.Fatal(err)
		}
	}
	status, data := request(t, clients[0], server.URL, "POST", "/v1/tables", guests[0].Token, service.Command{ActionID: "network-create-0001", Game: "trix_complex"})
	if status != 200 {
		t.Fatalf("create: %d %s", status, data)
	}
	var table service.Table
	if err := json.Unmarshal(data, &table); err != nil {
		t.Fatal(err)
	}
	status, _ = request(t, clients[1], server.URL, "GET", "/v1/tables/"+table.ID, guests[1].Token, nil)
	if status != 404 {
		t.Fatal("private table leaked over HTTP")
	}
	for i := 1; i < 4; i++ {
		status, data = request(t, clients[i], server.URL, "POST", "/v1/tables/join", guests[i].Token, service.Command{ActionID: "network-join-00001", Invite: table.Invite})
		if status != 200 {
			t.Fatalf("join: %d %s", status, data)
		}
		if err := json.Unmarshal(data, &table); err != nil {
			t.Fatal(err)
		}
	}
	for i := range guests {
		status, data = request(t, clients[i], server.URL, "POST", "/v1/tables/"+table.ID+"/ready", guests[i].Token, service.Command{ActionID: "network-ready-0001", ExpectedVersion: table.Version, Ready: true})
		if status != 200 {
			t.Fatalf("ready: %d %s", status, data)
		}
		if err := json.Unmarshal(data, &table); err != nil {
			t.Fatal(err)
		}
	}
	server.CloseClientConnections()
	restored, err := service.Open(path)
	if err != nil {
		t.Fatal(err)
	}
	restart := httptest.NewTLSServer(New(restored))
	defer restart.Close()
	for _, g := range guests {
		status, data = request(t, restart.Client(), restart.URL, "GET", "/v1/me", g.Token, nil)
		if status != 200 || !bytes.Contains(data, []byte(table.ID)) {
			t.Fatal("session recovery failed")
		}
		status, data = request(t, restart.Client(), restart.URL, "GET", "/v1/tables/"+table.ID, g.Token, nil)
		if status != 200 {
			t.Fatal("table recovery failed")
		}
		if bytes.Contains(data, []byte("hands")) || bytes.Contains(data, []byte("token")) {
			t.Fatal("unexpected private data")
		}
	}
	status, data = request(t, restart.Client(), restart.URL, "POST", "/v1/tables/"+table.ID+"/start", guests[0].Token, service.Command{ActionID: "network-start-0001", ExpectedVersion: table.Version})
	if status != 503 || !bytes.Contains(data, []byte("rules_not_approved")) {
		t.Fatal("missing production rule gate")
	}
}

func TestMalformedUnauthorizedAndRateLimit(t *testing.T) {
	s, err := service.Open(filepath.Join(t.TempDir(), "state.json"))
	if err != nil {
		t.Fatal(err)
	}
	h := New(s)
	for _, body := range []string{`{"unknown":1}`, `{} {}`, `{"action_id":`, strings.Repeat("x", 5000)} {
		r := httptest.NewRequest("POST", "/v1/tables", strings.NewReader(body))
		r.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()
		h.ServeHTTP(w, r)
		if w.Code != 400 {
			t.Fatalf("malformed body accepted: %d", w.Code)
		}
	}
	r := httptest.NewRequest("GET", "/v1/me", nil)
	w := httptest.NewRecorder()
	h.ServeHTTP(w, r)
	if w.Code != 401 {
		t.Fatal("anonymous access accepted")
	}
	for i := 0; i < 6; i++ {
		r := httptest.NewRequest("POST", "/v1/guests", strings.NewReader(`{}`))
		r.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()
		h.ServeHTTP(w, r)
		if i < 5 && w.Code != 201 {
			t.Fatal("unexpected guest rejection")
		}
		if i == 5 && (w.Code != 429 || w.Header().Get("Retry-After") == "") {
			t.Fatal("guest creation unlimited")
		}
	}
}

func TestAdminIsDisabledByDefaultAndNeverExposesSecrets(t *testing.T) {
	s, err := service.Open(filepath.Join(t.TempDir(), "state.json"))
	if err != nil {
		t.Fatal(err)
	}
	g, err := s.NewGuest()
	if err != nil {
		t.Fatal(err)
	}
	table, err := s.Act(g.Token, "create", "", service.Command{ActionID: "admin-test-create-01", Game: "tarneeb"})
	if err != nil {
		t.Fatal(err)
	}
	defaultHandler := New(s)
	r := httptest.NewRequest("GET", "/v1/admin/overview", nil)
	w := httptest.NewRecorder()
	defaultHandler.ServeHTTP(w, r)
	if w.Code != 404 {
		t.Fatal("admin route enabled without credentials")
	}
	secret := strings.Repeat("test-admin-credential", 3)
	h := New(s, Options{AdminToken: secret})
	for _, token := range []string{"", g.Token, secret} {
		r := httptest.NewRequest("GET", "/v1/admin/overview", nil)
		r.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		h.ServeHTTP(w, r)
		if token != secret && w.Code != 401 {
			t.Fatal("non-admin authorized")
		}
		if token == secret {
			if w.Code != 200 || !strings.Contains(w.Body.String(), "guest.created") {
				t.Fatal("missing ops overview")
			}
			for _, sensitive := range []string{g.Token, table.Invite, secret, "expires_at"} {
				if strings.Contains(w.Body.String(), sensitive) {
					t.Fatal("admin overview leaks restricted data")
				}
			}
		}
	}
}
