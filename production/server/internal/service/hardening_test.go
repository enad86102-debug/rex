package service

import (
	"errors"
	"os"
	"testing"
)

func TestDirectLogoutReleasesWaitingSeatAndRotatesInvite(t *testing.T) {
	s, _ := setup(t)
	owner := guest(t, s)
	peer := guest(t, s)
	table := create(t, s, owner)
	c := cmd("peer-join")
	c.Invite = table.Invite
	joined, err := s.Act(peer.Token, "join", "", c)
	if err != nil {
		t.Fatal(err)
	}
	if err := s.Logout(owner.Token); err != nil {
		t.Fatal(err)
	}
	current, err := s.Table(peer.Token, table.ID)
	if err != nil {
		t.Fatal(err)
	}
	if current.OwnerID != peer.Me.Player.ID || current.Seats[0] != nil || current.Invite == joined.Invite || current.Version != joined.Version+1 {
		t.Fatal("direct logout left an inaccessible owner or reusable invitation")
	}
	if _, err := s.Me(owner.Token); !errors.Is(err, ErrAuth) {
		t.Fatal("logout failed to revoke session")
	}
}

func TestStoreRejectsDanglingSession(t *testing.T) {
	s, path := setup(t)
	g := guest(t, s)
	delete(s.s.Players, g.Me.Player.ID)
	// Syntactically valid JSON is not sufficient for recovery integrity.
	data := []byte(`{"schema":1,"players":{},"sessions":{"` + digest(g.Token) + `":{"player_id":"` + g.Me.Player.ID + `","expires_at":"2030-01-01T00:00:00Z"}},"tables":{},"receipts":{}}`)
	if err := os.WriteFile(path, data, 0600); err != nil {
		t.Fatal(err)
	}
	if _, err := Open(path); err == nil {
		t.Fatal("corrupt referential state accepted")
	}
}
