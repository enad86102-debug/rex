//go:build rex_candidate

package service

import (
	"bytes"
	"encoding/json"
	"errors"
	"io"
	"os"
	"path/filepath"
	"regexp"

	"rex/production/server/internal/cards"
	"rex/production/server/internal/games/trixcomplex"
)

// CandidateCoordinator is an isolated single-process engineering adapter.
// Not a commercial database. It is never reachable through api.New or rexd.
type CandidateCoordinator struct {
	service *Service
	dir     string
}

type CandidateCommand struct {
	ActionID        string                   `json:"action_id"`
	ExpectedVersion uint64                   `json:"expected_version"`
	Type            trixcomplex.ActionType   `json:"type"`
	Contract        trixcomplex.ContractType `json:"contract,omitempty"`
	Card            cards.Card               `json:"card,omitempty"`
}

type CandidateResponse struct {
	View        trixcomplex.PlayerMatchView  `json:"view"`
	LegalMoves  trixcomplex.PlayerLegalMoves `json:"legal_moves"`
	Result      *trixcomplex.ActionResult    `json:"result,omitempty"`
	RulesStatus string                       `json:"rules_status"`
}

type candidateDisk struct {
	Schema       int             `json:"schema"`
	TableID      string          `json:"table_id"`
	TableVersion uint64          `json:"table_version"`
	Seats        [4]string       `json:"seats"`
	Checkpoint   json.RawMessage `json:"checkpoint"`
}

var candidateRoomID = regexp.MustCompile(`^[a-f0-9]{32}$`)

func NewCandidateCoordinator(s *Service, dir string) *CandidateCoordinator {
	return &CandidateCoordinator{service: s, dir: dir}
}

func candidateProfile() trixcomplex.CandidateProfile {
	return trixcomplex.CandidateProfile{
		GameID: trixcomplex.GameID, Version: trixcomplex.DraftVersion,
		Status: "PROPOSED", SeatOrder: [4]trixcomplex.SeatID{0, 1, 2, 3},
		OpeningLeaderPolicy: "owner", HeartsLeadPolicy: "unrestricted",
		PenaltyDiscardPolicy: "unrestricted", DoublingPolicy: "disabled_candidate",
		RedealPolicy: "none_candidate", TimeoutPolicy: "manual_candidate",
		ResignationPolicy: "disabled_candidate",
	}
}

func (c *CandidateCoordinator) path(id string) (string, error) {
	if c == nil || c.service == nil || c.dir == "" || !candidateRoomID.MatchString(id) {
		return "", ErrInput
	}
	return filepath.Join(c.dir, id+".private.json"), nil
}

// All candidate operations take Service.mu. A modified roster, ready state or
// logged-out identity fails closed before the checkpoint can be read or changed.
func (c *CandidateCoordinator) room(token, id string) (Table, string, error) {
	session, err := c.service.authenticate(token)
	if err != nil {
		return Table{}, "", err
	}
	t, ok := c.service.s.Tables[id]
	if !ok || member(t, session.PlayerID) < 0 {
		return Table{}, "", ErrNotFound
	}
	if t.Game != trixcomplex.GameID {
		return Table{}, "", ErrRules
	}
	return t, session.PlayerID, nil
}

func roster(t Table) ([4]string, error) {
	var members [4]string
	for i, seat := range t.Seats {
		if seat == nil || !seat.Ready || seat.PlayerID == "" {
			return members, ErrConflict
		}
		members[i] = seat.PlayerID
	}
	return members, nil
}

func candidateView(m *trixcomplex.Match, actor string, result *trixcomplex.ActionResult) (CandidateResponse, error) {
	v, err := m.View(actor)
	if err != nil {
		return CandidateResponse{}, ErrNotFound
	}
	moves, err := m.LegalMoves(actor)
	if err != nil {
		return CandidateResponse{}, ErrNotFound
	}
	return CandidateResponse{View: v, LegalMoves: moves, Result: result, RulesStatus: "candidate_unapproved"}, nil
}

func (c *CandidateCoordinator) load(id string, t Table) (*trixcomplex.Match, candidateDisk, error) {
	path, err := c.path(id)
	if err != nil {
		return nil, candidateDisk{}, err
	}
	stat, err := os.Stat(path)
	if err != nil {
		return nil, candidateDisk{}, err
	}
	if stat.Mode().Perm()&0077 != 0 || stat.Size() > 2<<20 {
		return nil, candidateDisk{}, ErrRules
	}
	// #nosec G304 -- validated table ID and server-controlled directory.
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, candidateDisk{}, err
	}
	d := json.NewDecoder(bytes.NewReader(data))
	d.DisallowUnknownFields()
	var disk candidateDisk
	if err := d.Decode(&disk); err != nil {
		return nil, candidateDisk{}, ErrRules
	}
	if err := d.Decode(new(any)); !errors.Is(err, io.EOF) {
		return nil, candidateDisk{}, ErrRules
	}
	members, err := roster(t)
	if err != nil || disk.Schema != 1 || disk.TableID != id ||
		disk.TableVersion != t.Version || disk.Seats != members {
		return nil, candidateDisk{}, ErrConflict
	}
	m, err := trixcomplex.RestoreCandidateMatch(disk.Checkpoint)
	if err != nil {
		return nil, candidateDisk{}, ErrRules
	}
	for seat, player := range members {
		view, err := m.View(player)
		if err != nil || int(view.Seat) != seat || string(view.MatchID) != id {
			return nil, candidateDisk{}, ErrRules
		}
	}
	return m, disk, nil
}

