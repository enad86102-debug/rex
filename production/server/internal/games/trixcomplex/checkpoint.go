package trixcomplex

import (
	"bytes"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/hex"
	"encoding/json"
	"io"
	"slices"

	"rex/production/server/internal/cards"
)

// This is private match material: decks, identities and action history. It is
// for a protected server-side store only, never a client response or audit log.
const maxPrivateCheckpointBytes = 1 << 20

type privateJournalEntry struct {
	Action *GameAction  `json:"action,omitempty"`
	Deck   []cards.Card `json:"deck,omitempty"`
}

type privateCheckpoint struct {
	Schema      int                   `json:"schema"`
	MatchID     MatchID               `json:"match_id"`
	Profile     CandidateProfile      `json:"profile"`
	Members     [4]string             `json:"members"`
	InitialDeck []cards.Card          `json:"initial_deck"`
	Journal     []privateJournalEntry `json:"journal"`
	Version     uint64                `json:"version"`
	Phase       Phase                 `json:"phase"`
	Scores      [4]int                `json:"scores"`
	Integrity   string                `json:"integrity"`
}

// Clone isolates a proposed state transition from the committed match. A
// failed persistence write can discard the clone without mutating the source.
func (m *Match) Clone() (*Match, error) {
	if m == nil {
		return nil, ErrInvalidState
	}
	copy := *m
	copy.initialDeck = slices.Clone(m.initialDeck)
	copy.journal = make([]journalEntry, len(m.journal))
	for i, entry := range m.journal {
		copy.journal[i].deck = slices.Clone(entry.deck)
		if entry.action != nil {
			action := copyAction(*entry.action)
			copy.journal[i].action = &action
		}
	}
	copy.receipts = make(map[receiptKey]receipt, len(m.receipts))
	for key, value := range m.receipts {
		copy.receipts[key] = receipt{fingerprint: value.fingerprint, result: cloneResult(value.result)}
	}
	for i := range copy.hands {
		copy.hands[i] = slices.Clone(m.hands[i])
	}
	copy.trick.Plays = slices.Clone(m.trick.Plays)
	copy.finish = slices.Clone(m.finish)
	copy.events = make([]GameEvent, len(m.events))
	for i, event := range m.events {
		copy.events[i] = cloneEvent(event)
	}
	return &copy, nil
}

// PrivateCheckpoint records the complete candidate history and a state
// consistency marker. The caller must commit these bytes atomically with the
// enclosing receipt and event record before acknowledging an action.
func (m *Match) PrivateCheckpoint() ([]byte, error) {
	if m == nil || m.VerifyReplay() != nil {
		return nil, ErrInvalidState
	}
	cp := privateCheckpoint{
		Schema: 1, MatchID: m.id, Profile: m.profile, Members: m.members,
		InitialDeck: slices.Clone(m.initialDeck),
		Journal:     make([]privateJournalEntry, len(m.journal)),
		Version:     m.version, Phase: m.phase, Scores: m.scores,
	}
	for i, entry := range m.journal {
		cp.Journal[i].Deck = slices.Clone(entry.deck)
		if entry.action != nil {
			action := copyAction(*entry.action)
			cp.Journal[i].Action = &action
		}
	}
	digest, err := checkpointDigest(cp)
	if err != nil {
		return nil, ErrInvalidState
	}
	cp.Integrity = digest
	encoded, err := json.Marshal(cp)
	if err != nil || len(encoded) > maxPrivateCheckpointBytes {
		return nil, ErrInvalidState
	}
	return encoded, nil
}

// RestoreCandidateMatch reconstructs private state by replaying every stored
// action and independently supplied deal. Malformed or inconsistent records
// are rejected rather than partially recovered.
func RestoreCandidateMatch(data []byte) (*Match, error) {
	if len(data) == 0 || len(data) > maxPrivateCheckpointBytes {
		return nil, ErrInvalidState
	}
	decoder := json.NewDecoder(bytes.NewReader(data))
	decoder.DisallowUnknownFields()
	var cp privateCheckpoint
	if err := decoder.Decode(&cp); err != nil {
		return nil, ErrInvalidState
	}
	if err := decoder.Decode(new(any)); err != io.EOF || cp.Schema != 1 {
		return nil, ErrInvalidState
	}
	storedIntegrity := cp.Integrity
	cp.Integrity = ""
	digest, err := checkpointDigest(cp)
	if err != nil || subtle.ConstantTimeCompare([]byte(storedIntegrity), []byte(digest)) != 1 {
		return nil, ErrInvalidState
	}
	m, err := NewCandidateMatch(cp.MatchID, cp.Profile, cp.Members, cp.InitialDeck)
	if err != nil {
		return nil, ErrInvalidState
	}
	for _, entry := range cp.Journal {
		if (entry.Action == nil) == (entry.Deck == nil) {
			return nil, ErrInvalidState
		}
		before := len(m.journal)
		if entry.Action != nil {
			if _, err := m.Apply(*entry.Action); err != nil {
				return nil, ErrInvalidState
			}
		} else if err := m.AdvanceDeal(entry.Deck); err != nil {
			return nil, ErrInvalidState
		}
		if len(m.journal) != before+1 {
			return nil, ErrInvalidState
		}
	}
	if m.version != cp.Version || m.phase != cp.Phase || m.scores != cp.Scores || m.VerifyReplay() != nil {
		return nil, ErrInvalidState
	}
	return m, nil
}

func checkpointDigest(cp privateCheckpoint) (string, error) {
	cp.Integrity = ""
	data, err := json.Marshal(cp)
	if err != nil {
		return "", err
	}
	digest := sha256.Sum256(data)
	return hex.EncodeToString(digest[:]), nil
}
