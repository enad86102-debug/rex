package matchcore

import (
	"bytes"
	"encoding/json"
	"testing"

	"rex/production/server/internal/cards"
)

func TestFourSeatViewsKeepOpponentHandsPrivate(t *testing.T) {
	deck := cards.Deck()
	deal, err := NewDeal(deck)
	if err != nil {
		t.Fatal(err)
	}
	deck[0] = cards.Card{}
	for seat := 0; seat < 4; seat++ {
		view, err := deal.View(seat)
		if err != nil || len(view.Hand) != 13 {
			t.Fatal("invalid seat view", err)
		}
		if view.Hand[0] == (cards.Card{}) {
			t.Fatal("deal aliases caller deck")
		}
		wire, err := json.Marshal(view)
		if err != nil {
			t.Fatal(err)
		}
		for other := 0; other < 4; other++ {
			if other == seat {
				if view.OpponentCounts[other] != 0 {
					t.Fatal("own hand counted as opponent")
				}
				continue
			}
			if view.OpponentCounts[other] != 13 {
				t.Fatal("wrong opponent count")
			}
			secretHand, _ := deal.HandCopy(other)
			for _, secret := range secretHand {
				encoded, _ := json.Marshal(secret)
				if bytes.Contains(wire, encoded) {
					t.Fatalf("seat %d received seat %d card %v", seat, other, secret)
				}
			}
		}
		view.Hand[0] = cards.Card{}
		copied, _ := deal.HandCopy(seat)
		if copied[0] == (cards.Card{}) {
			t.Fatal("view aliases authoritative hand")
		}
		copied[0] = cards.Card{}
		copiedAgain, _ := deal.HandCopy(seat)
		if copiedAgain[0] == (cards.Card{}) {
			t.Fatal("rules hand copy aliases authoritative hand")
		}
	}
}

func TestDealRejectsMalformedDeckAndSeat(t *testing.T) {
	valid := cards.Deck()
	cases := [][]cards.Card{
		nil,
		valid[:51],
		append([]cards.Card(nil), append(valid[:51], valid[0])...),
		append([]cards.Card{{Suit: cards.Spades + 1, Rank: 2}}, valid[1:]...),
		append([]cards.Card{{Suit: cards.Clubs, Rank: 1}}, valid[1:]...),
	}
	for _, candidate := range cases {
		if deal, err := NewDeal(candidate); err == nil || deal != nil {
			t.Fatal("accepted malformed deck")
		}
	}
	deal, _ := NewDeal(valid)
	for _, seat := range []int{-1, 4} {
		if _, err := deal.View(seat); err == nil {
			t.Fatal("accepted invalid view seat")
		}
		if _, err := deal.HandCopy(seat); err == nil {
			t.Fatal("accepted invalid hand seat")
		}
	}
	if _, err := (*Deal)(nil).View(0); err == nil {
		t.Fatal("nil deal accepted")
	}
}

func TestShuffleAndDealHasFullUniqueDeck(t *testing.T) {
	deal, err := ShuffleAndDeal()
	if err != nil {
		t.Fatal(err)
	}
	seen := map[cards.Card]bool{}
	for seat := 0; seat < 4; seat++ {
		hand, err := deal.HandCopy(seat)
		if err != nil || len(hand) != 13 {
			t.Fatal("invalid shuffled hand", err)
		}
		for _, card := range hand {
			if seen[card] {
				t.Fatal("duplicate card")
			}
			seen[card] = true
		}
	}
	if len(seen) != 52 {
		t.Fatal("lost card")
	}
}
