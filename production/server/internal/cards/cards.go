// Package cards supplies shared, rule-independent deck primitives.
// It does not specify or approve Trix Complex or Tarneeb rules.
package cards

import (
	"crypto/rand"
	"errors"
	"io"
	"math/big"
)

type Suit uint8

const (
	Clubs Suit = iota
	Diamonds
	Hearts
	Spades
)

type Card struct {
	Suit Suit  `json:"suit"`
	Rank uint8 `json:"rank"`
}

func Deck() []Card {
	deck := make([]Card, 0, 52)
	for suit := Clubs; suit <= Spades; suit++ {
		for rank := uint8(2); rank <= 14; rank++ {
			deck = append(deck, Card{Suit: suit, Rank: rank})
		}
	}
	return deck
}

// Shuffle uses rejection-sampled Fisher-Yates with the operating system CSPRNG.
// The caller receives no partly shuffled deck if the entropy source fails.
func Shuffle(deck []Card) ([]Card, error) { return shuffle(deck, rand.Reader) }

func shuffle(deck []Card, entropy io.Reader) ([]Card, error) {
	out := append([]Card(nil), deck...)
	for i := len(out) - 1; i > 0; i-- {
		n, err := rand.Int(entropy, big.NewInt(int64(i+1)))
		if err != nil {
			return nil, err
		}
		j := int(n.Int64())
		out[i], out[j] = out[j], out[i]
	}
	return out, nil
}

// Deal distributes round-robin from the first seat. Who starts and when to
// deal belong to each future approved rules contract, not this primitive.
func Deal(deck []Card, seats int) ([][]Card, error) {
	if seats < 1 || seats > len(deck) || len(deck)%seats != 0 {
		return nil, errors.New("invalid seat count")
	}
	hands := make([][]Card, seats)
	for i, card := range deck {
		hands[i%seats] = append(hands[i%seats], card)
	}
	return hands, nil
}
