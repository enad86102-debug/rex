package trixcomplex

import "rex/production/server/internal/cards"

func validCard(card cards.Card) bool {
	return card.Suit <= cards.Spades && card.Rank >= 2 && card.Rank <= 14
}

func hasCard(hand []cards.Card, card cards.Card) bool {
	for _, held := range hand {
		if held == card {
			return true
		}
	}
	return false
}

func removeCard(hand []cards.Card, card cards.Card) []cards.Card {
	out := make([]cards.Card, 0, len(hand)-1)
	for _, held := range hand {
		if held != card {
			out = append(out, held)
		}
	}
	return out
}

func complexLegal(hand []cards.Card, trick TrickState, card cards.Card) bool {
	if !validCard(card) || !hasCard(hand, card) {
		return false
	}
	if len(trick.Plays) == 0 || card.Suit == trick.Plays[0].Card.Suit {
		return true
	}
	for _, held := range hand {
		if held.Suit == trick.Plays[0].Card.Suit {
			return false
		}
	}
	return true
}

// TrickWinner has no trump: only cards of the led suit can win.
func TrickWinner(plays []Play) (SeatID, error) {
	if len(plays) != 4 {
		return 0, ErrInvalidAction
	}
	seenSeats := [4]bool{}
	seenCards := map[cards.Card]bool{}
	for _, play := range plays {
		if play.Seat > 3 || seenSeats[play.Seat] || !validCard(play.Card) || seenCards[play.Card] {
			return 0, ErrInvalidAction
		}
		seenSeats[play.Seat] = true
		seenCards[play.Card] = true
	}
	best := plays[0]
	for _, play := range plays[1:] {
		if play.Card.Suit == best.Card.Suit && play.Card.Rank > best.Card.Rank {
			best = play
		}
	}
	return best.Seat, nil
}

// TrickPenalty is a pure proposed, undoubled scoring function.
func TrickPenalty(plays []Play) (int, error) {
	if _, err := TrickWinner(plays); err != nil {
		return 0, err
	}
	penalty := -15
	for _, play := range plays {
		if play.Card.Suit == cards.Diamonds {
			penalty -= 10
		}
		if play.Card.Rank == 12 {
			penalty -= 25
		}
		if play.Card == (cards.Card{Suit: cards.Hearts, Rank: 13}) {
			penalty -= 75
		}
	}
	return penalty, nil
}
