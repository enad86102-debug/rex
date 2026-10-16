// Package service owns identity and private-table state. The file adapter is a
// single-process review candidate, not the adopted production database.
package service

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"
)

var (
	ErrAuth     = errors.New("unauthorized")
	ErrInput    = errors.New("invalid_input")
	ErrNotFound = errors.New("not_found")
	ErrConflict = errors.New("conflict")
	ErrFull     = errors.New("table_full")
	ErrRules    = errors.New("rules_not_approved")
	ErrCapacity = errors.New("capacity_reached")
)

type Player struct {
	ID        string    `json:"id"`
	CreatedAt time.Time `json:"created_at"`
}

type Session struct {
	PlayerID  string    `json:"player_id"`
	ExpiresAt time.Time `json:"expires_at"`
}

type Seat struct {
	PlayerID string `json:"player_id"`
	Ready    bool   `json:"ready"`
}

type Table struct {
	ID        string    `json:"id"`
	Invite    string    `json:"invite"`
	OwnerID   string    `json:"owner_id"`
	Game      string    `json:"game"`
	Version   uint64    `json:"version"`
	Seats     [4]*Seat  `json:"seats"`
	CreatedAt time.Time `json:"created_at"`
}

// Me is always scoped to the authenticated player. No public player listing.
type Me struct {
	Player    Player    `json:"player"`
	ExpiresAt time.Time `json:"expires_at"`
	TableID   string    `json:"table_id,omitempty"`
}

type Guest struct {
	Token string `json:"token"`
	Me    Me     `json:"me"`
}

type Command struct {
	ActionID        string `json:"action_id"`
	ExpectedVersion uint64 `json:"expected_version"`
	Game            string `json:"game,omitempty"`
	Invite          string `json:"invite,omitempty"`
	Ready           bool   `json:"ready"`
}

type Receipt struct {
	Fingerprint string    `json:"fingerprint"`
	Table       Table     `json:"table"`
	At          time.Time `json:"at"`
}

type Audit struct {
	At        time.Time `json:"at"`
	Actor     string    `json:"actor"`
	Operation string    `json:"operation"`
	TableID   string    `json:"table_id,omitempty"`
}

// Overview is a read-only support view: no bearer tokens, invitations or hands.
type Overview struct {
	Players        int     `json:"players"`
	ActiveSessions int     `json:"active_sessions"`
	WaitingTables  int     `json:"waiting_tables"`
	RecentEvents   []Audit `json:"recent_events"`
}

func (s *Service) Overview() Overview {
	s.mu.Lock()
	defer s.mu.Unlock()
	o := Overview{Players: len(s.s.Players), WaitingTables: len(s.s.Tables)}
	for _, session := range s.s.Sessions {
		if s.now().Before(session.ExpiresAt) {
			o.ActiveSessions++
		}
	}
	start := len(s.s.Audit) - 50
	if start < 0 {
		start = 0
	}
	o.RecentEvents = append([]Audit(nil), s.s.Audit[start:]...)
	return o
}

type state struct {
	Schema   int                `json:"schema"`
	Players  map[string]Player  `json:"players"`
	Sessions map[string]Session `json:"sessions"`
	Tables   map[string]Table   `json:"tables"`
	Receipts map[string]Receipt `json:"receipts"`
	Audit    []Audit            `json:"audit"`
}

type Service struct {
	mu   sync.Mutex
	path string
	s    state
	now  func() time.Time
}

func Open(path string) (*Service, error) {
	s := &Service{path: path, now: time.Now, s: state{Schema: 1,
		Players: map[string]Player{}, Sessions: map[string]Session{},
		Tables: map[string]Table{}, Receipts: map[string]Receipt{}}}
	// #nosec G304 -- operator-configured service-owned store; never request input.
	data, err := os.ReadFile(path)
	if err == nil {
		s.s = state{}
		if err = json.Unmarshal(data, &s.s); err != nil {
			return nil, fmt.Errorf("decode store: %w", err)
		}
		if s.s.Schema != 1 || s.s.Players == nil || s.s.Sessions == nil || s.s.Tables == nil || s.s.Receipts == nil {
			return nil, errors.New("unsupported or incomplete store")
		}
		if err := validateState(s.s); err != nil {
			return nil, err
		}
	} else if !errors.Is(err, os.ErrNotExist) {
		return nil, err
	}
	return s, nil
}

func randomID(bytes int) (string, error) {
	b := make([]byte, bytes)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return hex.EncodeToString(b), nil
}

func digest(value string) string {
	h := sha256.Sum256([]byte(value))
	return hex.EncodeToString(h[:])
}

