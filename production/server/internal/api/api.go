// Package api exposes the versioned, authenticated REX HTTP boundary.
package api

import (
	"crypto/sha256"
	"crypto/subtle"
	"encoding/json"
	"errors"
	"io"
	"mime"
	"net"
	"net/http"
	"strings"
	"sync"
	"time"

	"rex/production/server/internal/service"
)

type bucket struct {
	At    time.Time
	Count int
}

type handler struct {
	s            *service.Service
	mu           sync.Mutex
	buckets      map[string]bucket
	adminHash    [32]byte
	adminEnabled bool
	inflight     chan struct{}
	nextSweep    time.Time
}

type Options struct {
	AdminToken string
	// Bounds application work, including slow request bodies and storage waits.
	// Zero uses 64; values above 256 are clamped, pending measured capacity review.
	MaxInFlight int
}

func New(s *service.Service, options ...Options) http.Handler {
	h := &handler{s: s, buckets: make(map[string]bucket)}
	capacity := 64
	if len(options) > 0 && options[0].MaxInFlight > 0 {
		capacity = min(options[0].MaxInFlight, 256)
	}
	h.inflight = make(chan struct{}, capacity)
	if len(options) > 0 && len(options[0].AdminToken) >= 32 {
		h.adminHash = sha256.Sum256([]byte(options[0].AdminToken))
		h.adminEnabled = true
	}
	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, r *http.Request) { write(w, 200, map[string]string{"status": "ok"}) })
	mux.HandleFunc("POST /v1/guests", h.guest)
	mux.HandleFunc("GET /v1/me", h.me)
	mux.HandleFunc("DELETE /v1/session", h.logout)
	mux.HandleFunc("POST /v1/tables", h.action("create"))
	mux.HandleFunc("POST /v1/tables/join", h.action("join"))
	mux.HandleFunc("GET /v1/tables/{id}", h.table)
	mux.HandleFunc("POST /v1/tables/{id}/ready", h.action("ready"))
	mux.HandleFunc("POST /v1/tables/{id}/leave", h.action("leave"))
	mux.HandleFunc("POST /v1/tables/{id}/start", h.action("start"))
	if h.adminEnabled {
		mux.HandleFunc("GET /v1/admin/overview", h.overview)
	}
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Cache-Control", "no-store")
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Header().Set("Referrer-Policy", "no-referrer")
		// Health remains available during application overload. The listener and
		// TLS proxy still need independent connection/header/body limits.
		if r.URL.Path != "/healthz" {
			select {
			case h.inflight <- struct{}{}:
				defer func() { <-h.inflight }()
			default:
				w.Header().Set("Retry-After", "1")
				write(w, 503, map[string]string{"error": "server_busy"})
				return
			}
		}
		// Do not trust arbitrary X-Forwarded-For headers. Proxy rate limiting is
		// additionally required at deployment when clients share a proxy address.
		if !h.allow(r) {
			w.Header().Set("Retry-After", "60")
			write(w, 429, map[string]string{"error": "rate_limited"})
			return
		}
		mux.ServeHTTP(w, r)
	})
}

func (h *handler) overview(w http.ResponseWriter, r *http.Request) {
	got := sha256.Sum256([]byte(bearer(r)))
	if subtle.ConstantTimeCompare(got[:], h.adminHash[:]) != 1 {
		fail(w, service.ErrAuth)
		return
	}
	write(w, 200, h.s.Overview())
}

func (h *handler) allow(r *http.Request) bool {
	if r.URL.Path == "/healthz" {
		return true
	}
	ip, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		ip = r.RemoteAddr
	}
	limit := 180
	if r.URL.Path == "/v1/guests" {
		ip = "guest:" + ip
		limit = 5
	}
	h.mu.Lock()
	defer h.mu.Unlock()
	now := time.Now()
	b := h.buckets[ip]
	if now.Sub(b.At) >= time.Minute {
		b = bucket{At: now}
	}
	if b.Count >= limit {
		return false
	}
	// Sweep at most once a minute, rather than scanning 10,000 entries on
	// every new source address during a cardinality attack.
	if !now.Before(h.nextSweep) {
		for key, value := range h.buckets {
			if now.Sub(value.At) >= time.Minute {
				delete(h.buckets, key)
			}
		}
		h.nextSweep = now.Add(time.Minute)
	}
	if _, exists := h.buckets[ip]; !exists && len(h.buckets) >= 10000 {
		return false
	}
	b.Count++
	h.buckets[ip] = b
	return true
}