// save is a single-process test adapter: durable before acknowledgement,
// private mode 0600, temporary write, fsync, rename, directory fsync.
func (c *CandidateCoordinator) save(id string, disk candidateDisk) error {
	path, err := c.path(id)
	if err != nil {
		return err
	}
	if err := os.MkdirAll(c.dir, 0700); err != nil {
		return err
	}
	info, err := os.Stat(c.dir)
	if err != nil || !info.IsDir() || info.Mode().Perm()&0077 != 0 {
		return ErrRules
	}
	data, err := json.Marshal(disk)
	if err != nil {
		return err
	}
	f, err := os.CreateTemp(c.dir, ".candidate-*")
	if err != nil {
		return err
	}
	defer os.Remove(f.Name())
	if err := f.Chmod(0600); err != nil {
		f.Close()
		return err
	}
	if _, err := f.Write(data); err != nil {
		f.Close()
		return err
	}
	if err := f.Sync(); err != nil {
		f.Close()
		return err
	}
	if err := f.Close(); err != nil {
		return err
	}
	dir, err := os.Open(c.dir)
	if err != nil {
		return err
	}
	defer dir.Close()
	if err := os.Rename(f.Name(), path); err != nil {
		return err
	}
	return dir.Sync()
}

// Start requires four ready authenticated seats and the genuine room owner.
// A second identical request returns the same candidate view, not a new deal.
func (c *CandidateCoordinator) Start(token, id string) (CandidateResponse, error) {
	if _, err := c.path(id); err != nil {
		return CandidateResponse{}, err
	}
	c.service.mu.Lock()
	defer c.service.mu.Unlock()
	t, actor, err := c.room(token, id)
	if err != nil {
		return CandidateResponse{}, err
	}
	if t.OwnerID != actor {
		return CandidateResponse{}, ErrNotFound
	}
	members, err := roster(t)
	if err != nil {
		return CandidateResponse{}, err
	}
	old, _, err := c.load(id, t)
	if err == nil {
		return candidateView(old, actor, nil)
	}
	if !errors.Is(err, os.ErrNotExist) {
		return CandidateResponse{}, err
	}
	shuffled, err := cards.Shuffle(cards.Deck())
	if err != nil {
		return CandidateResponse{}, err
	}
	m, err := trixcomplex.NewCandidateMatch(trixcomplex.MatchID(id), candidateProfile(), members, shuffled)
	if err != nil {
		return CandidateResponse{}, ErrRules
	}
	checkpoint, err := m.PrivateCheckpoint()
	if err != nil {
		return CandidateResponse{}, ErrRules
	}
	disk := candidateDisk{Schema: 1, TableID: id, TableVersion: t.Version,
		Seats: members, Checkpoint: checkpoint}
	if err := c.save(id, disk); err != nil {
		return CandidateResponse{}, err
	}
	return candidateView(m, actor, nil)
}

func (c *CandidateCoordinator) View(token, id string) (CandidateResponse, error) {
	if _, err := c.path(id); err != nil {
		return CandidateResponse{}, err
	}
	c.service.mu.Lock()
	defer c.service.mu.Unlock()
	t, actor, err := c.room(token, id)
	if err != nil {
		return CandidateResponse{}, err
	}
	m, _, err := c.load(id, t)
	if err != nil {
		return CandidateResponse{}, err
	}
	return candidateView(m, actor, nil)
}

func (c *CandidateCoordinator) Apply(token, id string, cmd CandidateCommand) (CandidateResponse, error) {
	if _, err := c.path(id); err != nil {
		return CandidateResponse{}, err
	}
	c.service.mu.Lock()
	defer c.service.mu.Unlock()
	t, actor, err := c.room(token, id)
	if err != nil {
		return CandidateResponse{}, err
	}
	m, disk, err := c.load(id, t)
	if err != nil {
		return CandidateResponse{}, err
	}
	next, err := m.Clone()
	if err != nil {
		return CandidateResponse{}, ErrRules
	}
	action := trixcomplex.GameAction{
		MatchID: trixcomplex.MatchID(id), ActorID: actor,
		ActionID: cmd.ActionID, ExpectedVersion: cmd.ExpectedVersion,
		RulesVersion: trixcomplex.DraftVersion, Type: cmd.Type,
		Contract: cmd.Contract, Card: cmd.Card,
	}
	result, err := next.Apply(action)
	if err != nil {
		switch {
		case errors.Is(err, trixcomplex.ErrUnauthorized):
			return CandidateResponse{}, ErrAuth
		case errors.Is(err, trixcomplex.ErrVersionConflict),
			errors.Is(err, trixcomplex.ErrActionConflict),
			errors.Is(err, trixcomplex.ErrWrongTurn):
			return CandidateResponse{}, ErrConflict
		default:
			return CandidateResponse{}, ErrInput
		}
	}
	// A server-only deal transition occurs after settlement. Candidate rules
	// still remain impossible to activate from the public rexd binary.
	if nextView, err := next.View(actor); err == nil && nextView.Phase == trixcomplex.DealSettlement {
		shuffled, err := cards.Shuffle(cards.Deck())
		if err != nil {
			return CandidateResponse{}, err
		}
		if err := next.AdvanceDeal(shuffled); err != nil {
			return CandidateResponse{}, ErrRules
		}
	}
	checkpoint, err := next.PrivateCheckpoint()
	if err != nil {
		return CandidateResponse{}, ErrRules
	}
	disk.Checkpoint = checkpoint
	if err := c.save(id, disk); err != nil {
		return CandidateResponse{}, err
	}
	return candidateView(next, actor, &result)
}
