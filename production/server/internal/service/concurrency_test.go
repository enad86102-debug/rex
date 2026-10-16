package service

import (
	"errors"
	"sync"
	"testing"
)

func TestConcurrentDuplicateCreateCommitsExactlyOneIntention(t *testing.T) {
	s, _ := setup(t)
	g := guest(t, s)
	c := cmd("concurrent-create")
	c.Game = "tarneeb"
	var wg sync.WaitGroup
	results := make(chan string, 20)
	failures := make(chan error, 20)
	for i := 0; i < 20; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			table, err := s.Act(g.Token, "create", "", c)
			if err != nil {
				failures <- err
				return
			}
			results <- table.ID
		}()
	}
	wg.Wait()
	close(results)
	close(failures)
	for err := range failures {
		t.Fatal(err)
	}
	id := ""
	for got := range results {
		if id != "" && got != id {
			t.Fatal("duplicate room created")
		}
		id = got
	}
	if len(s.s.Tables) != 1 || len(s.s.Receipts) != 1 || len(s.s.Audit) != 2 {
		t.Fatal("duplicate effect or audit event")
	}
}

func TestDepartedPlayerCannotReplayJoinToReadRotatedInvitation(t *testing.T) {
	s, _ := setup(t)
	owner := guest(t, s)
	peer := guest(t, s)
	table := create(t, s, owner)
	join := cmd("join-peer")
	join.Invite = table.Invite
	joined, err := s.Act(peer.Token, "join", "", join)
	if err != nil {
		t.Fatal(err)
	}
	leave := cmd("leave-peer")
	leave.ExpectedVersion = joined.Version
	left, err := s.Act(peer.Token, "leave", table.ID, leave)
	if err != nil {
		t.Fatal(err)
	}
	if left.Invite != "" {
		t.Fatal("new invitation leaked to departed player")
	}
	if _, err := s.Act(peer.Token, "join", "", join); !errors.Is(err, ErrNotFound) {
		t.Fatal("replayed invitation view remained accessible")
	}
}
