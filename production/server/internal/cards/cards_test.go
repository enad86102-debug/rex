package cards

import (
	"bytes"
	"testing"
)

func TestDeckShuffleDeal(t *testing.T) {
	deck := Deck()
	seen := map[Card]bool{}
	for _, c := range deck {
		if seen[c] || c.Rank < 2 || c.Rank > 14 || c.Suit > Spades {
			t.Fatal("invalid deck")
		}
		seen[c] = true
	}
	if len(seen) != 52 {
		t.Fatal("deck must contain 52 unique cards")
	}
	shuffled, err := Shuffle(deck)
	if err != nil {
		t.Fatal(err)
	}
	hands, err := Deal(shuffled, 4)
	if err != nil {
		t.Fatal(err)
	}
	for _, hand := range hands {
		if len(hand) != 13 {
			t.Fatal("invalid hand size")
		}
		for _, c := range hand {
			if !seen[c] {
				t.Fatal("duplicate or unknown card")
			}
			delete(seen, c)
		}
	}
	if len(seen) != 0 {
		t.Fatal("lost cards")
	}
	if deck[0] != (Card{Suit: Clubs, Rank: 2}) {
		t.Fatal("caller deck mutated")
	}
	// Hands must own distinct backing storage.
	before := hands[1][0]
	hands[0][0] = Card{}
	if hands[1][0] != before {
		t.Fatal("aliased hands")
	}
}

func TestEntropyFailureAndInvalidDeals(t *testing.T) {
	deck := Deck()
	result, err := shuffle(deck, bytes.NewReader(nil))
	if err == nil || result != nil {
		t.Fatal("must fail closed on missing entropy")
	}
	for _, seats := range []int{-1, 0, 3, 53} {
		if _, err := Deal(deck, seats); err == nil {
			t.Fatalf("accepted %d seats", seats)
		}
	}
}
