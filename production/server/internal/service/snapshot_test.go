package service

import (
	"encoding/json"
	"errors"
	"fmt"
	"path/filepath"
	"testing"
)

func TestFailedReadyDoesNotMutateSeatsOrReceipts(t *testing.T) {
	s, path := setup(t)
	g := guest(t, s)
	table := create(t, s, g)
	before, err := json.Marshal(s.s)
	if err != nil {
		t.Fatal(err)
	}
	s.path = filepath.Join(path, "not-a-directory.json")
	c := cmd("failed-ready")
	c.Ready = true
	c.ExpectedVersion = table.Version
	if _, err := s.Act(g.Token, "ready", table.ID, c); err == nil {
		t.Fatal("failed persistence acknowledged")
	}
	after, err := json.Marshal(s.s)
	if err != nil {
		t.Fatal(err)
	}
	if string(before) != string(after) {
		t.Fatal("failed write mutated nested state")
	}
	s.path = path
	if _, err := s.Act(g.Token, "ready", table.ID, c); err != nil {
		t.Fatal(err)
	}
	if err := s.transaction(func(st *state) error {
		for key, r := range st.Receipts {
			r.Table.Seats[0].Ready = !r.Table.Seats[0].Ready
			st.Receipts[key] = r
		}
		return errors.New("injected rollback")
	}); err == nil {
		t.Fatal("injected error lost")
	}
	for _, r := range s.s.Receipts {
		if r.Table.Version == table.Version && r.Table.Seats[0].Ready {
			t.Fatal("receipt seat aliased")
		}
	}
}

func BenchmarkSnapshotCopy(b *testing.B) {
	st := state{Schema: 1, Players: map[string]Player{}, Sessions: map[string]Session{}, Tables: map[string]Table{}, Receipts: map[string]Receipt{}}
	for i := 0; i < 1000; i++ {
		st.Receipts[fmt.Sprint(i)] = Receipt{Table: Table{ID: fmt.Sprint(i), Seats: [4]*Seat{{PlayerID: "synthetic-player"}}}}
	}
	b.Run("JSON_roundtrip_previous", func(b *testing.B) {
		b.ReportAllocs()
		for b.Loop() {
			data, err := json.Marshal(st)
			if err != nil {
				b.Fatal(err)
			}
			var next state
			if err := json.Unmarshal(data, &next); err != nil {
				b.Fatal(err)
			}
		}
	})
	b.Run("isolated_typed_copy", func(b *testing.B) {
		b.ReportAllocs()
		for b.Loop() {
			next := cloneState(st)
			if len(next.Receipts) != 1000 {
				b.Fatal("incomplete copy")
			}
		}
	})
}
