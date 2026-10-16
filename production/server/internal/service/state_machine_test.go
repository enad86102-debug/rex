package service

import (
	"encoding/json"
	"fmt"
	"math/rand/v2"
	"sort"
	"testing"
)

// Generated waiting-room action sequences assert persistence, atomic failure,
// membership isolation and replay invariants, without inventing game rules.
func TestGeneratedWaitingRoomRecoveryAndReplay(t *testing.T) {
	for _, seed := range []uint64{1, 7, 2026} {
		t.Run(fmt.Sprint(seed), func(t *testing.T) {
			s, path := setup(t)
			var players [8]Guest
			for i := range players {
				players[i] = guest(t, s)
			}
			rng := rand.New(rand.NewPCG(seed, seed+1))
			for step := 0; step < 200; step++ {
				g := players[rng.IntN(len(players))]
				me, err := s.Me(g.Token)
				if err != nil {
					t.Fatal(err)
				}
				op, id := "create", ""
				c := Command{ActionID: fmt.Sprintf("generated-%d-%06d", seed, step), Game: "tarneeb"}
				if me.TableID != "" {
					table, err := s.Table(g.Token, me.TableID)
					if err != nil {
						t.Fatal(err)
					}
					op, id, c.ExpectedVersion = "ready", table.ID, table.Version
					c.Ready = rng.IntN(2) == 0
					if rng.IntN(3) == 0 {
						op = "leave"
					}
				} else if len(s.s.Tables) > 0 && rng.IntN(2) == 0 {
					ids := make([]string, 0, len(s.s.Tables))
					for id := range s.s.Tables {
						ids = append(ids, id)
					}
					sort.Strings(ids)
					op = "join"
					c.Invite = s.s.Tables[ids[rng.IntN(len(ids))]].Invite
				}
				before, err := json.Marshal(s.s)
				if err != nil {
					t.Fatal(err)
				}
				result, actionErr := s.Act(g.Token, op, id, c)
				if actionErr != nil {
					after, err := json.Marshal(s.s)
					if err != nil {
						t.Fatal(err)
					}
					if string(before) != string(after) {
						t.Fatal("rejected action mutated state")
					}
				} else {
					replay, err := s.Act(g.Token, op, id, c)
					if err != nil {
						t.Fatal(err)
					}
					a, err := json.Marshal(result)
					if err != nil {
						t.Fatal(err)
					}
					b, err := json.Marshal(replay)
					if err != nil {
						t.Fatal(err)
					}
					if string(a) != string(b) {
						t.Fatal("replay changed outcome")
					}
				}
				if err := validateState(s.s); err != nil {
					t.Fatalf("seed %d step %d: %v", seed, step, err)
				}
				for _, other := range players {
					for _, table := range s.s.Tables {
						if member(table, other.Me.Player.ID) < 0 {
							if _, err := s.Table(other.Token, table.ID); err != ErrNotFound {
								t.Fatal("private table disclosed")
							}
						}
					}
				}
				if step%25 == 0 {
					before, err := json.Marshal(s.s)
					if err != nil {
						t.Fatal(err)
					}
					s, err = Open(path)
					if err != nil {
						t.Fatal(err)
					}
					after, err := json.Marshal(s.s)
					if err != nil {
						t.Fatal(err)
					}
					if string(before) != string(after) {
						t.Fatal("cold recovery changed committed state")
					}
				}
			}
		})
	}
}
