package api

import (
	"net/http/httptest"
	"strings"
	"testing"

	"rex/production/server/internal/service"
)

func FuzzCommandDecoder(f *testing.F) {
	for _, seed := range []string{`{}`, `null`, `{"ready":true}`, `{"ready":false,"ready":true}`, `{"expected_version":18446744073709551616}`, `[{}]`, `{"invite":"\ud800"}`} {
		f.Add(seed)
	}
	f.Fuzz(func(t *testing.T, body string) {
		if len(body) > 8192 {
			return
		}
		r := httptest.NewRequest("POST", "/v1/tables", strings.NewReader(body))
		r.Header.Set("Content-Type", "application/json")
		var command service.Command
		if err := decode(httptest.NewRecorder(), r, &command); err == nil {
			if !strings.HasPrefix(strings.TrimSpace(body), "{") || len(body) > 4096 {
				t.Fatal("invalid accepted object")
			}
		}
	})
}
