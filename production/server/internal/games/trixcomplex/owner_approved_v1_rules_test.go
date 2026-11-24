package trixcomplex

import (
	"errors"
	"reflect"
	"sync"
	"testing"
	"time"

	"rex/production/server/internal/cards"
)

func TestApprovedOwnerContractDeadlineAndRightwardSeats(t *testing.T) {
	want := [4]SeatID{1, 2, 3, 0}
	for seat, next := range want {
		got, err := RightwardNextSeat(SeatID(seat))
		if err != nil || got != next {
			t.Fatalf("seat %d moved to %d not %d (%v)", seat, got, next, err)
		}
	}
	if _, err := RightwardNextSeat(4); err == nil {
		t.Fatal("out-of-range seat was accepted")
	}
	both := []ContractType{Complex, Trix}
	first, err := TimedContractSelection(both, Trix, 14*time.Second)
	if err != nil || first != Trix {
		t.Fatal("owner was unable to choose Trix before deadline", err)
	}
	if _, err := TimedContractSelection(both, "", 14*time.Second); !errors.Is(err, ErrInvalidState) {
		t.Fatal("unexpired deadline incorrectly selected a contract")
	}
	fallback, err := TimedContractSelection(both, "", 15*time.Second)
	if err != nil || fallback != Complex {
		t.Fatal("Complex must start when 15-second deadline expires", err)
	}
	next, err := TimedContractSelection([]ContractType{Trix}, "", 15*time.Second)
	if err != nil || next != Trix {
		t.Fatal("already used Complex was selected a second time", err)
	}
	if _, err := TimedContractSelection(both, Trix, 15*time.Second); err == nil {
		t.Fatal("late contract choice accepted")
	}
	if _, err := TimedContractSelection([]ContractType{Trix}, Complex, 10*time.Second); err == nil {
		t.Fatal("already-used contract accepted")
	}
}

func TestApprovedDoubleSelectionHiddenAndSimultaneous(t *testing.T) {
	m := newTestMatch(t)
	start := time.Unix(1000000, 0)
	window, err := NewDoubleSelectionWindow(m.hands, start)
	if err != nil {
		t.Fatal(err)
	}
	var doublables [4][]cards.Card
	for seat, hand := range m.hands {
		for _, card := range hand {
			if isDoublable(card) {
				doublables[seat] = append(doublables[seat], card)
			}
		}
	}
	totalEligible := 0
	for _, hand := range doublables {
		totalEligible += len(hand)
	}
	if totalEligible != 5 {
		t.Fatalf("expected king of hearts and four queens, got %d", totalEligible)
	}
	for seat, eligible := range doublables {
		if err := window.Submit(SeatID(seat), eligible, start.Add(9*time.Second)); err != nil {
			t.Fatal("eligible player could not announce", err)
		}
	}
	if marks, err := window.Reveal(start.Add(9 * time.Second)); err == nil || len(marks) != 0 {
		t.Fatal("early double card reveal before shared deadline")
	}
	flags, err := window.SubmittedFlags()
	if err != nil || flags != [4]bool{true, true, true, true} {
		t.Fatal("submission status incorrect")
	}
	marks, err := window.Reveal(start.Add(SimultaneousDoubleWindow))
	if err != nil || len(marks) != 5 {
		t.Fatal("all five selected cards not revealed together at 10 sec", err)
	}
	seen := map[cards.Card]bool{}
	for _, mark := range marks {
		if !isDoublable(mark.Card) || seen[mark.Card] || !hasCard(m.hands[mark.Owner], mark.Card) {
			t.Fatal("invalid or wrong-owner double declaration revealed")
		}
		seen[mark.Card] = true
	}
	if err := window.Submit(0, nil, start.Add(SimultaneousDoubleWindow)); err == nil {
		t.Fatal("late selection changed double declaration")
	}
}

