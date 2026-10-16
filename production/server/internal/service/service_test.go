package service

import (
	"bytes"
	"errors"
	"os"
	"path/filepath"
	"sync"
	"testing"
	"time"
)

func setup(t *testing.T) (*Service, string) {
	t.Helper()
	path := filepath.Join(t.TempDir(), "state.json")
	s, err := Open(path)
	if err != nil {
		t.Fatal(err)
	}
	return s, path
}

func guest(t *testing.T, s *Service) Guest {
	t.Helper()
	g, err := s.NewGuest()
	if err != nil {
		t.Fatal(err)
	}
	return g
}

func cmd(id string) Command { return Command{ActionID: "action-0000000000-" + id} }

func create(t *testing.T, s *Service, g Guest) Table {
	t.Helper()
	c := cmd("create")
	c.Game = "tarneeb"
	table, err := s.Act(g.Token, "create", "", c)
	if err != nil {
		t.Fatal(err)
	}
	return table
}

func TestFourPlayersRecoveryAuthorizationAndLogout(t *testing.T) {
	s, path := setup(t)
	players := []Guest{guest(t, s), guest(t, s), guest(t, s), guest(t, s), guest(t, s)}
	table := create(t, s, players[0])
	if _, err := s.Table(players[1].Token, table.ID); !errors.Is(err, ErrNotFound) {
		t.Fatal("non-member can read private table")
	}
	for _, g := range players[1:4] {
		c := cmd("join")
		c.Invite = table.Invite
		var err error
		table, err = s.Act(g.Token, "join", "", c)
		if err != nil {
			t.Fatal(err)
		}
	}
	c := cmd("overflow")
	c.Invite = table.Invite
	if _, err := s.Act(players[4].Token, "join", "", c); !errors.Is(err, ErrFull) {
		t.Fatal("fifth player seated")
	}
	for _, g := range players[:4] {
		c := cmd("ready")
		c.ExpectedVersion = table.Version
		c.Ready = true
		var err error
		table, err = s.Act(g.Token, "ready", table.ID, c)
		if err != nil {
			t.Fatal(err)
		}
	}
	c = cmd("start")
	c.ExpectedVersion = table.Version
	if _, err := s.Act(players[0].Token, "start", table.ID, c); !errors.Is(err, ErrRules) {
		t.Fatal("unapproved gameplay enabled")
	}
	if _, err := s.Act(players[1].Token, "start", table.ID, c); !errors.Is(err, ErrNotFound) {
		t.Fatal("non-owner start authorized")
	}
	reopened, err := Open(path)
	if err != nil {
		t.Fatal(err)
	}
	for i, g := range players[:4] {
		m, err := reopened.Me(g.Token)
		if err != nil || m.TableID != table.ID {
			t.Fatal("session/table did not survive restart", err)
		}
		recovered, err := reopened.Table(g.Token, table.ID)
		if err != nil || recovered.Version != table.Version || !recovered.Seats[i].Ready {
			t.Fatal("table recovery mismatch")
		}
	}
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	for _, g := range players {
		if bytes.Contains(data, []byte(g.Token)) {
			t.Fatal("raw bearer persisted")
		}
	}
	info, _ := os.Stat(path)
	if info.Mode().Perm() != 0600 {
		t.Fatal("unsafe store permissions")
	}
	if err := reopened.Logout(players[0].Token); err != nil {
		t.Fatal(err)
	}
	if _, err := reopened.Me(players[0].Token); !errors.Is(err, ErrAuth) {
		t.Fatal("revoked session accepted")
	}
	reopened, err = Open(path)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := reopened.Me(players[0].Token); !errors.Is(err, ErrAuth) {
		t.Fatal("revocation lost on restart")
	}
}

