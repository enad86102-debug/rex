package trixcomplex

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"math/rand"
	"reflect"
	"testing"

	"rex/production/server/internal/cards"
)

// These deterministic pseudo-random decks are testing fixtures ONLY. Production
// deals must continue to use cards.Shuffle and cryptographic randomness.
func deterministicTestDeck(random *rand.Rand) []cards.Card {
	deck := cards.Deck()
	random.Shuffle(len(deck), func(i, j int) {
		deck[i], deck[j] = deck[j], deck[i]
	})
	return deck
}

func TestPhase1CompleteEightDealMatrix(t *testing.T) {
	// Vary the deck for every deal, the initial owner, each contract's order,
	// and every legal card selection. This verifies the PROPOSED profile only.
	for seed := int64(1); seed <= 12; seed++ {
		t.Run(fmt.Sprintf("draft-seed-%02d", seed), func(t *testing.T) {
			random := rand.New(rand.NewSource(seed))
			m, err := NewCandidateMatch(
				MatchID(fmt.Sprintf("phase1-draft-%02d", seed)),
				testProfile(), testMembers, deterministicTestDeck(random),
			)
			if err != nil {
				t.Fatal(err)
			}
			nextAction := 1
			for dealNumber := 0; dealNumber < 8; dealNumber++ {
				if dealNumber != 0 {
					if err := m.AdvanceDeal(deterministicTestDeck(random)); err != nil {
						t.Fatal("advance rejected valid deck", err)
					}
				}
				if m.phase != ContractSelection || int(m.kingdom) != dealNumber/2 {
					t.Fatalf("incorrect kingdom/phase at deal %d: kingdom=%d phase=%s", dealNumber, m.kingdom, m.phase)
				}

				eventStart := len(m.events)
				assertCandidateDeckConservation(t, m, eventStart)
				// Exercise both possible orders of Complex and Trix contracts.
				contract := Complex
				if (dealNumber+int(seed))%2 == 1 {
					contract = Trix
				}
				chooseTest(t, m, contract, nextAction)
				nextAction++
				steps := 0
				for m.phase == ComplexActive || m.phase == TrixActive {
					steps++
					if steps > 650 {
						t.Fatalf("candidate deal %d did not settle in bounded turns", dealNumber)
					}
					seat := m.turn
					legal, err := m.LegalMoves(m.members[seat])
					if err != nil || legal.Version != m.version {
						t.Fatalf("legal move projection unavailable: %+v %v", legal, err)
					}
					action := candidateAction(m, seat, PlayCard, nextAction)
					nextAction++
					if len(legal.Cards) != 0 {
						action.Card = legal.Cards[random.Intn(len(legal.Cards))]
						if legal.CanPass {
							t.Fatal("advertised both legal cards and a mandatory pass")
						}
					} else {
						if m.phase != TrixActive || !legal.CanPass {
							t.Fatalf("no legal card or pass for seat=%d phase=%s", seat, m.phase)
						}
						action.Type = Pass
					}
					beforeVersion := m.version
					result, err := m.Apply(action)
					if err != nil {
						t.Fatalf("rejected advertised legal move in deal %d step %d: %v", dealNumber, steps, err)
					}
					if m.version != beforeVersion+1 || result.Version != m.version {
						t.Fatal("authoritative version did not advance exactly once")
					}
					assertCandidateDeckConservation(t, m, eventStart)
					if steps%13 == 0 {
						assertPhase1PrivateViews(t, m)
					}
					// A retried command must be no-op even after the turn changes.
					if steps%19 == 0 {
						before, err := m.Clone()
						if err != nil {
							t.Fatal(err)
						}
						repeated, err := m.Apply(action)
						if err != nil || !reflect.DeepEqual(result, repeated) || !reflect.DeepEqual(before, m) {
							t.Fatal("duplicate action altered candidate match", err)
						}
					}
				}
				if m.completedDeals != uint8(dealNumber+1) {
					t.Fatalf("candidate deal %d settled incorrectly: %d", dealNumber, m.completedDeals)
				}
				if m.phase != DealSettlement && m.phase != MatchComplete {
					t.Fatalf("candidate deal ended in invalid phase: %s", m.phase)
				}
			}
			if m.phase != MatchComplete {
				t.Fatal("draft candidate did not finish its eighth deal")
			}
			result, err := m.Result()
			if err != nil {
				t.Fatal(err)
			}
			sum := 0
			for _, score := range result.Scores {
				sum += score
			}
			if sum != 0 {
				t.Fatalf("4 Complex and 4 Trix candidate deals must net zero, got %d", sum)
			}
			var eventScores [4]int
			for _, event := range m.PublicEvents() {
				for seat, delta := range event.ScoreDelta {
					eventScores[seat] += delta
				}
			}
			if eventScores != result.Scores {
				t.Fatalf("draft event ledger %v differs from final result %v", eventScores, result.Scores)
			}
			trickWins, placements, dealt, kingdoms, completed := 0, 0, 0, 0, 0
			for _, event := range m.PublicEvents() {
				switch event.Type {
				case "trick_won":
					trickWins++
				case "hand_finished":
					placements++
				case "deal_settled":
					dealt++
				case "kingdom_complete":
					kingdoms++
				case "match_complete":
					completed++
				}
			}
			if trickWins != 52 || placements != 16 || dealt != 8 || kingdoms != 4 || completed != 1 {
				t.Fatalf("draft event conservation failed: trick=%d placements=%d deals=%d kingdoms=%d match=%d", trickWins, placements, dealt, kingdoms, completed)
			}
			if err := m.VerifyReplay(); err != nil {
				t.Fatal("draft in-memory replay mismatch", err)
			}
			checkpoint, err := m.PrivateCheckpoint()
			if err != nil {
				t.Fatal("private checkpoint failed", err)
			}
			restored, err := RestoreCandidateMatch(checkpoint)
			if err != nil || !reflect.DeepEqual(restored, m) {
				t.Fatal("restored full draft match differs from original", err)
			}
			if !errors.Is(m.profile.PublicActivation(), ErrUnapproved) {
				t.Fatal("test success must not activate unapproved rules")
			}
		})
	}
}