func TestApprovedDoubleSelectionGuards(t *testing.T) {
	m := newTestMatch(t)
	start := time.Unix(1000000, 0)
	w, err := NewDoubleSelectionWindow(m.hands, start)
	if err != nil {
		t.Fatal(err)
	}
	seat := SeatID(0)
	var unowned, invalid cards.Card
	for _, card := range cards.Deck() {
		if !hasCard(m.hands[seat], card) && isDoublable(card) {
			unowned = card
			break
		}
	}
	for _, card := range m.hands[seat] {
		if !isDoublable(card) {
			invalid = card
			break
		}
	}
	for _, invalidSelection := range [][]cards.Card{{unowned}, {invalid}} {
		if err := w.Submit(seat, invalidSelection, start); err == nil {
			t.Fatal("unowned or non-eligible card doubled")
		}
	}
	var owned cards.Card
	found := false
	for _, card := range m.hands[seat] {
		if isDoublable(card) {
			owned, found = card, true
			break
		}
	}
	if !found {
		t.Fatal("test hand missing a doublable card")
	}
	if err := w.Submit(seat, []cards.Card{owned, owned}, start); err == nil {
		t.Fatal("duplicate double was accepted")
	}
	if err := w.Submit(seat, []cards.Card{owned}, start.Add(-time.Second)); err == nil {
		t.Fatal("selection before phase start accepted")
	}
	if err := w.Submit(seat, []cards.Card{owned}, start); err != nil {
		t.Fatal(err)
	}
	if err := w.Submit(seat, nil, start.Add(time.Second)); err != nil {
		t.Fatal("explicit pass before deadline rejected", err)
	}
	marks, err := w.Reveal(start.Add(SimultaneousDoubleWindow))
	if err != nil || len(marks) != 0 {
		t.Fatal("revised explicit pass did not clear selection")
	}
	dupHands := m.hands
	dupHands[0] = append([]cards.Card(nil), m.hands[0]...)
	dupHands[0][0] = dupHands[1][0]
	if _, err := NewDoubleSelectionWindow(dupHands, start); err == nil {
		t.Fatal("duplicate deck accepted")
	}
}

func TestApprovedComplexDoubleScoringAndSelfCapture(t *testing.T) {
	qDiamond := cards.Card{Suit: cards.Diamonds, Rank: 12}
	plays := []Play{
		{Seat: 0, Card: cards.Card{Suit: cards.Clubs, Rank: 2}},
		{Seat: 1, Card: qDiamond},
		{Seat: 2, Card: cards.Card{Suit: cards.Spades, Rank: 14}},
		{Seat: 3, Card: cards.Card{Suit: cards.Clubs, Rank: 10}},
	}
	got, err := ScoreApprovedComplexTrick(plays, []DoubleMark{{Card: qDiamond, Owner: 1}})
	if err != nil || got.Winner != 3 || got.BasePenalty != -50 || got.DoubleExtra != -25 ||
		got.Delta != [4]int{0, 25, 0, -75} {
		t.Fatalf("doubled Q diamonds not audited correctly: %+v err=%v", got, err)
	}
	self := []Play{
		{Seat: 0, Card: cards.Card{Suit: cards.Diamonds, Rank: 2}},
		{Seat: 1, Card: qDiamond},
		{Seat: 2, Card: cards.Card{Suit: cards.Clubs, Rank: 3}},
		{Seat: 3, Card: cards.Card{Suit: cards.Spades, Rank: 14}},
	}
	got, err = ScoreApprovedComplexTrick(self, []DoubleMark{{Card: qDiamond, Owner: 1}})
	if err != nil || got.Winner != 1 || got.Delta != [4]int{0, -85, 0, 0} {
		t.Fatalf("self-capture must double debit without bonus: %+v err=%v", got, err)
	}
	king := cards.Card{Suit: cards.Hearts, Rank: 13}
	both := []Play{
		{Seat: 0, Card: cards.Card{Suit: cards.Clubs, Rank: 14}},
		{Seat: 1, Card: qDiamond},
		{Seat: 2, Card: king},
		{Seat: 3, Card: cards.Card{Suit: cards.Clubs, Rank: 2}},
	}
	got, err = ScoreApprovedComplexTrick(both, []DoubleMark{{Card: qDiamond, Owner: 1}, {Card: king, Owner: 2}})
	if err != nil || got.BasePenalty != -125 || got.DoubleExtra != -100 ||
		got.Delta != [4]int{-225, 25, 75, 0} {
		t.Fatalf("multiple doubled penalties or bonuses incorrect: %+v err=%v", got, err)
	}
	if _, err := ScoreApprovedComplexTrick(plays, []DoubleMark{{Card: qDiamond, Owner: 1}, {Card: qDiamond, Owner: 1}}); err == nil {
		t.Fatal("same card doubled twice")
	}
	if _, err := ScoreApprovedComplexTrick(plays, []DoubleMark{{Card: qDiamond, Owner: 2}}); err == nil {
		t.Fatal("doubled card owner spoofed")
	}
}

