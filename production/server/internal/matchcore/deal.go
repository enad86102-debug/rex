// Package matchcore holds rule-independent, server-only four-seat card state.
// A deal is not a playable match: turn order, legal moves, scoring and match
// completion require an approved, versioned game contract.
package matchcore

import (
	"errors"

	"rex/production/server/internal/cards"
)

var ErrInvalidDeal = errors.New("invalid four-seat deal")

type Deal struct {
	hands [4][]cards.Card
}

// NewDeal accepts a previously shuffled server-side deck. It validates the
// complete canonical deck before allocating hands and never retains the input.
func NewDeal(deck []cards.Card) (*Deal, error) {
	if len(deck) != 52 {
		return nil, ErrInvalidDeal
	}
	seen := [4][15]bool{}
	for _, card := range deck {
		if card.Suit > cards.Spades || card.Rank < 2 || card.Rank > 14 || seen[card.Suit][card.Rank] {
			return nil, ErrInvalidDeal
		}
		seen[card.Suit][card.Rank] = true
	}
	hands, err := cards.Deal(deck, 4)
	if err != nil {
		return nil, ErrInvalidDeal
	}
	deal := &Deal{}
	for seat := range deal.hands {
		deal.hands[seat] = hands[seat]
	}
	return deal, nil
}

// ShuffleAndDeal uses the server's cryptographic random source. No result is
// returned on entropy failure.
func ShuffleAndDeal() (*Deal, error) {
	deck, err := cards.Shuffle(cards.Deck())
	if err != nil {
		return nil, err
	}
	return NewDeal(deck)
}

// SeatView is the only serializable representation intended for a player.
// Opponent hands are represented only by their counts.
type SeatView struct {
	Seat           int          `json:"seat"`
	Hand           []cards.Card `json:"hand"`
	OpponentCounts [4]int       `json:"opponent_counts"`
}

func (d *Deal) View(seat int) (SeatView, error) {
	if d == nil || seat < 0 || seat >= len(d.hands) {
		return SeatView{}, ErrInvalidDeal
	}
	view := SeatView{Seat: seat, Hand: append([]cards.Card(nil), d.hands[seat]...)}
	for other := range d.hands {
		if other != seat {
			view.OpponentCounts[other] = len(d.hands[other])
		}
	}
	return view, nil
}

// HandCopy is for a future server-side rules module. It cannot mutate the
// deal and must never be serialized into a response for another seat.
func (d *Deal) HandCopy(seat int) ([]cards.Card, error) {
	if d == nil || seat < 0 || seat >= len(d.hands) {
		return nil, ErrInvalidDeal
	}
	return append([]cards.Card(nil), d.hands[seat]...), nil
}
