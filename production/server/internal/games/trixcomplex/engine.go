package trixcomplex

import (
	"crypto/sha256"
	"encoding/json"
	"reflect"
	"slices"

	"rex/production/server/internal/cards"
	"rex/production/server/internal/matchcore"
)

type receipt struct {
	fingerprint [32]byte
	result      ActionResult
}

// A structured key keeps actor and action boundaries unambiguous even when
// either identifier contains punctuation used by the transport layer.
type receiptKey struct {
	actorID  string
	actionID string
}

type journalEntry struct {
	action *GameAction
	deck   []cards.Card
}

// Match contains all secret cards and must never be serialized to a player.
// Its fields are private; View is the player-facing projection. No existing
// HTTP handler creates or exposes this candidate match.
type Match struct {
	id             MatchID
	profile        CandidateProfile
	members        [4]string
	initialDeck    []cards.Card
	journal        []journalEntry
	receipts       map[receiptKey]receipt
	version        uint64
	kingdom        Kingdom
	owner          SeatID
	used           [4][2]bool
	completedDeals uint8
	phase          Phase
	contract       ContractType
	turn           SeatID
	hands          [4][]cards.Card
	trick          TrickState
	tricksWon      uint8
	playedCount    uint8
	layout         TrixLayout
	finish         []SeatID
	scores         [4]int
	dealScore      int
	events         []GameEvent
}

func NewCandidateMatch(id MatchID, profile CandidateProfile, members [4]string, firstDeck []cards.Card) (*Match, error) {
	if id == "" || profile.Validate() != nil {
		return nil, ErrInvalidRules
	}
	seen := map[string]bool{}
	for _, member := range members {
		if member == "" || seen[member] {
			return nil, ErrInvalidAction
		}
		seen[member] = true
	}
	deal, err := matchcore.NewDeal(firstDeck)
	if err != nil {
		return nil, err
	}
	m := &Match{id: id, profile: profile, members: members,
		initialDeck: slices.Clone(firstDeck), receipts: make(map[receiptKey]receipt),
		version: 1, phase: ContractSelection}
	for seat := range m.hands {
		m.hands[seat], _ = deal.HandCopy(seat)
		if hasCard(m.hands[seat], cards.Card{Suit: cards.Hearts, Rank: 7}) {
			m.owner = SeatID(seat)
		}
	}
	m.turn = m.owner
	return m, nil
}

func (m *Match) seatFor(actor string) (SeatID, error) {
	for seat, member := range m.members {
		if member == actor {
			return SeatID(seat), nil
		}
	}
	return 0, ErrUnauthorized
}

func (m *Match) nextSeat(current SeatID, skipFinished bool) (SeatID, error) {
	for i, seat := range m.profile.SeatOrder {
		if seat == current {
			for offset := 1; offset <= 4; offset++ {
				candidate := m.profile.SeatOrder[(i+offset)%4]
				if !skipFinished || !slices.Contains(m.finish, candidate) {
					return candidate, nil
				}
			}
		}
	}
	return 0, ErrInvalidState
}

func cloneEvent(event GameEvent) GameEvent {
	if event.Card != nil {
		card := *event.Card
		event.Card = &card
	}
	if event.Winner != nil {
		winner := *event.Winner
		event.Winner = &winner
	}
	return event
}

func cloneResult(result ActionResult) ActionResult {
	copy := ActionResult{Version: result.Version, Events: make([]GameEvent, len(result.Events))}
	for i, event := range result.Events {
		copy.Events[i] = cloneEvent(event)
	}
	return copy
}

func copyAction(action GameAction) GameAction {
	if action.ClaimedSeat != nil {
		seat := *action.ClaimedSeat
		action.ClaimedSeat = &seat
	}
	return action
}