func TestRetriesVersionsAndConcurrentSeatAssignment(t *testing.T) {
	s, _ := setup(t)
	owner := guest(t, s)
	table := create(t, s, owner)
	c := cmd("create")
	c.Game = "tarneeb"
	retry, err := s.Act(owner.Token, "create", "", c)
	if err != nil || retry.ID != table.ID || len(s.s.Tables) != 1 {
		t.Fatal("create not idempotent")
	}
	c.Game = "trix_complex"
	if _, err := s.Act(owner.Token, "create", "", c); !errors.Is(err, ErrConflict) {
		t.Fatal("action ID reuse accepted")
	}
	const racers = 8
	guests := make([]Guest, racers)
	for i := range guests {
		guests[i] = guest(t, s)
	}
	var wg sync.WaitGroup
	outcomes := make(chan error, racers)
	for _, g := range guests {
		wg.Add(1)
		go func(g Guest) {
			defer wg.Done()
			c := cmd("join")
			c.Invite = table.Invite
			_, err := s.Act(g.Token, "join", "", c)
			outcomes <- err
		}(g)
	}
	wg.Wait()
	close(outcomes)
	successes := 0
	for err := range outcomes {
		if err == nil {
			successes++
		} else if !errors.Is(err, ErrFull) {
			t.Fatal(err)
		}
	}
	if successes != 3 {
		t.Fatalf("accepted %d concurrent joins", successes)
	}
	current, _ := s.Table(owner.Token, table.ID)
	c = cmd("stale")
	c.ExpectedVersion = 1
	c.Ready = true
	if _, err := s.Act(owner.Token, "ready", table.ID, c); !errors.Is(err, ErrConflict) {
		t.Fatal("stale version accepted")
	}
	c = cmd("ready")
	c.ExpectedVersion = current.Version
	c.Ready = true
	ready, err := s.Act(owner.Token, "ready", table.ID, c)
	if err != nil {
		t.Fatal(err)
	}
	retry, err = s.Act(owner.Token, "ready", table.ID, c)
	if err != nil || retry.Version != ready.Version {
		t.Fatal("ready retry changed state")
	}
	// Returned pointers must not mutate authoritative state.
	retry.Seats[0].Ready = false
	actual, _ := s.Table(owner.Token, table.ID)
	if !actual.Seats[0].Ready {
		t.Fatal("private state aliases response")
	}
}

func TestLeaveOwnershipInviteAndExpiry(t *testing.T) {
	s, _ := setup(t)
	owner := guest(t, s)
	other := guest(t, s)
	table := create(t, s, owner)
	c := cmd("join")
	c.Invite = table.Invite
	table, err := s.Act(other.Token, "join", "", c)
	if err != nil {
		t.Fatal(err)
	}
	oldInvite := table.Invite
	c = cmd("leave")
	c.ExpectedVersion = table.Version
	left, err := s.Act(owner.Token, "leave", table.ID, c)
	if err != nil || left.Invite != "" {
		t.Fatal("departed player received rotated invite")
	}
	current, err := s.Table(other.Token, table.ID)
	if err != nil || current.OwnerID != other.Me.Player.ID || current.Invite == oldInvite {
		t.Fatal("ownership/invite not updated")
	}
	if _, err := s.Table(owner.Token, table.ID); !errors.Is(err, ErrNotFound) {
		t.Fatal("departed player retained access")
	}
	c = cmd("join-again")
	c.Invite = oldInvite
	if _, err := s.Act(owner.Token, "join", "", c); !errors.Is(err, ErrNotFound) {
		t.Fatal("revoked invite accepted")
	}
	s.now = func() time.Time { return owner.Me.ExpiresAt }
	if _, err := s.Me(owner.Token); !errors.Is(err, ErrAuth) {
		t.Fatal("expired token accepted")
	}
}

func TestFailedWritesDoNotAcknowledgeOrMutate(t *testing.T) {
	s, path := setup(t)
	g := guest(t, s)
	old := s.s
	// A regular file cannot serve as the parent directory of a snapshot.
	s.path = filepath.Join(path, "impossible.json")
	c := cmd("failed")
	c.Game = "tarneeb"
	if _, err := s.Act(g.Token, "create", "", c); err == nil {
		t.Fatal("write failure acknowledged")
	}
	if len(s.s.Tables) != len(old.Tables) || len(s.s.Receipts) != len(old.Receipts) {
		t.Fatal("failed transaction published")
	}
	s.path = path
	if _, err := s.Act(g.Token, "create", "", c); err != nil {
		t.Fatal("retry failed", err)
	}
}

func TestCorruptAndUnknownStoresFailClosed(t *testing.T) {
	for _, data := range []string{"{", `{"schema":99}`, `{"schema":1}`} {
		path := filepath.Join(t.TempDir(), "state.json")
		if err := os.WriteFile(path, []byte(data), 0600); err != nil {
			t.Fatal(err)
		}
		if _, err := Open(path); err == nil {
			t.Fatal("invalid store silently accepted")
		}
	}
}
