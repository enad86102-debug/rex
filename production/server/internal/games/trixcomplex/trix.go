package trixcomplex

import "rex/production/server/internal/cards"

func TrixLegal(layout TrixLayout, hand []cards.Card, card cards.Card) bool {
	if !validCard(card) || !hasCard(hand, card) {
		return false
	}
	low, high := layout.Low[card.Suit], layout.High[card.Suit]
	if low == 0 {
		return card.Rank == 11
	}
	return (low > 2 && card.Rank == low-1) || (high < 14 && card.Rank == high+1)
}

func TrixHasMove(layout TrixLayout, hand []cards.Card) bool {
	for _, card := range hand {
		if TrixLegal(layout, hand, card) {
			return true
		}
	}
	return false
}

func placeTrix(layout *TrixLayout, card cards.Card) {
	if layout.Low[card.Suit] == 0 {
		layout.Low[card.Suit], layout.High[card.Suit] = 11, 11
	} else if card.Rank < layout.Low[card.Suit] {
		layout.Low[card.Suit] = card.Rank
	} else {
		layout.High[card.Suit] = card.Rank
	}
}