func (m *Match) Apply(action GameAction) (ActionResult, error) {
	if m == nil {
		return ActionResult{}, ErrInvalidState
	}
	seat, err := m.seatFor(action.ActorID)
	if err != nil {
		return ActionResult{}, err
	}
	if action.MatchID != m.id || action.RulesVersion != m.profile.Version ||
		len(action.ActionID) < 16 || len(action.ActionID) > 128 ||
		(action.ClaimedSeat != nil && *action.ClaimedSeat != seat) {
		return ActionResult{}, ErrInvalidAction
	}
	encoded, err := json.Marshal(action)
	if err != nil {
		return ActionResult{}, ErrInvalidAction
	}
	fingerprint := sha256.Sum256(encoded)
	key := receiptKey{actorID: action.ActorID, actionID: action.ActionID}
	if old, found := m.receipts[key]; found {
		if old.fingerprint != fingerprint {
			return ActionResult{}, ErrActionConflict
		}
		return cloneResult(old.result), nil
	}
	if action.ExpectedVersion != m.version {
		return ActionResult{}, ErrVersionConflict
	}
	var events []GameEvent
	switch action.Type {
	case ChooseContract:
		events, err = m.choose(seat, action)
	case PlayCard:
		events, err = m.play(seat, action)
	case Pass:
		events, err = m.pass(seat, action)
	case DeclareDouble:
		err = ErrUnsupported
	default:
		err = ErrInvalidAction
	}
	if err != nil {
		return ActionResult{}, err
	}
	m.version++
	result := ActionResult{Version: m.version, Events: events}
	m.receipts[key] = receipt{fingerprint: fingerprint, result: cloneResult(result)}
	copy := copyAction(action)
	m.journal = append(m.journal, journalEntry{action: &copy})
	for _, event := range events {
		m.events = append(m.events, cloneEvent(event))
	}
	return cloneResult(result), nil
}

func contractIndex(contract ContractType) int {
	if contract == Complex {
		return 0
	}
	if contract == Trix {
		return 1
	}
	return -1
}

func (m *Match) choose(seat SeatID, action GameAction) ([]GameEvent, error) {
	index := contractIndex(action.Contract)
	if m.phase != ContractSelection || seat != m.owner || index < 0 ||
		m.used[m.kingdom][index] || action.Card != (cards.Card{}) {
		return nil, ErrInvalidAction
	}
	m.contract = action.Contract
	m.turn = m.owner // Explicit candidate profile; no visual-seat inference.
	m.trick = TrickState{Leader: m.turn}
	m.tricksWon, m.playedCount, m.dealScore = 0, 0, 0
	m.layout = TrixLayout{}
	m.finish = nil
	if action.Contract == Complex {
		m.phase = ComplexActive
	} else {
		m.phase = TrixActive
	}
	return []GameEvent{{Type: "contract_selected", Seat: seat, Contract: action.Contract}}, nil
}

func (m *Match) play(seat SeatID, action GameAction) ([]GameEvent, error) {
	if seat != m.turn {
		return nil, ErrWrongTurn
	}
	if action.Contract != "" || !validCard(action.Card) {
		return nil, ErrInvalidAction
	}
	switch m.phase {
	case ComplexActive:
		return m.playComplex(seat, action.Card)
	case TrixActive:
		return m.playTrix(seat, action.Card)
	default:
		return nil, ErrInvalidState
	}
}

func (m *Match) playComplex(seat SeatID, card cards.Card) ([]GameEvent, error) {
	if !complexLegal(m.hands[seat], m.trick, card) {
		return nil, ErrIllegalCard
	}
	plays := append(slices.Clone(m.trick.Plays), Play{Seat: seat, Card: card})
	var winner SeatID
	var penalty int
	if len(plays) == 4 {
		var err error
		winner, err = TrickWinner(plays)
		if err != nil {
			return nil, err
		}
		penalty, err = TrickPenalty(plays)
		if err != nil {
			return nil, err
		}
	}
	m.hands[seat] = removeCard(m.hands[seat], card)
	m.playedCount++
	m.trick.Plays = plays
	events := []GameEvent{{Type: "card_played", Seat: seat, Card: &card}}
	if len(plays) < 4 {
		m.turn, _ = m.nextSeat(seat, false)
		return events, nil
	}
	m.scores[winner] += penalty
	m.dealScore += penalty
	m.tricksWon++
	events = append(events, GameEvent{Type: "trick_won", Seat: winner, Winner: &winner,
		ScoreDelta: scoreDelta(winner, penalty)})
	m.turn = winner
	m.trick = TrickState{Leader: winner}
	if m.tricksWon == 13 {
		if m.playedCount != 52 || m.dealScore != -500 {
			return nil, ErrInvalidState // unreachable with a validated deck.
		}
		events = append(events, m.settle()...)
	}
	return events, nil
}