func TestPhase1GoldenUndoubledComplexTricks(t *testing.T) {
	// All expected scores come from the written 0.9.0-draft only.
	cases := []struct {
		name    string
		plays   [4]Play
		winner  SeatID
		penalty int
	}{
		{
			name: "four clubs no penalty cards",
			plays: [4]Play{
				{Seat: 0, Card: cards.Card{Suit: cards.Clubs, Rank: 2}},
				{Seat: 1, Card: cards.Card{Suit: cards.Clubs, Rank: 3}},
				{Seat: 2, Card: cards.Card{Suit: cards.Clubs, Rank: 4}},
				{Seat: 3, Card: cards.Card{Suit: cards.Clubs, Rank: 5}},
			},
			winner: 3, penalty: -15,
		},
		{
			name: "diamond queen scores diamond and queen plus king hearts",
			plays: [4]Play{
				{Seat: 0, Card: cards.Card{Suit: cards.Diamonds, Rank: 2}},
				{Seat: 1, Card: cards.Card{Suit: cards.Diamonds, Rank: 12}},
				{Seat: 2, Card: cards.Card{Suit: cards.Hearts, Rank: 13}},
				{Seat: 3, Card: cards.Card{Suit: cards.Spades, Rank: 14}},
			},
			winner: 1, penalty: -135,
		},
		{
			name: "four diamonds and mandatory trick penalty",
			plays: [4]Play{
				{Seat: 0, Card: cards.Card{Suit: cards.Diamonds, Rank: 2}},
				{Seat: 1, Card: cards.Card{Suit: cards.Diamonds, Rank: 3}},
				{Seat: 2, Card: cards.Card{Suit: cards.Diamonds, Rank: 4}},
				{Seat: 3, Card: cards.Card{Suit: cards.Diamonds, Rank: 5}},
			},
			winner: 3, penalty: -55,
		},
		{
			name: "no trump when off suit contains ace",
			plays: [4]Play{
				{Seat: 0, Card: cards.Card{Suit: cards.Clubs, Rank: 9}},
				{Seat: 1, Card: cards.Card{Suit: cards.Spades, Rank: 14}},
				{Seat: 2, Card: cards.Card{Suit: cards.Clubs, Rank: 7}},
				{Seat: 3, Card: cards.Card{Suit: cards.Diamonds, Rank: 3}},
			},
			winner: 0, penalty: -25,
		},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			plays := tc.plays[:]
			winner, err := TrickWinner(plays)
			if err != nil || winner != tc.winner {
				t.Fatalf("winner: got=%d want=%d err=%v", winner, tc.winner, err)
			}
			penalty, err := TrickPenalty(plays)
			if err != nil || penalty != tc.penalty {
				t.Fatalf("penalty: got=%d want=%d err=%v", penalty, tc.penalty, err)
			}
		})
	}
}

