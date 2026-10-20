package trixcomplex

import (
	"errors"
	"slices"
	"testing"

	"rex/production/server/internal/cards"
)

func TestLegalMovesAreSeatFilteredAndRevalidated(t *testing.T) {
	m := newTestMatch(t)
	owner := m.owner
	other := (owner + 1) % 4
	opening, err := m.LegalMoves(m.members[owner])
	if err != nil || !slices.Equal(opening.Contracts, []ContractType{Complex, Trix}) ||
		len(opening.Cards) != 0 || opening.CanPass || opening.Version != 1 {
		t.Fatalf("unexpected owner's contract options: %+v %v", opening, err)
	}
	waiting, err := m.LegalMoves(m.members[other])
	if err != nil || len(waiting.Contracts) != 0 || len(waiting.Cards) != 0 || waiting.CanPass {
		t.Fatalf("waiting player received options: %+v %v", waiting, err)
	}
	if _, err := m.LegalMoves("outsider"); !errors.Is(err, ErrUnauthorized) {
		t.Fatal("outsider received legal moves")
	}
	chooseTest(t, m, Complex, 1)
	lead, err := m.LegalMoves(m.members[owner])
	if err != nil || !slices.Equal(lead.Cards, m.hands[owner]) || lead.Version != m.version {
		t.Fatalf("owner did not receive own lead choices: %+v %v", lead, err)
	}
	// A move list is advisory; an invalid play is still rejected by Apply.
	bad := candidateAction(m, owner, PlayCard, 2)
	bad.Card = cards.Card{Suit: cards.Spades, Rank: 14}
	if slices.Contains(lead.Cards, bad.Card) {
		for _, card := range cards.Deck() {
			if !slices.Contains(lead.Cards, card) {
				bad.Card = card
				break
			}
		}
	}
	if _, err := m.Apply(bad); !errors.Is(err, ErrIllegalCard) {
		t.Fatalf("advisory projection bypassed authority: %v", err)
	}
}

func TestLegalMovesRespectsFollowSuitAndTrixPass(t *testing.T) {
	m := newTestMatch(t)
	owner := m.owner
	chooseTest(t, m, Complex, 1)
	first := candidateAction(m, m.turn, PlayCard, 2)
	first.Card = m.hands[m.turn][0]
	if _, err := m.Apply(first); err != nil {
		t.Fatal(err)
	}
	seat := m.turn
	moves, err := m.LegalMoves(m.members[seat])
	if err != nil || len(moves.Cards) == 0 {
		t.Fatalf("missing follower choices: %+v %v", moves, err)
	}
	for _, card := range moves.Cards {
		if !complexLegal(m.hands[seat], m.trick, card) {
			t.Fatal("illegal follower card advertised")
		}
		if !slices.Contains(m.hands[seat], card) || slices.Contains(m.hands[owner], card) {
			t.Fatal("legal move projection exposed a card from another hand")
		}
	}
	seq := 3
	playCompleteComplex(t, m, &seq)
	if err := m.AdvanceDeal(cards.Deck()); err != nil {
		t.Fatal(err)
	}
	contractMoves, err := m.LegalMoves(m.members[owner])
	if err != nil || !slices.Equal(contractMoves.Contracts, []ContractType{Trix}) {
		t.Fatalf("used contract offered again: %+v %v", contractMoves, err)
	}
	chooseTest(t, m, Trix, seq)
	for steps := 0; steps < 100; steps++ {
		seat = m.turn
		moves, err = m.LegalMoves(m.members[seat])
		if err != nil {
			t.Fatal(err)
		}
		if moves.CanPass {
			if len(moves.Cards) != 0 || TrixHasMove(m.layout, m.hands[seat]) {
				t.Fatal("pass offered despite legal play")
			}
			return
		}
		if len(moves.Cards) == 0 || !TrixLegal(m.layout, m.hands[seat], moves.Cards[0]) {
			t.Fatal("invalid Trix card options")
		}
		action := candidateAction(m, seat, PlayCard, seq+steps+1)
		action.Card = moves.Cards[0]
		if _, err := m.Apply(action); err != nil {
			t.Fatal(err)
		}
	}
	t.Fatal("no Trix pass reached in bounded deterministic run")
}
