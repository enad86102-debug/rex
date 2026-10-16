package trixcomplex

import (
	"bytes"
	"encoding/json"
	"errors"
	"reflect"
	"testing"

	"rex/production/server/internal/cards"
)

var testMembers = [4]string{"member-north", "member-east", "member-south", "member-west"}

func testProfile() CandidateProfile {
	return CandidateProfile{GameID: GameID, Version: DraftVersion, Status: "PROPOSED",
		SeatOrder: [4]SeatID{0, 1, 2, 3}, OpeningLeaderPolicy: "owner",
		HeartsLeadPolicy: "unrestricted", PenaltyDiscardPolicy: "unrestricted",
		DoublingPolicy: "disabled_candidate", RedealPolicy: "none_candidate",
		TimeoutPolicy: "manual_candidate", ResignationPolicy: "disabled_candidate"}
}

func newTestMatch(t *testing.T) *Match {
	t.Helper()
	m, err := NewCandidateMatch("candidate-match-0001", testProfile(), testMembers, cards.Deck())
	if err != nil {
		t.Fatal(err)
	}
	return m
}

func candidateAction(m *Match, seat SeatID, kind ActionType, number int) GameAction {
	return GameAction{MatchID: m.id, ActorID: m.members[seat], ActionID: "candidate-action-" +
		stringID(number), ExpectedVersion: m.version, RulesVersion: m.profile.Version, Type: kind}
}

func stringID(number int) string {
	const digits = "0123456789"
	if number == 0 {
		return "0"
	}
	var out []byte
	for number > 0 {
		out = append([]byte{digits[number%10]}, out...)
		number /= 10
	}
	return string(out)
}

func chooseTest(t *testing.T, m *Match, contract ContractType, number int) {
	t.Helper()
	action := candidateAction(m, m.owner, ChooseContract, number)
	action.Contract = contract
	if _, err := m.Apply(action); err != nil {
		t.Fatal(err)
	}
}

func playCompleteComplex(t *testing.T, m *Match, sequence *int) {
	t.Helper()
	for m.phase == ComplexActive {
		seat := m.turn
		var selected cards.Card
		found := false
		for _, card := range m.hands[seat] {
			if complexLegal(m.hands[seat], m.trick, card) {
				selected, found = card, true
				break
			}
		}
		if !found {
			t.Fatal("no legal complex card")
		}
		action := candidateAction(m, seat, PlayCard, *sequence)
		*sequence++
		action.Card = selected
		if _, err := m.Apply(action); err != nil {
			t.Fatal(err)
		}
	}
	if m.tricksWon != 13 || m.playedCount != 52 || m.dealScore != -500 {
		t.Fatalf("invalid complex settlement: %d tricks, %d cards, %d score",
			m.tricksWon, m.playedCount, m.dealScore)
	}
}

func playCompleteTrix(t *testing.T, m *Match, sequence *int) {
	t.Helper()
	steps := 0
	for m.phase == TrixActive {
		steps++
		if steps > 500 {
			t.Fatal("trix sequence did not settle")
		}
		seat := m.turn
		action := candidateAction(m, seat, Pass, *sequence)
		*sequence++
		for _, card := range m.hands[seat] {
			if TrixLegal(m.layout, m.hands[seat], card) {
				action.Type, action.Card = PlayCard, card
				break
			}
		}
		if _, err := m.Apply(action); err != nil {
			t.Fatal(err)
		}
	}
	if len(m.finish) != 4 || m.playedCount != 52 || m.dealScore != 500 {
		t.Fatalf("invalid trix settlement: %d finishers, %d cards, %d score",
			len(m.finish), m.playedCount, m.dealScore)
	}
}