func TestPhase1SeatRotationUsesExplicitProfileNotScreenPosition(t *testing.T) {
	profile := testProfile()
	// This reverse-order profile is a QA permutation, not a rules decision.
	profile.SeatOrder = [4]SeatID{0, 3, 2, 1}
	m, err := NewCandidateMatch("draft-reverse-seat-order", profile, testMembers, cards.Deck())
	if err != nil {
		t.Fatal(err)
	}
	if m.owner != 3 {
		t.Fatal("the initial 7-hearts holder was not used")
	}
	next, err := m.nextSeat(m.owner, false)
	if err != nil || next != 2 {
		t.Fatalf("hard-coded visual order bypassed profile: seat=%d err=%v", next, err)
	}
	sequence := 1
	chooseTest(t, m, Complex, sequence)
	sequence++
	playCompleteComplex(t, m, &sequence)
	if err := m.AdvanceDeal(cards.Deck()); err != nil {
		t.Fatal(err)
	}
	chooseTest(t, m, Trix, sequence)
	sequence++
	playCompleteTrix(t, m, &sequence)
	if err := m.AdvanceDeal(cards.Deck()); err != nil {
		t.Fatal(err)
	}
	if m.owner != 2 || m.kingdom != 1 || m.phase != ContractSelection {
		t.Fatalf("kingdom owner ignored reverse seat profile: owner=%d kingdom=%d phase=%s", m.owner, m.kingdom, m.phase)
	}
	if err := m.VerifyReplay(); err != nil {
		t.Fatal("reverse order replay is not deterministic", err)
	}
	if !errors.Is(profile.PublicActivation(), ErrUnapproved) {
		t.Fatal("test reverse seat order was treated as founder-approved")
	}
}

// assertCandidateDeckConservation proves that all 52 cards are either still
// privately held or already publicly played in this one proposed deal.
func assertCandidateDeckConservation(t *testing.T, m *Match, eventStart int) {
	t.Helper()
	seen := make(map[cards.Card]bool, 52)
	for _, hand := range m.hands {
		for _, card := range hand {
			if !validCard(card) || seen[card] {
				t.Fatalf("draft card is invalid or duplicated in a hand: %+v", card)
			}
			seen[card] = true
		}
	}
	played := 0
	for _, event := range m.events[eventStart:] {
		if event.Type != "card_played" && event.Type != "card_placed" {
			continue
		}
		if event.Card == nil || !validCard(*event.Card) || seen[*event.Card] {
			t.Fatalf("draft card is duplicated or invalid in event: %+v", event)
		}
		seen[*event.Card] = true
		played++
	}
	if len(seen) != 52 || played != int(m.playedCount) {
		t.Fatalf("draft deck conservation failed: unique=%d played=%d count=%d", len(seen), played, m.playedCount)
	}
}

func assertPhase1PrivateViews(t *testing.T, m *Match) {
	t.Helper()
	for seat, actor := range m.members {
		view, err := m.View(actor)
		if err != nil {
			t.Fatal("authenticated seat denied its own draft view", err)
		}
		if view.Seat != SeatID(seat) || view.Version != m.version ||
			!reflect.DeepEqual(view.Hand, m.hands[seat]) {
			t.Fatalf("seat %d received inconsistent private view", seat)
		}
		wire, err := json.Marshal(view)
		if err != nil {
			t.Fatal("draft view could not be encoded", err)
		}
		for opponent := range m.hands {
			if opponent == seat {
				continue
			}
			if view.OpponentCounts[opponent] != len(m.hands[opponent]) {
				t.Fatalf("seat %d saw incorrect opponent %d card count", seat, opponent)
			}
			for _, hidden := range m.hands[opponent] {
				cardWire, err := json.Marshal(hidden)
				if err != nil {
					t.Fatal(err)
				}
				if bytes.Contains(wire, cardWire) {
					t.Fatalf("seat %d draft view leaked unplayed opponent card from seat %d", seat, opponent)
				}
			}
		}
		moves, err := m.LegalMoves(actor)
		if err != nil || moves.Version != m.version {
			t.Fatalf("seat %d received invalid legal projection: %v", seat, err)
		}
		if SeatID(seat) != m.turn {
			if len(moves.Cards) != 0 || len(moves.Contracts) != 0 || moves.CanPass {
				t.Fatalf("off-turn seat %d was offered an action", seat)
			}
			continue
		}
		for _, card := range moves.Cards {
			if !hasCard(m.hands[seat], card) {
				t.Fatalf("seat %d offered a card it does not hold", seat)
			}
		}
		if moves.CanPass && (m.phase != TrixActive || len(moves.Cards) != 0) {
			t.Fatalf("seat %d offered illegal pass", seat)
		}
	}
	if _, err := m.View("unauthorized-player"); !errors.Is(err, ErrUnauthorized) {
		t.Fatal("nonmember was offered draft match view")
	}
	if _, err := m.LegalMoves("unauthorized-player"); !errors.Is(err, ErrUnauthorized) {
		t.Fatal("nonmember was offered private legal move projection")
	}
}