func bearer(r *http.Request) string {
	value := r.Header.Get("Authorization")
	if !strings.HasPrefix(value, "Bearer ") {
		return ""
	}
	return strings.TrimPrefix(value, "Bearer ")
}

func write(w http.ResponseWriter, status int, value any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(value)
}

func fail(w http.ResponseWriter, err error) {
	status := http.StatusInternalServerError
	code := "internal_error"
	switch {
	case errors.Is(err, service.ErrAuth):
		status = 401
		code = err.Error()
	case errors.Is(err, service.ErrInput):
		status = 400
		code = err.Error()
	case errors.Is(err, service.ErrNotFound):
		status = 404
		code = err.Error()
	case errors.Is(err, service.ErrConflict), errors.Is(err, service.ErrFull):
		status = 409
		code = err.Error()
	case errors.Is(err, service.ErrRules), errors.Is(err, service.ErrCapacity):
		status = 503
		code = err.Error()
	}
	// Never echo raw persistence errors, request bodies, bearer tokens or hands.
	write(w, status, map[string]string{"error": code})
}

func decode(w http.ResponseWriter, r *http.Request, value any) error {
	mediaType, parameters, err := mime.ParseMediaType(r.Header.Get("Content-Type"))
	if err != nil || mediaType != "application/json" || (parameters["charset"] != "" && !strings.EqualFold(parameters["charset"], "utf-8")) {
		return service.ErrInput
	}
	r.Body = http.MaxBytesReader(w, r.Body, 4096)
	// Commands are flat JSON objects. Reject null, duplicate keys and case
	// aliases rather than relying on encoding/json's last-value/case matching.
	d := json.NewDecoder(r.Body)
	start, err := d.Token()
	if err != nil || start != json.Delim('{') {
		return service.ErrInput
	}
	fields := map[string]json.RawMessage{}
	allowed := map[string]bool{}
	switch value.(type) {
	case *service.Command:
		for _, key := range []string{"action_id", "expected_version", "game", "invite", "ready"} {
			allowed[key] = true
		}
	case *struct{}:
	default:
		return service.ErrInput
	}
	for d.More() {
		key, err := d.Token()
		if err != nil {
			return service.ErrInput
		}
		name, ok := key.(string)
		if !ok || !allowed[name] {
			return service.ErrInput
		}
		if _, exists := fields[name]; exists {
			return service.ErrInput
		}
		var raw json.RawMessage
		if err := d.Decode(&raw); err != nil || string(raw) == "null" {
			return service.ErrInput
		}
		fields[name] = raw
	}
	if end, err := d.Token(); err != nil || end != json.Delim('}') {
		return service.ErrInput
	}
	if err := d.Decode(new(any)); !errors.Is(err, io.EOF) {
		return service.ErrInput
	}
	data, err := json.Marshal(fields)
	if err != nil {
		return service.ErrInput
	}
	if err := json.Unmarshal(data, value); err != nil {
		return service.ErrInput
	}
	return nil
}

func (h *handler) guest(w http.ResponseWriter, r *http.Request) {
	var empty struct{}
	if err := decode(w, r, &empty); err != nil {
		fail(w, err)
		return
	}
	g, err := h.s.NewGuest()
	if err != nil {
		fail(w, err)
		return
	}
	write(w, 201, g)
}

func (h *handler) me(w http.ResponseWriter, r *http.Request) {
	m, err := h.s.Me(bearer(r))
	if err != nil {
		fail(w, err)
		return
	}
	write(w, 200, m)
}

func (h *handler) logout(w http.ResponseWriter, r *http.Request) {
	if err := h.s.Logout(bearer(r)); err != nil {
		fail(w, err)
		return
	}
	w.WriteHeader(204)
}

func (h *handler) table(w http.ResponseWriter, r *http.Request) {
	t, err := h.s.Table(bearer(r), r.PathValue("id"))
	if err != nil {
		fail(w, err)
		return
	}
	write(w, 200, t)
}

func (h *handler) action(operation string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var c service.Command
		if err := decode(w, r, &c); err != nil {
			fail(w, err)
			return
		}
		t, err := h.s.Act(bearer(r), operation, r.PathValue("id"), c)
		if err != nil {
			fail(w, err)
			return
		}
		write(w, 200, t)
	}
}