func TestApprovedWinnerWithTieAndWithdrawal(t *testing.T) {
	finish := []SeatID{3, 1, 0, 2}
	scenarios := []struct {
		score     [4]int
		withdrawn [4]bool
		want      SeatID
	}{
		{score: [4]int{10, 10, 0, 0}, want: 1},
		{score: [4]int{0, 10, 0, 10}, want: 3},
		{score: [4]int{40, 50, 0, 60}, withdrawn: [4]bool{false, false, false, true}, want: 1},
		{score: [4]int{1, 2, 3, 4}, want: 3},
	}
	for _, tc := range scenarios {
		got, err := OwnerApprovedWinner(tc.score, tc.withdrawn, finish)
		if err != nil || got != tc.want {
			t.Fatalf("unexpected winner=%d wanted=%d err=%v", got, tc.want, err)
		}
	}
	if _, err := OwnerApprovedWinner([4]int{}, [4]bool{true, true, true, true}, finish); err == nil {
		t.Fatal("declared winner when all seats withdrew")
	}
	if _, err := OwnerApprovedWinner([4]int{}, [4]bool{}, []SeatID{0, 0, 2, 3}); err == nil {
		t.Fatal("duplicated final Trix places accepted")
	}
	// Public activation remains blocked even though owner-approved rules are
	// present as isolated policy functions awaiting technical integration.
	if !errors.Is(testProfile().PublicActivation(), ErrUnapproved) {
		t.Fatal("candidate rules unexpectedly enabled for public play")
	}
	if KingdomContractDeadline != CardActionDeadline || ReconnectGracePeriod != 4*CardActionDeadline {
		t.Fatal("approved timer constants changed")
	}
	if !reflect.DeepEqual(rightwardSeatOrder, [4]SeatID{0, 1, 2, 3}) {
		t.Fatal("approved rightward order was modified")
	}
}

func TestApprovedDoubleWindowSimultaneousSubmissionsRaceSafe(t *testing.T) {
	m := newTestMatch(t)
	start := time.Unix(999999, 0)
	window, err := NewDoubleSelectionWindow(m.hands, start)
	if err != nil {
		t.Fatal(err)
	}
	var wg sync.WaitGroup
	errs := make(chan error, 4)
	for seat := 0; seat < 4; seat++ {
		wg.Add(1)
		go func(seat int) {
			defer wg.Done()
			var selected []cards.Card
			for _, c := range m.hands[seat] {
				if isDoublable(c) {
					selected = append(selected, c)
				}
			}
			errs <- window.Submit(SeatID(seat), selected, start.Add(time.Second))
		}(seat)
	}
	wg.Wait()
	close(errs)
	for err := range errs {
		if err != nil {
			t.Fatal("simultaneous legitimate announcement rejected", err)
		}
	}
	revealed, err := window.Reveal(start.Add(SimultaneousDoubleWindow))
	if err != nil || len(revealed) != 5 {
		t.Fatalf("simultaneous announcements lost: %d (%v)", len(revealed), err)
	}
	if err := window.Submit(0, nil, start.Add(time.Second)); err == nil {
		t.Fatal("old-timestamp submission modified already revealed announcements")
	}
	again, err := window.Reveal(start.Add(SimultaneousDoubleWindow))
	if err != nil || !reflect.DeepEqual(revealed, again) {
		t.Fatal("same reveal not repeatable", err)
	}
}
