package trixcomplex

import (
	"math/rand"
	"testing"

	"rex/production/server/internal/cards"
)

// Independent expectations protect against an engine test agreeing with its
// own buggy LegalMoves implementation. Fixed seeds are QA only, never deals.
func TestPhase1IndependentComplexFollowSuitOracle(t *testing.T) {
	random := rand.New(rand.NewSource(20261123))
	deck := cards.Deck()
	for iteration := 0; iteration < 120; iteration++ {
		random.Shuffle(len(deck), func(i, j int) {
			deck[i], deck[j] = deck[j], deck[i]
		})
		hand := append([]cards.Card(nil), deck[:13]...)
		led := deck[13]
		trick := TrickState{Leader: 0, Plays: []Play{{Seat: 0, Card: led}}}
		for _, candidate := range cards.Deck() {
			held, followsLedSuit := false, false
			for _, card := range hand {
				if card == candidate {
					held = true
				}
				if card.Suit == led.Suit {
					followsLedSuit = true
				}
			}
			want := held && (candidate.Suit == led.Suit || !followsLedSuit)
			if got := complexLegal(hand, trick, candidate); got != want {
				t.Fatalf("seed iteration %d: led=%v card=%v got=%v want=%v", iteration, led, candidate, got, want)
			}
			if got := complexLegal(hand, TrickState{}, candidate); got != held {
				t.Fatalf("seed iteration %d: opening lead improperly restricted %v", iteration, candidate)
			}
		}
	}
}

func TestPhase1IndependentTrixSequenceOracle(t *testing.T) {
	random := rand.New(rand.NewSource(20261124))
	for iteration := 0; iteration < 120; iteration++ {
		var layout TrixLayout
		alreadyPlayed := map[cards.Card]bool{}
		for suit := cards.Clubs; suit <= cards.Spades; suit++ {
			if random.Intn(5) == 0 {
				continue // no jack has been laid in this suit
			}
			low := uint8(2 + random.Intn(10))
			high := uint8(11 + random.Intn(4))
			layout.Low[suit], layout.High[suit] = low, high
			for rank := low; rank <= high; rank++ {
				alreadyPlayed[cards.Card{Suit: suit, Rank: rank}] = true
			}
		}
		var remaining []cards.Card
		for _, card := range cards.Deck() {
			if !alreadyPlayed[card] {
				remaining = append(remaining, card)
			}
		}
		hand := append([]cards.Card(nil), remaining...)
		for _, candidate := range cards.Deck() {
			held := !alreadyPlayed[candidate]
			low, high := layout.Low[candidate.Suit], layout.High[candidate.Suit]
			want := false
			if held {
				if low == 0 {
					want = candidate.Rank == 11
				} else {
					want = int(candidate.Rank) == int(low)-1 ||
						int(candidate.Rank) == int(high)+1
				}
			}
			if got := TrixLegal(layout, hand, candidate); got != want {
				t.Fatalf("iteration %d: suit=%d, low=%d high=%d, card=%v got=%v want=%v",
					iteration, candidate.Suit, low, high, candidate, got, want)
			}
		}
		anyLegal := false
		for _, candidate := range hand {
			low, high := layout.Low[candidate.Suit], layout.High[candidate.Suit]
			if (low == 0 && candidate.Rank == 11) ||
				(low != 0 && (int(candidate.Rank) == int(low)-1 ||
					int(candidate.Rank) == int(high)+1)) {
				anyLegal = true
				break
			}
		}
		if got := TrixHasMove(layout, hand); got != anyLegal {
			t.Fatalf("iteration %d: pass availability mismatches independent oracle", iteration)
		}
	}
}

func TestPhase1InvalidCardBoundsCannotEnterDraftMatch(t *testing.T) {
	invalid := []cards.Card{
		{Suit: cards.Spades + 1, Rank: 11},
		{Suit: cards.Clubs, Rank: 1},
		{Suit: cards.Hearts, Rank: 15},
	}
	m := newTestMatch(t)
	chooseTest(t, m, Complex, 1)
	for i, card := range invalid {
		if validCard(card) {
			t.Fatalf("invalid card %d accepted by primitive validator", i)
		}
		if complexLegal(m.hands[m.turn], m.trick, card) {
			t.Fatal("illegal complex card advertised as legal")
		}
		if TrixLegal(TrixLayout{}, m.hands[m.turn], card) {
			t.Fatal("illegal trix card advertised as legal")
		}
		action := candidateAction(m, m.turn, PlayCard, 100+i)
		action.Card = card
		oldVersion := m.version
		if _, err := m.Apply(action); err == nil || m.version != oldVersion {
			t.Fatalf("invalid card %d changed the match state: err=%v", i, err)
		}
	}
}
