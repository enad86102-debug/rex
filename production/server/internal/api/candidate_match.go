//go:build rex_candidate

package api

import (
	"bytes"
	"encoding/json"
	"errors"
	"io"
	"mime"
	"net/http"
	"os"
	"strings"

	"rex/production/server/internal/service"
)

// NewCandidate uses the SAME admission, rate limiter and in-flight middleware
// as the production router. No candidate route is registered by New or rexd.
func NewCandidate(s *service.Service, c *service.CandidateCoordinator, options ...Options) http.Handler {
	return newRouter(s, func(mux *http.ServeMux, _ *handler) {
		mux.HandleFunc("GET /v1/tables/{id}/match", func(w http.ResponseWriter, r *http.Request) {
			result, err := c.View(bearer(r), r.PathValue("id"))
			if err != nil {
				candidateFail(w, err)
				return
			}
			write(w, http.StatusOK, result)
		})
		mux.HandleFunc("POST /v1/tables/{id}/match/start", func(w http.ResponseWriter, r *http.Request) {
			var empty struct{}
			if err := decode(w, r, &empty); err != nil {
				fail(w, err)
				return
			}
			result, err := c.Start(bearer(r), r.PathValue("id"))
			if err != nil {
				candidateFail(w, err)
				return
			}
			write(w, http.StatusOK, result)
		})
		mux.HandleFunc("POST /v1/tables/{id}/match/actions", func(w http.ResponseWriter, r *http.Request) {
			command, err := decodeCandidateAction(w, r)
			if err != nil {
				fail(w, service.ErrInput)
				return
			}
			result, err := c.Apply(bearer(r), r.PathValue("id"), command)
			if err != nil {
				candidateFail(w, err)
				return
			}
			write(w, http.StatusOK, result)
		})
	}, options...)
}

func candidateFail(w http.ResponseWriter, err error) {
	if errors.Is(err, io.EOF) || errors.Is(err, os.ErrNotExist) {
		fail(w, service.ErrNotFound)
		return
	}
	fail(w, err)
}

// Strict top-level action parser. User-controlled actor_id, claimed_seat,
// rules_version, and private state fields are always rejected before service.
func decodeCandidateAction(w http.ResponseWriter, r *http.Request) (service.CandidateCommand, error) {
	var cmd service.CandidateCommand
	media, params, err := mime.ParseMediaType(r.Header.Get("Content-Type"))
	if err != nil || media != "application/json" ||
		(params["charset"] != "" && !strings.EqualFold(params["charset"], "utf-8")) {
		return cmd, service.ErrInput
	}
	decoder := json.NewDecoder(http.MaxBytesReader(w, r.Body, 4096))
	open, err := decoder.Token()
	if err != nil || open != json.Delim('{') {
		return cmd, service.ErrInput
	}
	allowed := map[string]bool{
		"action_id": true, "expected_version": true, "type": true,
		"contract": true, "card": true,
	}
	values := map[string]json.RawMessage{}
	for decoder.More() {
		key, err := decoder.Token()
		if err != nil {
			return cmd, service.ErrInput
		}
		name, ok := key.(string)
		if !ok || !allowed[name] || values[name] != nil {
			return cmd, service.ErrInput
		}
		var raw json.RawMessage
		if err := decoder.Decode(&raw); err != nil || bytes.Equal(raw, []byte("null")) {
			return cmd, service.ErrInput
		}
		values[name] = raw
	}
	end, err := decoder.Token()
	if err != nil || end != json.Delim('}') {
		return cmd, service.ErrInput
	}
	if err := decoder.Decode(new(any)); !errors.Is(err, io.EOF) {
		return cmd, service.ErrInput
	}
	if len(values["action_id"]) == 0 || len(values["expected_version"]) == 0 || len(values["type"]) == 0 {
		return cmd, service.ErrInput
	}
	if value, exists := values["card"]; exists {
		if err := validateCandidateCard(value); err != nil {
			return cmd, service.ErrInput
		}
	}
	encoded, err := json.Marshal(values)
	if err != nil {
		return cmd, service.ErrInput
	}
	strict := json.NewDecoder(bytes.NewReader(encoded))
	strict.DisallowUnknownFields()
	if err := strict.Decode(&cmd); err != nil {
		return cmd, service.ErrInput
	}
	return cmd, nil
}

func validateCandidateCard(raw []byte) error {
	d := json.NewDecoder(bytes.NewReader(raw))
	start, err := d.Token()
	if err != nil || start != json.Delim('{') {
		return service.ErrInput
	}
	seen := map[string]bool{}
	for d.More() {
		key, err := d.Token()
		if err != nil {
			return service.ErrInput
		}
		field, ok := key.(string)
		if !ok || (field != "suit" && field != "rank") || seen[field] {
			return service.ErrInput
		}
		seen[field] = true
		var value uint8
		if err := d.Decode(&value); err != nil {
			return service.ErrInput
		}
	}
	end, err := d.Token()
	if err != nil || end != json.Delim('}') || len(seen) != 2 {
		return service.ErrInput
	}
	if err := d.Decode(new(any)); !errors.Is(err, io.EOF) {
		return service.ErrInput
	}
	return nil
}
