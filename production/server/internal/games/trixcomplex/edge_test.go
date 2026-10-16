package trixcomplex

import (
	"errors"
	"reflect"
	"testing"

	"rex/production/server/internal/cards"
)

func TestExplicitCandidatePolicyAndDraftGate(t *testing.T) {
	p := testProfile()
	if err := p.Validate(); err != nil {
		t.Fatal(err)
	}
	checks := []func(*CandidateProfile){
		func(x *CandidateProfile) { x.SeatOrder = [4]SeatID{0, 1, 1, 3} },
		func(x *CandidateProfile) { x.HeartsLeadPolicy = "" },
		func(x *CandidateProfile) { x.DoublingPolicy = "common_variant" },
		func(x *CandidateProfile) { x.Version = "approved-looking-version" },
		func(x *CandidateProfile) { x.Status = "APPROVED" },
		func(x *CandidateProfile) { x.ApprovalReference = "fabricated" },
	}
	for _, breakProfile := range checks {
		bad := p
		breakProfile(&bad)
		if !errors.Is(bad.Validate(), ErrInvalidRules) || !errors.Is(bad.PublicActivation(), ErrUnapproved) {
			t.Fatal("accepted implicit or fabricated policy")
		}
	}
	if err := ValidateDoubleDeclaration(p, DoublePolicy{}, DoubleDeclaration{}); !errors.Is(err, ErrUnsupported) {
		t.Fatal("activated unresolved doubling")
	}
}

func TestKingdomSelectionGuardsAndDeckRejection(t *testing.T) {
	m := newTestMatch(t)
	other := (m.owner + 1) % 4
	bad := candidateAction(m, other, ChooseContract, 1)
	bad.Contract = Complex
	if _, err := m.Apply(bad); !errors.Is(err, ErrInvalidAction) {
		t.Fatal("non-owner selected contract")
	}
	chooseTest(t, m, Complex, 2)
	if _, err := m.Apply(bad); !errors.Is(err, ErrVersionConflict) {
		t.Fatal("stale action accepted")
	}
	seq := 3
	playCompleteComplex(t, m, &seq)
	before, _ := m.Replay()
	badDeck := cards.Deck()
	badDeck[0] = badDeck[1]
	if err := m.AdvanceDeal(badDeck); err == nil || !reflect.DeepEqual(m, before) {
		t.Fatal("invalid next deck partially changed state")
	}
	if err := m.AdvanceDeal(cards.Deck()); err != nil {
		t.Fatal(err)
	}
	bad = candidateAction(m, m.owner, ChooseContract, seq+1)
	bad.Contract = Complex
	if _, err := m.Apply(bad); !errors.Is(err, ErrInvalidAction) {
		t.Fatal("same contract selected twice in kingdom")
	}
	chooseTest(t, m, Trix, seq+2)
	if m.phase != TrixActive {
		t.Fatal("second distinct contract not selected")
	}
}

func TestVersionIdentityAndResultGuards(t *testing.T) {
	m := newTestMatch(t)
	if _, err := m.Result(); !errors.Is(err, ErrInvalidState) {
		t.Fatal("unsettled match yielded result")
	}
	action := candidateAction(m, m.owner, ChooseContract, 1)
	action.Contract = Complex
	for _, change := range []func(*GameAction){
		func(x *GameAction) { x.MatchID = "another-match" },
		func(x *GameAction) { x.RulesVersion = "other-rules" },
		func(x *GameAction) { x.ActionID = "short" },
		func(x *GameAction) { x.ActorID = "outsider" },
	} {
		bad := action
		change(&bad)
		if _, err := m.Apply(bad); err == nil || m.version != 1 {
			t.Fatal("invalid action mutated match")
		}
	}
	if _, err := m.Apply(action); err != nil {
		t.Fatal(err)
	}
	if _, err := m.Apply(GameAction{MatchID: m.id, ActorID: m.members[m.turn],
		ActionID: "candidate-double-0001", ExpectedVersion: m.version,
		RulesVersion: m.profile.Version, Type: DeclareDouble}); !errors.Is(err, ErrUnsupported) {
		t.Fatal("unapproved double accepted")
	}
	if m.version != 2 {
		t.Fatal("rejected double changed version")
	}
}

func FuzzTrickWinnerAndPenalty(f *testing.F) {
	f.Add([]byte{0, 1, 2, 3})
	f.Add([]byte{51, 13, 26, 39})
	f.Fuzz(func(t *testing.T, indexes []byte) {
		if len(indexes) < 4 {
			return
		}
		deck := cards.Deck()
		seen := map[cards.Card]bool{}
		plays := make([]Play, 4)
		for i := range plays {
			card := deck[int(indexes[i])%len(deck)]
			if seen[card] {
				return
			}
			seen[card] = true
			plays[i] = Play{Seat: SeatID(i), Card: card}
		}
		winner, err := TrickWinner(plays)
		if err != nil {
			t.Fatal(err)
		}
		if plays[winner].Card.Suit != plays[0].Card.Suit {
			t.Fatal("off-suit winner")
		}
		penalty, err := TrickPenalty(plays)
		if err != nil || penalty > -15 || penalty < -230 {
			t.Fatal("invalid bounded penalty", penalty, err)
		}
	})
}