func TestFullCandidateEightDealMatchAndReplay(t *testing.T) {
	m := newTestMatch(t)
	if m.owner != 3 || m.kingdom != 0 || m.phase != ContractSelection {
		t.Fatal("seven of hearts did not select initial kingdom owner")
	}
	seq := 1
	for deal := 0; deal < 8; deal++ {
		if deal > 0 {
			if err := m.AdvanceDeal(cards.Deck()); err != nil {
				t.Fatal(err)
			}
		}
		if m.owner != SeatID((3+deal/2)%4) || m.kingdom != Kingdom(deal/2) {
			t.Fatal("kingdom owner rotation is inconsistent")
		}
		contract := Complex
		if deal%2 == 1 {
			contract = Trix
		}
		chooseTest(t, m, contract, seq)
		seq++
		if contract == Complex {
			playCompleteComplex(t, m, &seq)
		} else {
			playCompleteTrix(t, m, &seq)
		}
		if m.completedDeals != uint8(deal+1) {
			t.Fatal("deal counted twice or not counted")
		}
	}
	if m.phase != MatchComplete {
		t.Fatal("eight deals did not complete match")
	}
	result, err := m.Result()
	if err != nil {
		t.Fatal(err)
	}
	total := 0
	for _, score := range result.Scores {
		total += score
	}
	if total != 0 {
		t.Fatal("four complex and four trix deals should balance to zero")
	}
	if err := m.AdvanceDeal(cards.Deck()); !errors.Is(err, ErrInvalidState) {
		t.Fatal("finished match resumed")
	}
	replayed, err := m.Replay()
	if err != nil || !reflect.DeepEqual(m, replayed) {
		t.Fatal("deterministic in-memory replay differs", err)
	}
}

func TestComplexScoringAndNoTrump(t *testing.T) {
	plays := []Play{
		{0, cards.Card{Suit: cards.Clubs, Rank: 2}},
		{1, cards.Card{Suit: cards.Diamonds, Rank: 12}},
		{2, cards.Card{Suit: cards.Hearts, Rank: 13}},
		{3, cards.Card{Suit: cards.Clubs, Rank: 10}},
	}
	winner, err := TrickWinner(plays)
	if err != nil || winner != 3 {
		t.Fatal("off-suit high cards incorrectly won")
	}
	penalty, err := TrickPenalty(plays)
	if err != nil || penalty != -125 {
		t.Fatalf("Q diamonds and K hearts combination: %d %v", penalty, err)
	}
	if _, err := TrickPenalty(plays[:3]); err == nil {
		t.Fatal("accepted incomplete trick")
	}
	plays[3] = plays[0]
	if _, err := TrickWinner(plays); err == nil {
		t.Fatal("accepted duplicate card and seat")
	}
}

func TestComplexFollowSuitAndRejectedActionsAreAtomic(t *testing.T) {
	m := newTestMatch(t)
	chooseTest(t, m, Complex, 1)
	leader := m.turn
	led := m.hands[leader][0]
	action := candidateAction(m, leader, PlayCard, 2)
	action.Card = led
	if _, err := m.Apply(action); err != nil {
		t.Fatal(err)
	}
	follower := m.turn
	var off cards.Card
	var foundOff, foundLed bool
	for _, card := range m.hands[follower] {
		if card.Suit == led.Suit {
			foundLed = true
		} else {
			off, foundOff = card, true
		}
	}
	if !foundLed || !foundOff {
		t.Skip("deterministic hand lacks both suit choices")
	}
	before, _ := m.Replay()
	bad := candidateAction(m, follower, PlayCard, 3)
	bad.Card = off
	if _, err := m.Apply(bad); !errors.Is(err, ErrIllegalCard) || !reflect.DeepEqual(m, before) {
		t.Fatal("off-suit play changed state or was accepted")
	}
	bad.Card = cards.Card{Suit: cards.Spades, Rank: 14}
	bad.ActorID = m.members[leader]
	if _, err := m.Apply(bad); !errors.Is(err, ErrWrongTurn) {
		t.Fatal("out-of-turn actor accepted")
	}
}