func scoreDelta(seat SeatID, value int) [4]int {
	var delta [4]int
	delta[seat] = value
	return delta
}

func (m *Match) playTrix(seat SeatID, card cards.Card) ([]GameEvent, error) {
	if !TrixLegal(m.layout, m.hands[seat], card) {
		return nil, ErrIllegalCard
	}
	m.hands[seat] = removeCard(m.hands[seat], card)
	placeTrix(&m.layout, card)
	m.playedCount++
	events := []GameEvent{{Type: "card_placed", Seat: seat, Card: &card}}
	if len(m.hands[seat]) == 0 {
		m.finish = append(m.finish, seat)
		points := [...]int{200, 150, 100, 50}[len(m.finish)-1]
		m.scores[seat] += points
		m.dealScore += points
		events = append(events, GameEvent{Type: "hand_finished", Seat: seat,
			ScoreDelta: scoreDelta(seat, points)})
	}
	if len(m.finish) == 4 {
		if m.playedCount != 52 || m.dealScore != 500 {
			return nil, ErrInvalidState // unreachable with a validated deck.
		}
		events = append(events, m.settle()...)
	} else {
		m.turn, _ = m.nextSeat(seat, true)
	}
	return events, nil
}

func (m *Match) pass(seat SeatID, action GameAction) ([]GameEvent, error) {
	if m.phase != TrixActive || seat != m.turn || action.Contract != "" || action.Card != (cards.Card{}) {
		return nil, ErrInvalidAction
	}
	if TrixHasMove(m.layout, m.hands[seat]) {
		return nil, ErrPassForbidden
	}
	m.turn, _ = m.nextSeat(seat, true)
	return []GameEvent{{Type: "passed", Seat: seat}}, nil
}

func (m *Match) settle() []GameEvent {
	m.used[m.kingdom][contractIndex(m.contract)] = true
	m.completedDeals++
	events := []GameEvent{{Type: "deal_settled", Seat: m.owner, Contract: m.contract}}
	if m.used[m.kingdom][0] && m.used[m.kingdom][1] {
		events = append(events, GameEvent{Type: "kingdom_complete", Seat: m.owner})
	}
	if m.completedDeals == 8 {
		m.phase = MatchComplete
		events = append(events, GameEvent{Type: "match_complete", Seat: m.owner})
	} else {
		m.phase = DealSettlement
	}
	return events
}

// AdvanceDeal is a server-only transition. It does not choose a contract or
// create a public match. The next independent deck must be supplied by the
// future approved persistence/session coordinator.
func (m *Match) AdvanceDeal(nextDeck []cards.Card) error {
	if m == nil || m.phase != DealSettlement {
		return ErrInvalidState
	}
	deal, err := matchcore.NewDeal(nextDeck)
	if err != nil {
		return err
	}
	if m.used[m.kingdom][0] && m.used[m.kingdom][1] {
		if m.kingdom >= 3 {
			return ErrInvalidState
		}
		m.kingdom++
		m.owner, _ = m.nextSeat(m.owner, false)
	}
	for seat := range m.hands {
		m.hands[seat], _ = deal.HandCopy(seat)
	}
	m.phase = ContractSelection
	m.contract = ""
	m.turn = m.owner
	m.trick = TrickState{}
	m.tricksWon, m.playedCount, m.dealScore = 0, 0, 0
	m.layout = TrixLayout{}
	m.finish = nil
	m.version++
	m.journal = append(m.journal, journalEntry{deck: slices.Clone(nextDeck)})
	return nil
}

