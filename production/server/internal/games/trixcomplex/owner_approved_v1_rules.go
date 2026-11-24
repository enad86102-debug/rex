package trixcomplex

import (
	"slices"
	"sync"
	"time"

	"rex/production/server/internal/cards"
)

// OwnerApprovedV1 is a rules-policy boundary based on the 2026-11-23 owner
// decision report. It does NOT activate the public server or replace the
// 0.9.0 draft engine. Technical integration review remains mandatory.
const (
	OwnerApprovedV1Reference = "REX/TRIX-COMPLEX/2026-11-23-owner-rules"
	KingdomContractDeadline  = 15 * time.Second
	SimultaneousDoubleWindow = 10 * time.Second
	CardActionDeadline       = 15 * time.Second
	ReconnectGracePeriod     = 60 * time.Second
)

var rightwardSeatOrder = [4]SeatID{0, 1, 2, 3}

// RightwardNextSeat uses the approved bottom -> right -> top -> left
// orientation. The mobile UI must bind physical chair IDs to these seats.
func RightwardNextSeat(seat SeatID) (SeatID, error) {
	if seat >= 4 {
		return 0, ErrInvalidAction
	}
	return rightwardSeatOrder[(int(seat)+1)%len(rightwardSeatOrder)], nil
}

// TimedContractSelection implements the approved default on the 15s deadline.
// Both contracts may be selected once per kingdom, not twice.
func TimedContractSelection(available []ContractType, chosen ContractType, elapsed time.Duration) (ContractType, error) {
	if elapsed < 0 {
		return "", ErrInvalidAction
	}
	for _, c := range available {
		if c != Complex && c != Trix {
			return "", ErrInvalidRules
		}
	}
	if chosen != "" {
		if elapsed >= KingdomContractDeadline || !slices.Contains(available, chosen) {
			return "", ErrInvalidAction
		}
		return chosen, nil
	}
	if elapsed < KingdomContractDeadline {
		return "", ErrInvalidState // Owner still has time to select.
	}
	if slices.Contains(available, Complex) {
		return Complex, nil
	}
	if slices.Contains(available, Trix) {
		return Trix, nil
	}
	return "", ErrInvalidState
}

// DoubleMark represents a card explicitly announced by its current holder,
// revealed only after the simultaneous selection window closes.
type DoubleMark struct {
	Card  cards.Card `json:"card"`
	Owner SeatID     `json:"owner"`
}

// DoubleSelectionWindow is PRIVATE server state, never a player view.
// The owner can revise their selection before the deadline; no chosen card is
// exposed by the protocol until Reveal. This is rules logic, not a durable
// transport/session coordinator.
type DoubleSelectionWindow struct {
	mu         sync.Mutex
	start      time.Time
	deadline   time.Time
	owner      map[cards.Card]SeatID
	choices    [4]map[cards.Card]bool
	submitted  [4]bool
	revealed   bool
}

func isDoublable(card cards.Card) bool {
	return card == (cards.Card{Suit: cards.Hearts, Rank: 13}) || card.Rank == 12 && validCard(card)
}

func NewDoubleSelectionWindow(hands [4][]cards.Card, start time.Time) (*DoubleSelectionWindow, error) {
	if start.IsZero() {
		return nil, ErrInvalidState
	}
	w := &DoubleSelectionWindow{start: start, deadline: start.Add(SimultaneousDoubleWindow),
		owner: make(map[cards.Card]SeatID, 52)}
	for seat, hand := range hands {
		if len(hand) != 13 {
			return nil, ErrInvalidRules
		}
		for _, card := range hand {
			if !validCard(card) {
				return nil, ErrInvalidRules
			}
			if _, exists := w.owner[card]; exists {
				return nil, ErrInvalidRules
			}
			w.owner[card] = SeatID(seat)
		}
	}
	if len(w.owner) != 52 {
		return nil, ErrInvalidRules
	}
	return w, nil
}

// Submit is private and rejects any card a player does not hold. Submitting
// zero marks is an explicit pass. No public declaration is emitted here.
func (w *DoubleSelectionWindow) Submit(seat SeatID, selection []cards.Card, at time.Time) error {
	if w == nil {
		return ErrInvalidAction
	}
	w.mu.Lock()
	defer w.mu.Unlock()
	if w.revealed || seat >= 4 || at.Before(w.start) || !at.Before(w.deadline) {
		return ErrInvalidAction
	}
	choices := make(map[cards.Card]bool, len(selection))
	for _, card := range selection {
		holder, held := w.owner[card]
		if !held || holder != seat || !isDoublable(card) || choices[card] {
			return ErrInvalidAction
		}
		choices[card] = true
	}
	w.choices[seat] = choices
	w.submitted[seat] = true
	return nil
}

