package api

import (
	"net/http/httptest"
	"path/filepath"
	"strings"
	"testing"

	"rex/production/server/internal/service"
)

func TestJSONContractRejectsNullDuplicatesAndAcceptsUTF8(t *testing.T) {
	for _, tc := range []struct {
		name, body, contentType string
		want                    int
	}{
		{"null", "null", "application/json", 400},
		{"duplicate", `{"action_id":"aaaaaaaaaaaaaaaa","action_id":"bbbbbbbbbbbbbbbb"}`, "application/json", 400},
		{"case alias", `{"Action_ID":"aaaaaaaaaaaaaaaa"}`, "application/json", 400},
		{"utf8", `{}`, "application/json; charset=utf-8", 201},
	} {
		t.Run(tc.name, func(t *testing.T) {
			s, err := service.Open(filepath.Join(t.TempDir(), "state.json"))
			if err != nil {
				t.Fatal(err)
			}
			h := New(s)
			path := "/v1/guests"
			if tc.name == "duplicate" || tc.name == "case alias" {
				path = "/v1/tables"
			}
			r := httptest.NewRequest("POST", path, strings.NewReader(tc.body))
			r.Header.Set("Content-Type", tc.contentType)
			w := httptest.NewRecorder()
			h.ServeHTTP(w, r)
			if w.Code != tc.want {
				t.Fatalf("got %d, want %d", w.Code, tc.want)
			}
		})
	}
}
