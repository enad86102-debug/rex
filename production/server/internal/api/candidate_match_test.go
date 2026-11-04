//go:build rex_candidate

package api

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"path/filepath"
	"testing"

	"rex/production/server/internal/games/trixcomplex"
	"rex/production/server/internal/service"
)

type candidateTestHarness struct {
	t      *testing.T
	h      http.Handler
	s      *service.Service
	c      *service.CandidateCoordinator
	tokens [4]string
	id     string
	version uint64
	calls  int
}

func candidateHarness(t *testing.T) *candidateTestHarness {
	t.Helper()
	root := t.TempDir()
	s, err := service.Open(filepath.Join(root, "rooms.json"))
	if err != nil {
		t.Fatal(err)
	}
	h := &candidateTestHarness{t: t, s: s}
	var table service.Table
	for i := range h.tokens {
		guest, err := s.NewGuest()
		if err != nil {
			t.Fatal(err)
		}
		h.tokens[i] = guest.Token
		if i == 0 {
			table, err = s.Act(h.tokens[0], "create", "", service.Command{
				ActionID: fmt.Sprintf("candidate-create-%016d", i), Game: "trix_complex",
			})
		} else {
			table, err = s.Act(h.tokens[i], "join", "", service.Command{
				ActionID: fmt.Sprintf("candidate-join-%016d", i), Invite: table.Invite,
			})
		}
		if err != nil {
			t.Fatal(err)
		}
	}
	for i := range h.tokens {
		var err error
		table, err = s.Act(h.tokens[i], "ready", table.ID, service.Command{
			ActionID: fmt.Sprintf("candidate-ready-%016d", i),
			ExpectedVersion: table.Version, Ready: true,
		})
		if err != nil {
			t.Fatal(err)
		}
	}
	h.id = table.ID
	h.version = table.Version
	h.c = service.NewCandidateCoordinator(s, filepath.Join(root, "candidate-private"))
	h.h = NewCandidate(s, h.c)
	return h
}

func (h *candidateTestHarness) call(seat int, method, path string, body any) (int, []byte) {
	h.t.Helper()
	var raw []byte
	if body != nil {
		var err error
		raw, err = json.Marshal(body)
		if err != nil {
			h.t.Fatal(err)
		}
	}
	req := httptest.NewRequest(method, path, bytes.NewReader(raw))
	req.Header.Set("Authorization", "Bearer "+h.tokens[seat])
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	// The full-game test does not benchmark NAT limits. It exercises the real
	// admission wrapper but distributes local synthetic source addresses.
	h.calls++
	req.RemoteAddr = fmt.Sprintf("198.51.100.%d:%d", 1+h.calls%200, 30000+h.calls%10000)
	rec := httptest.NewRecorder()
	h.h.ServeHTTP(rec, req)
	return rec.Code, rec.Body.Bytes()
}

func (h *candidateTestHarness) response(seat int, method, path string, body any) service.CandidateResponse {
	h.t.Helper()
	status, raw := h.call(seat, method, path, body)
	if status != http.StatusOK {
		h.t.Fatalf("seat %d %s %s: HTTP %d: %s", seat, method, path, status, raw)
	}
	var resp service.CandidateResponse
	if err := json.Unmarshal(raw, &resp); err != nil {
		h.t.Fatal(err)
	}
	return resp
}

func TestCandidateRoutesAbsentFromPublicAPI(t *testing.T) {
	h := candidateHarness(t)
	public := New(h.s)
	req := httptest.NewRequest(http.MethodGet, "/v1/tables/"+h.id+"/match", nil)
	req.Header.Set("Authorization", "Bearer "+h.tokens[0])
	rec := httptest.NewRecorder()
	public.ServeHTTP(rec, req)
	if rec.Code != http.StatusNotFound {
		t.Fatalf("public rexd unexpectedly exposes candidate route: HTTP %d", rec.Code)
	}
	status, raw := h.call(0, http.MethodPost, "/v1/tables/"+h.id+"/start",
		map[string]any{"action_id": "public-start-000000001", "expected_version": h.version})
	if status != http.StatusServiceUnavailable || !bytes.Contains(raw, []byte("rules_not_approved")) {
		t.Fatalf("public match activation should remain gated: %d %s", status, raw)
	}
}

func TestCandidateStrictBodyRejectsForgedIdentityAndUnknownFields(t *testing.T) {
	h := candidateHarness(t)
	path := "/v1/tables/" + h.id + "/match/actions"
	for _, raw := range []string{
		`{"action_id":"candidate-action-0001","expected_version":1,"type":"play_card","actor_id":"other"}`,
		`{"action_id":"candidate-action-0001","expected_version":1,"type":"play_card","claimed_seat":0}`,
		`{"action_id":"candidate-action-0001","expected_version":1,"type":"play_card","rules_version":"fake"}`,
		`{"action_id":"candidate-action-0001","action_id":"candidate-action-0002","expected_version":1,"type":"pass"}`,
		`{"action_id":"candidate-action-0001","expected_version":1,"type":"play_card","card":{"suit":0,"rank":11,"rank":12}}`,
		`{"action_id":"candidate-action-0001","expected_version":1,"type":"play_card","card":{"suit":0,"rank":11,"secret":1}}`,
		`{"action_id":"candidate-action-0001","expected_version":1,"type":"pass","checkpoint":"hidden"}`,
		`{"action_id":null,"expected_version":1,"type":"pass"}`,
	} {
		req := httptest.NewRequest(http.MethodPost, path, bytes.NewBufferString(raw))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+h.tokens[0])
		rec := httptest.NewRecorder()
		h.h.ServeHTTP(rec, req)
		if rec.Code != http.StatusBadRequest {
			t.Fatalf("unexpected %d for malformed candidate action: %s", rec.Code, raw)
		}
	}
}