// SubmittedFlags expose no selected card, holder, or doubling count.
func (w *DoubleSelectionWindow) SubmittedFlags() ([4]bool, error) {
	if w == nil {
		return [4]bool{}, ErrInvalidState
	}
	w.mu.Lock()
	defer w.mu.Unlock()
	return w.submitted, nil
}

// Reveal is valid at or after the 10 second deadline, never before it.
// The server returns all declarations together, with deterministic ordering.
func (w *DoubleSelectionWindow) Reveal(at time.Time) ([]DoubleMark, error) {
	if w == nil {
		return nil, ErrInvalidState
	}
	w.mu.Lock()
	defer w.mu.Unlock()
	if at.Before(w.deadline) {
		return nil, ErrInvalidState
	}
	w.revealed = true
	out := make([]DoubleMark, 0, 5)
	for seat, choices := range w.choices {
		for card := range choices {
			out = append(out, DoubleMark{Card: card, Owner: SeatID(seat)})
		}
	}
	if len(out) > 5 {
		return nil, ErrInvalidState
	}
	slices.SortFunc(out, func(a, b DoubleMark) int {
		if a.Card.Suit != b.Card.Suit {
			return int(a.Card.Suit) - int(b.Card.Suit)
		}
		return int(a.Card.Rank) - int(b.Card.Rank)
	})
	return out, nil
}

// ComplexTrickAward separates the original trick debit, doubled debit and
// issuer bonus, so a UI can show every scoring reason without guesswork.
type ComplexTrickAward struct {
	Winner       SeatID `json:"winner"`
	BasePenalty  int    `json:"base_penalty"`
	DoubleExtra  int    `json:"double_extra"`
	OwnerBonus   [4]int `json:"owner_bonus"`
	Delta        [4]int `json:"delta"`
}

// ScoreApprovedComplexTrick uses the 2026-11-23 owner-approved scoring policy.
// Q♦ retains both its diamond and queen debits. Doubling adds ONE additional
// queen/K♥ base penalty; it does not multiply the whole trick or diamond tax.
func ScoreApprovedComplexTrick(plays []Play, marks []DoubleMark) (ComplexTrickAward, error) {
	winner, err := TrickWinner(plays)
	if err != nil {
		return ComplexTrickAward{}, err
	}
	penalty, err := TrickPenalty(plays)
	if err != nil {
		return ComplexTrickAward{}, err
	}
	result := ComplexTrickAward{Winner: winner, BasePenalty: penalty}
	seen := make(map[cards.Card]bool, len(marks))
	if len(marks) > 5 {
		return ComplexTrickAward{}, ErrInvalidAction
	}
	for _, mark := range marks {
		if !isDoublable(mark.Card) || mark.Owner >= 4 || seen[mark.Card] {
			return ComplexTrickAward{}, ErrInvalidAction
		}
		seen[mark.Card] = true
		for _, play := range plays {
			if play.Card != mark.Card {
				continue
			}
			if play.Seat != mark.Owner {
				return ComplexTrickAward{}, ErrInvalidAction
			}
			extra := 25
			if mark.Card == (cards.Card{Suit: cards.Hearts, Rank: 13}) {
				extra = 75
			}
			result.DoubleExtra -= extra
			if winner != mark.Owner {
				result.OwnerBonus[mark.Owner] += extra
			}
		}
	}
	result.Delta[winner] = penalty + result.DoubleExtra
	for seat, bonus := range result.OwnerBonus {
		result.Delta[seat] += bonus
	}
	return result, nil
}

// OwnerApprovedWinner applies the approved highest-score rule. A top-score tie
// goes to whoever finished earliest in the LAST Trix contract. Withdrawn
// players keep their recorded score but cannot be declared winners.
func OwnerApprovedWinner(scores [4]int, withdrawn [4]bool, lastTrixFinish []SeatID) (SeatID, error) {
	if len(lastTrixFinish) != 4 {
		return 0, ErrInvalidState
	}
	rank := [4]int{}
	seen := [4]bool{}
	for i, seat := range lastTrixFinish {
		if seat >= 4 || seen[seat] {
			return 0, ErrInvalidState
		}
		rank[seat], seen[seat] = i, true
	}
	found := false
	var winner SeatID
	for seat, score := range scores {
		if withdrawn[seat] {
			continue
		}
		if !found || score > scores[winner] ||
			score == scores[winner] && rank[seat] < rank[winner] {
			winner = SeatID(seat)
			found = true
		}
	}
	if !found {
		return 0, ErrInvalidState
	}
	return winner, nil
}