func TestTrixSequencePassAndIdempotency(t *testing.T) {
	layout := TrixLayout{}
	hand := []cards.Card{{Suit: cards.Clubs, Rank: 11}, {Suit: cards.Clubs, Rank: 12},
		{Suit: cards.Clubs, Rank: 9}, {Suit: cards.Hearts, Rank: 11}}
	if !TrixLegal(layout, hand, hand[0]) || !TrixLegal(layout, hand, hand[3]) || TrixLegal(layout, hand, hand[1]) {
		t.Fatal("jack opening or queen pre-opening wrong")
	}
	placeTrix(&layout, hand[0])
	if !TrixLegal(layout, hand, hand[1]) || TrixLegal(layout, hand, hand[2]) {
		t.Fatal("trix skipped edge")
	}
	m := newTestMatch(t)
	chooseTest(t, m, Trix, 1)
	seat := m.turn
	if TrixHasMove(m.layout, m.hands[seat]) {
		pass := candidateAction(m, seat, Pass, 2)
		if _, err := m.Apply(pass); !errors.Is(err, ErrPassForbidden) {
			t.Fatal("passed despite legal jack")
		}
	}
	for !TrixHasMove(m.layout, m.hands[m.turn]) {
		pass := candidateAction(m, m.turn, Pass, int(m.version)+100)
		if _, err := m.Apply(pass); err != nil {
			t.Fatal(err)
		}
	}
	seat = m.turn
	var jack cards.Card
	for _, card := range m.hands[seat] {
		if TrixLegal(m.layout, m.hands[seat], card) {
			jack = card
			break
		}
	}
	action := candidateAction(m, seat, PlayCard, 200)
	action.Card = jack
	first, err := m.Apply(action)
	if err != nil {
		t.Fatal(err)
	}
	retry, err := m.Apply(action)
	if err != nil || !reflect.DeepEqual(first, retry) || m.playedCount != 1 {
		t.Fatal("duplicate played a second card")
	}
	action.Card = cards.Card{Suit: cards.Spades, Rank: 14}
	if _, err := m.Apply(action); !errors.Is(err, ErrActionConflict) {
		t.Fatal("changed payload reused action ID")
	}
}

func TestViewsAndApprovalGate(t *testing.T) {
	m := newTestMatch(t)
	if !errors.Is(m.profile.PublicActivation(), ErrUnapproved) {
		t.Fatal("draft activation allowed")
	}
	for seat, member := range m.members {
		view, err := m.View(member)
		if err != nil || len(view.Hand) != 13 {
			t.Fatal("invalid private view", err)
		}
		wire, err := json.Marshal(view)
		if err != nil {
			t.Fatal(err)
		}
		for other := range m.hands {
			if other == seat {
				continue
			}
			if view.OpponentCounts[other] != 13 {
				t.Fatal("wrong count")
			}
			for _, hidden := range m.hands[other] {
				encoded, _ := json.Marshal(hidden)
				if bytes.Contains(wire, encoded) {
					t.Fatalf("seat %d received opponent card %v", seat, hidden)
				}
			}
		}
		view.Hand[0] = cards.Card{}
		if m.hands[seat][0] == (cards.Card{}) {
			t.Fatal("view mutated authoritative hand")
		}
	}
	if _, err := m.View("outsider"); !errors.Is(err, ErrUnauthorized) {
		t.Fatal("nonmember saw match")
	}
	matchType := reflect.TypeOf(*m)
	for i := 0; i < matchType.NumField(); i++ {
		if matchType.Field(i).IsExported() {
			t.Fatal("internal match exposes serializable fields")
		}
	}
	wrongSeat := SeatID(1)
	if m.owner == 1 {
		wrongSeat = 0
	}
	action := candidateAction(m, m.owner, ChooseContract, 1)
	action.ClaimedSeat = &wrongSeat
	action.Contract = Complex
	if _, err := m.Apply(action); !errors.Is(err, ErrInvalidAction) {
		t.Fatal("forged seat accepted")
	}
}