func TestCandidateFourAuthenticatedClientsFullEightDeals(t *testing.T) {
	h := candidateHarness(t)
	base := "/v1/tables/" + h.id + "/match"
	resp := h.response(0, http.MethodPost, base+"/start", map[string]any{})
	if resp.RulesStatus != "candidate_unapproved" || resp.View.Version != 1 {
		t.Fatal("candidate start incorrectly labeled approved or wrong version")
	}
	// Four independent bearer identities must receive distinct private hands
	// and no serialized internal deck/checkpoint/roster private state.
	for seat := range h.tokens {
		status, body := h.call(seat, http.MethodGet, base, nil)
		if status != 200 || bytes.Contains(body, []byte("initial_deck")) ||
			bytes.Contains(body, []byte("checkpoint")) ||
			bytes.Contains(body, []byte("journal")) {
			t.Fatalf("private match state leaked to seat %d: %s", seat, body)
		}
		var v service.CandidateResponse
		if err := json.Unmarshal(body, &v); err != nil || int(v.View.Seat) != seat ||
			len(v.View.Hand) != 13 {
			t.Fatalf("wrong private seat hand for player %d: %v", seat, err)
		}
	}
	countComplex, countTrix, countPass, countTricks := 0, 0, 0, 0
	num := 0
	for step := 0; step < 1200; step++ {
		current := h.response(0, http.MethodGet, base, nil)
		if current.View.Phase == trixcomplex.MatchComplete {
			if current.View.CompletedDeals != 8 || countComplex != 208 ||
				countTrix != 208 || countTricks != 52 || countPass == 0 {
				t.Fatalf("incomplete 8-deal game: deals=%d complex=%d trix=%d tricks=%d passes=%d",
					current.View.CompletedDeals, countComplex, countTrix, countTricks, countPass)
			}
			var score int
			for _, value := range current.View.Scores {
				score += value
			}
			if score != 0 {
				t.Fatalf("candidate non-doubling scores do not balance: %d", score)
			}
			for seat := range h.tokens {
				v := h.response(seat, http.MethodGet, base, nil)
				if v.View.Phase != trixcomplex.MatchComplete || v.View.Scores != current.View.Scores {
					t.Fatalf("seat %d final scores differ", seat)
				}
			}
			return
		}
		seat := int(current.View.Turn)
		if seat < 0 || seat > 3 {
			t.Fatal("invalid actor seat")
		}
		v := h.response(seat, http.MethodGet, base, nil)
		num++
		action := map[string]any{
			"action_id": fmt.Sprintf("candidate-complete-%016d", num),
			"expected_version": v.View.Version,
		}
		switch v.View.Phase {
		case trixcomplex.ContractSelection:
			action["type"] = trixcomplex.ChooseContract
			if v.View.CompletedDeals%2 == 0 {
				action["contract"] = trixcomplex.Complex
			} else {
				action["contract"] = trixcomplex.Trix
			}
		case trixcomplex.ComplexActive, trixcomplex.TrixActive:
			if len(v.LegalMoves.Cards) > 0 {
				action["type"] = trixcomplex.PlayCard
				action["card"] = v.LegalMoves.Cards[0]
				if v.View.Phase == trixcomplex.ComplexActive {
					countComplex++
				} else {
					countTrix++
				}
			} else if v.LegalMoves.CanPass {
				action["type"] = trixcomplex.Pass
				countPass++
			} else {
				t.Fatalf("active player %d has no legal action in %s", seat, v.View.Phase)
			}
		default:
			t.Fatalf("unexpected candidate phase %s", v.View.Phase)
		}
		played := h.response(seat, http.MethodPost, base+"/actions", action)
		if played.Result == nil {
			t.Fatal("candidate action has no server result")
		}
		for _, event := range played.Result.Events {
			if event.Type == "trick_won" {
				countTricks++
			}
		}
		// Test one rejected forged action without losing a legal state.
		if num == 1 {
			bad := map[string]any{"action_id": "candidate-forgery-0000001",
				"expected_version": played.View.Version, "type": trixcomplex.PlayCard,
				"card": map[string]any{"suit": 0, "rank": 99}}
			status, _ := h.call(1, http.MethodPost, base+"/actions", bad)
			if status != http.StatusBadRequest && status != http.StatusConflict {
				t.Fatalf("illegal card accepted: HTTP %d", status)
			}
		}
	}
	t.Fatal("eight-deal candidate game did not complete")
}

func TestCandidateRosterChangeAndOutsiderFailClosed(t *testing.T) {
	h := candidateHarness(t)
	base := "/v1/tables/" + h.id + "/match"
	h.response(0, http.MethodPost, base+"/start", map[string]any{})
	outsider, err := h.s.NewGuest()
	if err != nil {
		t.Fatal(err)
	}
	req := httptest.NewRequest(http.MethodGet, base, nil)
	req.Header.Set("Authorization", "Bearer "+outsider.Token)
	rec := httptest.NewRecorder()
	h.h.ServeHTTP(rec, req)
	if rec.Code != http.StatusNotFound {
		t.Fatalf("outsider should be denied: HTTP %d", rec.Code)
	}
	if _, err := h.s.Act(h.tokens[0], "leave", h.id, service.Command{
		ActionID: "candidate-owner-leave-00001",
		ExpectedVersion: h.version,
	}); err != nil {
		t.Fatal(err)
	}
	status, body := h.call(1, http.MethodGet, base, nil)
	if status != http.StatusConflict {
		t.Fatalf("changed room roster did not fail closed: HTTP %d %s", status, body)
	}
}