// transaction publishes memory only after a complete snapshot has been synced
// and atomically renamed. Never acknowledge an action after a failed write.
func (s *Service) transaction(change func(*state) error) error {
	data, err := json.Marshal(s.s)
	if err != nil {
		return err
	}
	var next state
	if err = json.Unmarshal(data, &next); err != nil {
		return err
	}
	if err = change(&next); err != nil {
		return err
	}
	data, err = json.Marshal(next)
	if err != nil {
		return err
	}
	if err = os.MkdirAll(filepath.Dir(s.path), 0700); err != nil {
		return err
	}
	f, err := os.CreateTemp(filepath.Dir(s.path), ".rex-*")
	if err != nil {
		return err
	}
	defer os.Remove(f.Name())
	if _, err = f.Write(data); err != nil {
		return errors.Join(err, f.Close())
	}
	if err = f.Sync(); err != nil {
		return errors.Join(err, f.Close())
	}
	if err = f.Close(); err != nil {
		return err
	}
	dir, err := os.Open(filepath.Dir(s.path))
	if err != nil {
		return err
	}
	defer dir.Close()
	if err = os.Rename(f.Name(), s.path); err != nil {
		return err
	}
	s.s = next
	// A directory-sync failure leaves an ambiguous commit; action receipts still
	// make a same-ID retry safe. The caller must not assume failed means absent.
	return dir.Sync()
}

func (s *Service) NewGuest() (Guest, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if len(s.s.Players) >= 10000 {
		return Guest{}, ErrCapacity
	}
	id, err := randomID(16)
	if err != nil {
		return Guest{}, err
	}
	token, err := randomID(32)
	if err != nil {
		return Guest{}, err
	}
	now := s.now().UTC()
	p := Player{ID: id, CreatedAt: now}
	expiry := now.Add(30 * 24 * time.Hour)
	err = s.transaction(func(st *state) error {
		st.Players[id] = p
		st.Sessions[digest(token)] = Session{PlayerID: id, ExpiresAt: expiry}
		st.Audit = appendAudit(st.Audit, Audit{At: now, Actor: id, Operation: "guest.created"})
		return nil
	})
	if err != nil {
		return Guest{}, err
	}
	return Guest{Token: token, Me: Me{Player: p, ExpiresAt: expiry}}, nil
}

func appendAudit(a []Audit, event Audit) []Audit {
	// Bounded review adapter. Production audit retention/export requires review.
	if len(a) >= 10000 {
		a = a[len(a)-9999:]
	}
	return append(a, event)
}

func (s *Service) authenticate(token string) (Session, error) {
	if len(token) != 64 {
		return Session{}, ErrAuth
	}
	session, ok := s.s.Sessions[digest(token)]
	if !ok || !s.now().Before(session.ExpiresAt) {
		return Session{}, ErrAuth
	}
	return session, nil
}

func member(t Table, player string) int {
	for i, seat := range t.Seats {
		if seat != nil && seat.PlayerID == player {
			return i
		}
	}
	return -1
}

func tableFor(st *state, player string) string {
	for id, t := range st.Tables {
		if member(t, player) >= 0 {
			return id
		}
	}
	return ""
}

func (s *Service) Me(token string) (Me, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	session, err := s.authenticate(token)
	if err != nil {
		return Me{}, err
	}
	return Me{Player: s.s.Players[session.PlayerID], ExpiresAt: session.ExpiresAt, TableID: tableFor(&s.s, session.PlayerID)}, nil
}

func (s *Service) Logout(token string) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	session, err := s.authenticate(token)
	if err != nil {
		return err
	}
	return s.transaction(func(st *state) error {
		// Logout is an explicit departure from waiting rooms, not a gameplay
		// disconnection policy. Enforce it even when the client skips /leave.
		if id := tableFor(st, session.PlayerID); id != "" {
			if _, err := releaseWaitingSeat(st, id, session.PlayerID); err != nil {
				return err
			}
			st.Audit = appendAudit(st.Audit, Audit{At: s.now().UTC(), Actor: session.PlayerID, Operation: "table.leave", TableID: id})
		}
		delete(st.Sessions, digest(token))
		st.Audit = appendAudit(st.Audit, Audit{At: s.now().UTC(), Actor: session.PlayerID, Operation: "session.revoked"})
		return nil
	})
}

func (s *Service) Table(token, id string) (Table, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	session, err := s.authenticate(token)
	if err != nil {
		return Table{}, err
	}
	t, ok := s.s.Tables[id]
	if !ok || member(t, session.PlayerID) < 0 {
		return Table{}, ErrNotFound
	}
	return cloneTable(t), nil
}

func cloneTable(t Table) Table {
	for i, seat := range t.Seats {
		if seat != nil {
			copy := *seat
			t.Seats[i] = &copy
		}
	}
	return t
}

