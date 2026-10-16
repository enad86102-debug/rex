package api

import (
	"net/http/httptest"
	"path/filepath"
	"strings"
	"testing"

	"rex/production/server/internal/service"
)

func TestEveryPrivateRouteRejectsMissingForgedAndRevokedSessions(t *testing.T) {
	s, err := service.Open(filepath.Join(t.TempDir(), "state.json"))
	if err != nil {
		t.Fatal(err)
	}
	g, err := s.NewGuest()
	if err != nil {
		t.Fatal(err)
	}
	table, err := s.Act(g.Token, "create", "", service.Command{ActionID: "auth-matrix-create-1", Game: "tarneeb"})
	if err != nil {
		t.Fatal(err)
	}
	if err := s.Logout(g.Token); err != nil {
		t.Fatal(err)
	}
	h := New(s)
	for _, token := range []string{"", strings.Repeat("a", 64), g.Token} {
		for _, route := range []struct{ method, path, body string }{
			{"GET", "/v1/me", ""}, {"DELETE", "/v1/session", ""},
			{"GET", "/v1/tables/" + table.ID, ""},
			{"POST", "/v1/tables", `{"action_id":"auth-matrix-create-2","game":"tarneeb"}`},
			{"POST", "/v1/tables/join", `{"action_id":"auth-matrix-join-001","invite":"` + table.Invite + `"}`},
			{"POST", "/v1/tables/" + table.ID + "/ready", `{"action_id":"auth-matrix-ready-01","expected_version":1,"ready":true}`},
			{"POST", "/v1/tables/" + table.ID + "/leave", `{"action_id":"auth-matrix-leave-01","expected_version":1}`},
			{"POST", "/v1/tables/" + table.ID + "/start", `{"action_id":"auth-matrix-start-01","expected_version":1}`},
		} {
			r := httptest.NewRequest(route.method, route.path, strings.NewReader(route.body))
			r.Header.Set("Content-Type", "application/json")
			if token != "" {
				r.Header.Set("Authorization", "Bearer "+token)
			}
			w := httptest.NewRecorder()
			h.ServeHTTP(w, r)
			if w.Code != 401 {
				t.Fatalf("%s %s returned %d for invalid session", route.method, route.path, w.Code)
			}
			if strings.Contains(w.Body.String(), table.Invite) || strings.Contains(w.Body.String(), g.Token) {
				t.Fatal("restricted material in error")
			}
		}
	}
}
