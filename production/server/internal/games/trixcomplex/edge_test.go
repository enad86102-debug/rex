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

func TestRandomizedDealsAlwaysSettleWithoutLosingCards(t *testing.T) {
	for iteration := 0; iteration < 20; iteration++ {
		first, err := cards.Shuffle(cards.Deck())
		if err != nil {
			t.Fatal(err)
		}
		m, err := NewCandidateMatch("randomized-candidate", testProfile(), testMembers, first)
		if err != nil {
			t.Fatal(err)
		}
		sequence := 1
		chooseTest(t, m, Complex, sequence)
		sequence++
		playCompleteComplex(t, m, &sequence)
		second, err := cards.Shuffle(cards.Deck())
		if err != nil {
			t.Fatal(err)
		}
		if err := m.AdvanceDeal(second); err != nil {
			t.Fatal(err)
		}
		chooseTest(t, m, Trix, sequence)
		sequence++
		playCompleteTrix(t, m, &sequence)
		if _, err := m.Replay(); err != nil {
			t.Fatal("candidate replay failed", err)
		}
	}
}

func TestReceiptIdentityCannotCollideAcrossActors(t *testing.T) {
	members := [4]string{"owner", "east", "south", "owner:segment"}
	m, err := NewCandidateMatch("receipt-boundary-test", testProfile(), members, cards.Deck())
	if err != nil {
		t.Fatal(err)
	}
	if m.owner != 3 {
		t.Fatal("test deck no longer assigns owner to seat three")
	}
	choose := candidateAction(m, m.owner, ChooseContract, 1)
	choose.ActionID = "action-0000000001"
	choose.Contract = Complex
	if _, err := m.Apply(choose); err != nil {
		t.Fatal(err)
	}
	lead := candidateAction(m, m.turn, PlayCard, 2)
	lead.Card = m.hands[m.turn][0]
	if _, err := m.Apply(lead); err != nil {
		t.Fatal(err)
	}
	if m.turn != 0 {
		t.Fatal("test seat order changed")
	}
	follow := candidateAction(m, m.turn, PlayCard, 3)
	follow.ActionID = "segment:action-0000000001"
	for _, card := range m.hands[m.turn] {
		if complexLegal(m.hands[m.turn], m.trick, card) {
			follow.Card = card
			break
		}
	}
	if _, err := m.Apply(follow); err != nil {
		t.Fatalf("distinct actor/action pair collided with another receipt: %v", err)
	}
	if len(m.receipts) != 3 || m.VerifyReplay() != nil {
		t.Fatal("receipts or replay differ after distinct identities")
	}
	if _, err := m.Apply(follow); err != nil {
		t.Fatal("exact retry lost its idempotent receipt", err)
	}
}

func TestVerifyReplayDetectsPrivateStateOrJournalCorruption(t *testing.T) {
	m := newTestMatch(t)
	chooseTest(t, m, Complex, 1)
	if err := m.VerifyReplay(); err != nil {
		t.Fatal(err)
	}
	m.scores[0]++
	if err := m.VerifyReplay(); !errors.Is(err, ErrInvalidState) {
		t.Fatal("corrupted score was not detected")
	}
	m.scores[0]--
	m.journal[0].action.ExpectedVersion++
	if err := m.VerifyReplay(); !errors.Is(err, ErrInvalidState) {
		t.Fatal("corrupted journal was not detected")
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