// Act serializes commands, requires membership and optimistic versions, and
// deduplicates by player/action ID. Reusing an ID for different input conflicts.
// There is deliberately no playable engine until a rules contract is approved.
func (s *Service) Act(token, operation, id string, c Command) (Table, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	session, err := s.authenticate(token)
	if err != nil {
		return Table{}, err
	}
	if len(c.ActionID) < 16 || len(c.ActionID) > 128 || strings.TrimSpace(c.ActionID) != c.ActionID {
		return Table{}, ErrInput
	}
	player := session.PlayerID
	key := player + ":" + c.ActionID
	input, _ := json.Marshal(struct {
		Operation, ID string
		Command       Command
	}{operation, id, c})
	fingerprint := digest(string(input))
	if receipt, ok := s.s.Receipts[key]; ok {
		if receipt.Fingerprint != fingerprint {
			return Table{}, ErrConflict
		}
		// A departed player must never regain access to an invitation through replay.
		if t, exists := s.s.Tables[receipt.Table.ID]; exists && member(t, player) < 0 && operation != "leave" {
			return Table{}, ErrNotFound
		}
		return cloneTable(receipt.Table), nil
	}
	if len(s.s.Receipts) >= 100000 {
		return Table{}, ErrCapacity
	}
	var result Table
	err = s.transaction(func(st *state) error {
		switch operation {
		case "create":
			if c.Game != "trix_complex" && c.Game != "tarneeb" {
				return ErrInput
			}
			if tableFor(st, player) != "" {
				return ErrConflict
			}
			if len(st.Tables) >= 10000 {
				return ErrCapacity
			}
			tableID, e := randomID(16)
			if e != nil {
				return e
			}
			invite, e := randomID(16)
			if e != nil {
				return e
			}
			result = Table{ID: tableID, Invite: invite, OwnerID: player, Game: c.Game, Version: 1, CreatedAt: s.now().UTC()}
			result.Seats[0] = &Seat{PlayerID: player}
			st.Tables[tableID] = result
		case "join":
			if len(c.Invite) != 32 {
				return ErrNotFound
			}
			for _, t := range st.Tables {
				if t.Invite == c.Invite {
					result = t
					break
				}
			}
			if result.ID == "" {
				return ErrNotFound
			}
			if member(result, player) >= 0 {
				break
			}
			if tableFor(st, player) != "" {
				return ErrConflict
			}
			seat := -1
			for i, existing := range result.Seats {
				if existing == nil {
					seat = i
					break
				}
			}
			if seat < 0 {
				return ErrFull
			}
			result.Seats[seat] = &Seat{PlayerID: player}
			result.Version++
			resetReady(&result)
			st.Tables[result.ID] = result
		case "ready", "leave", "start":
			t, ok := st.Tables[id]
			if !ok || member(t, player) < 0 {
				return ErrNotFound
			}
			if c.ExpectedVersion != t.Version {
				return ErrConflict
			}
			seat := member(t, player)
			if operation == "start" {
				if t.OwnerID != player {
					return ErrNotFound
				}
				return ErrRules
			}
			if operation == "ready" {
				t.Seats[seat].Ready = c.Ready
				t.Version++
				st.Tables[id] = t
				result = t
			} else {
				var err error
				result, err = releaseWaitingSeat(st, id, player)
				if err != nil {
					return err
				}
				result.Invite = ""
			}
		default:
			return ErrInput
		}
		st.Receipts[key] = Receipt{Fingerprint: fingerprint, Table: result, At: s.now().UTC()}
		st.Audit = appendAudit(st.Audit, Audit{At: s.now().UTC(), Actor: player, Operation: "table." + operation, TableID: result.ID})
		return nil
	})
	if err != nil {
		return Table{}, err
	}
	return cloneTable(result), nil
}

func releaseWaitingSeat(st *state, id, player string) (Table, error) {
	t, ok := st.Tables[id]
	if !ok || member(t, player) < 0 {
		return Table{}, ErrNotFound
	}
	invite, err := randomID(16)
	if err != nil {
		return Table{}, err
	}
	t.Seats[member(t, player)] = nil
	resetReady(&t)
	if t.OwnerID == player {
		t.OwnerID = ""
		for _, seat := range t.Seats {
			if seat != nil {
				t.OwnerID = seat.PlayerID
				break
			}
		}
	}
	t.Invite = invite
	t.Version++
	if t.OwnerID == "" {
		delete(st.Tables, id)
	} else {
		st.Tables[id] = t
	}
	return t, nil
}

func resetReady(t *Table) {
	for _, seat := range t.Seats {
		if seat != nil {
			seat.Ready = false
		}
	}
}