func (m *Match) View(actorID string) (PlayerMatchView, error) {
	if m == nil {
		return PlayerMatchView{}, ErrInvalidState
	}
	seat, err := m.seatFor(actorID)
	if err != nil {
		return PlayerMatchView{}, err
	}
	view := PlayerMatchView{MatchID: m.id, RulesVersion: m.profile.Version, Version: m.version,
		Seat: seat, Kingdom: m.kingdom, Owner: m.owner, Phase: m.phase, Contract: m.contract,
		Turn: m.turn, Hand: slices.Clone(m.hands[seat]), Scores: m.scores,
		CompletedDeals: m.completedDeals, Layout: m.layout, FinishOrder: slices.Clone(m.finish),
		Trick: TrickState{Leader: m.trick.Leader, Plays: slices.Clone(m.trick.Plays)}}
	for other := range m.hands {
		if other != int(seat) {
			view.OpponentCounts[other] = len(m.hands[other])
		}
	}
	return view, nil
}

// LegalMoves exposes only the named actor's current options. A future HTTP
// adapter MUST derive actorID from the authenticated bearer session, never
// from a client-supplied actor field or query parameter. The projection does
// not grant authority: Apply still validates the current server state.
func (m *Match) LegalMoves(actorID string) (PlayerLegalMoves, error) {
	if m == nil {
		return PlayerLegalMoves{}, ErrInvalidState
	}
	seat, err := m.seatFor(actorID)
	if err != nil {
		return PlayerLegalMoves{}, err
	}
	moves := PlayerLegalMoves{Version: m.version}
	if seat != m.turn {
		return moves, nil
	}
	switch m.phase {
	case ContractSelection:
		for _, contract := range []ContractType{Complex, Trix} {
			if !m.used[m.kingdom][contractIndex(contract)] {
				moves.Contracts = append(moves.Contracts, contract)
			}
		}
	case ComplexActive:
		for _, card := range m.hands[seat] {
			if complexLegal(m.hands[seat], m.trick, card) {
				moves.Cards = append(moves.Cards, card)
			}
		}
	case TrixActive:
		for _, card := range m.hands[seat] {
			if TrixLegal(m.layout, m.hands[seat], card) {
				moves.Cards = append(moves.Cards, card)
			}
		}
		moves.CanPass = len(moves.Cards) == 0
	}
	return moves, nil
}

func (m *Match) Result() (MatchResult, error) {
	if m == nil || m.phase != MatchComplete {
		return MatchResult{}, ErrInvalidState
	}
	return MatchResult{Scores: m.scores}, nil
}

// Replay independently applies the private in-memory journal. It verifies
// deterministic rules, not crash durability. No journal is yet persisted.
func (m *Match) Replay() (*Match, error) {
	if m == nil {
		return nil, ErrInvalidState
	}
	replayed, err := NewCandidateMatch(m.id, m.profile, m.members, m.initialDeck)
	if err != nil {
		return nil, err
	}
	for _, entry := range m.journal {
		if entry.action != nil {
			if _, err := replayed.Apply(*entry.action); err != nil {
				return nil, err
			}
		} else if err := replayed.AdvanceDeal(entry.deck); err != nil {
			return nil, err
		}
	}
	return replayed, nil
}

// VerifyReplay checks that the current private in-memory state matches a fresh
// deterministic execution of its journal. The journal is not durable or
// tamper-evident; persistence and signed audit records need separate review.
func (m *Match) VerifyReplay() error {
	replayed, err := m.Replay()
	if err != nil || !reflect.DeepEqual(m, replayed) {
		return ErrInvalidState
	}
	return nil
}

func (m *Match) PublicEvents() []GameEvent {
	if m == nil {
		return nil
	}
	out := make([]GameEvent, len(m.events))
	for i, event := range m.events {
		out[i] = cloneEvent(event)
	}
	return out
}

// A declaration policy is deliberately a type boundary rather than a guessed
// formula. The proposed contract has no approved eligibility/award algorithm.
type DoubleDeclaration struct {
	Seat     SeatID
	Card     cards.Card
	ActionID string
}

// DoublePolicy records decisions that must be supplied by an approved rules
// contract. Nil fields mean unresolved, not a zero-valued scoring choice.
type DoublePolicy struct {
	EligibleCards   []cards.Card
	MaxDeclarations *uint8
	Visibility      string
	DeadlinePhase   Phase
	AwardAllocation string
	SelfCapture     string
}

func ValidateDoubleDeclaration(_ CandidateProfile, _ DoublePolicy, _ DoubleDeclaration) error {
	return ErrUnsupported
}
