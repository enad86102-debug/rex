package service

import (
	"encoding/json"
	"os"
	"testing"
)

func TestStoreIntegrityViolationsFailClosed(t *testing.T) {
	for _, name := range []string{"owner_not_member", "unknown_game", "zero_version", "duplicate_seat", "duplicate_invite", "invalid_receipt"} {
		t.Run(name, func(t *testing.T) {
			s, path := setup(t)
			g := guest(t, s)
			table := create(t, s, g)
			second := guest(t, s)
			other := create(t, s, second)
			switch name {
			case "owner_not_member":
				table.OwnerID = second.Me.Player.ID
			case "unknown_game":
				table.Game = "unapproved"
			case "zero_version":
				table.Version = 0
			case "duplicate_seat":
				table.Seats[1] = table.Seats[0]
			case "duplicate_invite":
				table.Invite = other.Invite
			case "invalid_receipt":
				for key, receipt := range s.s.Receipts {
					receipt.Fingerprint = "broken"
					s.s.Receipts[key] = receipt
					break
				}
			}
			s.s.Tables[table.ID] = table
			data, err := json.Marshal(s.s)
			if err != nil {
				t.Fatal(err)
			}
			if err := os.WriteFile(path, data, 0600); err != nil {
				t.Fatal(err)
			}
			if _, err := Open(path); err == nil {
				t.Fatal("inconsistent snapshot accepted")
			}
		})
	}
}
