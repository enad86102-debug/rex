package service

import (
	"encoding/hex"
	"errors"
	"strings"
)

// Reject semantically corrupt snapshots rather than restoring identities or
// permissions from dangling references. This is integrity checking, not a MAC
// or a replacement for service-owned file permissions and encrypted backups.
func validateState(st state) error {
	bad := errors.New("inconsistent store")
	if len(st.Players) > 10000 || len(st.Tables) > 10000 || len(st.Receipts) > 100000 || len(st.Audit) > 10000 {
		return bad
	}
	for id, p := range st.Players {
		if !validHex(id, 16) || p.ID != id || p.CreatedAt.IsZero() {
			return bad
		}
	}
	for hash, session := range st.Sessions {
		if _, ok := st.Players[session.PlayerID]; !ok || !validHex(hash, 32) || session.ExpiresAt.IsZero() {
			return bad
		}
	}
	seated := map[string]bool{}
	invites := map[string]bool{}
	for id, t := range st.Tables {
		if id != t.ID || !validHex(id, 16) || !validHex(t.Invite, 16) || invites[t.Invite] || t.Version == 0 || t.CreatedAt.IsZero() {
			return bad
		}
		if t.Game != "tarneeb" && t.Game != "trix_complex" {
			return bad
		}
		invites[t.Invite] = true
		if t.OwnerID == "" || member(t, t.OwnerID) < 0 {
			return bad
		}
		for _, seat := range t.Seats {
			if seat == nil {
				continue
			}
			if _, ok := st.Players[seat.PlayerID]; !ok || seated[seat.PlayerID] {
				return bad
			}
			seated[seat.PlayerID] = true
		}
	}
	for key, receipt := range st.Receipts {
		actor, action, ok := strings.Cut(key, ":")
		if _, exists := st.Players[actor]; !ok || !exists || len(action) < 16 || len(action) > 128 || !validHex(receipt.Fingerprint, 32) || receipt.At.IsZero() || !validHex(receipt.Table.ID, 16) || receipt.Table.Version == 0 {
			return bad
		}
	}
	return nil
}

func validHex(value string, size int) bool {
	if len(value) != size*2 {
		return false
	}
	data, err := hex.DecodeString(value)
	return err == nil && hex.EncodeToString(data) == value
}
