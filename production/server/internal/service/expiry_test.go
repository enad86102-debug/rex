package service

import (
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func TestExpiredSessionSweepTransfersWaitingRoomAndPersists(t *testing.T) {
	s, path := setup(t)
	owner := guest(t, s)
	peer := guest(t, s)
	table := create(t, s, owner)
	join := cmd("expiry-peer-join")
	join.Invite = table.Invite
	joined, err := s.Act(peer.Token, "join", "", join)
	if err != nil {
		t.Fatal(err)
	}
	// A second live session for the owner keeps their seat when the first ends.
	secondToken := strings.Repeat("a", 64)
	if err := s.transaction(func(st *state) error {
		st.Sessions[digest(secondToken)] = Session{PlayerID: owner.Me.Player.ID, ExpiresAt: owner.Me.ExpiresAt.Add(time.Hour)}
		peerSession := st.Sessions[digest(peer.Token)]
		peerSession.ExpiresAt = owner.Me.ExpiresAt.Add(2 * time.Hour)
		st.Sessions[digest(peer.Token)] = peerSession
		return nil
	}); err != nil {
		t.Fatal(err)
	}
	s.now = func() time.Time { return owner.Me.ExpiresAt }
	count, err := s.SweepExpired()
	if err != nil || count != 1 {
		t.Fatalf("first sweep: %d %v", count, err)
	}
	if _, err := s.Me(owner.Token); !errors.Is(err, ErrAuth) {
		t.Fatal("expired token survived")
	}
	if current, err := s.Table(secondToken, table.ID); err != nil || current.OwnerID != owner.Me.Player.ID {
		t.Fatal("live session lost seat")
	}
	count, err = s.SweepExpired()
	if err != nil || count != 0 {
		t.Fatal("clean sweep changed state", count, err)
	}
	s.now = func() time.Time { return owner.Me.ExpiresAt.Add(time.Hour) }
	count, err = s.SweepExpired()
	if err != nil || count != 1 {
		t.Fatalf("second sweep: %d %v", count, err)
	}
	current, err := s.Table(peer.Token, table.ID)
	if err != nil || current.OwnerID != peer.Me.Player.ID || current.Seats[0] != nil || current.Invite == joined.Invite || current.Version != joined.Version+1 {
		t.Fatal("expired owner retained seat or invite")
	}
	if _, err := s.Me(secondToken); !errors.Is(err, ErrAuth) {
		t.Fatal("second expired token survived")
	}
	reopened, err := Open(path)
	if err != nil {
		t.Fatal(err)
	}
	if persisted, err := reopened.Table(peer.Token, table.ID); err != nil || persisted.Version != current.Version || persisted.Invite != current.Invite {
		t.Fatal("sweep not durable")
	}
}

func TestExpiredSessionSweepFailureDoesNotRevokeOrMoveSeat(t *testing.T) {
	s, path := setup(t)
	g := guest(t, s)
	table := create(t, s, g)
	s.now = func() time.Time { return g.Me.ExpiresAt }
	s.path = filepath.Join(path, "bad.json")
	if count, err := s.SweepExpired(); err == nil || count != 0 {
		t.Fatal("failed sweep acknowledged")
	}
	if _, exists := s.s.Sessions[digest(g.Token)]; !exists {
		t.Fatal("failed sweep revoked in memory")
	}
	if member(s.s.Tables[table.ID], g.Me.Player.ID) < 0 {
		t.Fatal("failed sweep removed seat")
	}
	s.path = path
	if count, err := s.SweepExpired(); err != nil || count != 1 {
		t.Fatalf("retry: %d %v", count, err)
	}
	if _, exists := s.s.Tables[table.ID]; exists {
		t.Fatal("empty room not deleted")
	}
	if info, err := os.Stat(path); err != nil || info.Mode().Perm() != 0600 {
		t.Fatal("unsafe recovered store")
	}
}
