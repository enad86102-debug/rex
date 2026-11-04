package matchstorage

import (
	"bytes"
	"errors"
	"testing"
)

func keyOf(b byte) []byte {
	return bytes.Repeat([]byte{b}, KeySize)
}

func TestPrivateCheckpointAEADRoundTrip(t *testing.T) {
	key := keyOf(0x11)
	plaintext := []byte(`{"hands":[{"suit":3,"rank":14}],"action_id":"secret"}`)
	sealed, err := SealCandidateCheckpoint(key, "key-1", "match-a", "trix-candidate", plaintext)
	if err != nil {
		t.Fatal(err)
	}
	if bytes.Contains(sealed.Ciphertext, plaintext) || len(sealed.Nonce) != NonceSize {
		t.Fatal("private data was not sealed")
	}
	got, err := OpenCandidateCheckpoint(key, "key-1", "match-a", "trix-candidate", sealed)
	if err != nil || !bytes.Equal(got, plaintext) {
		t.Fatalf("decrypt mismatch: %v", err)
	}
}

func TestPrivateCheckpointAEADRejectsTamperAndContextSwap(t *testing.T) {
	key := keyOf(0x12)
	sealed, err := SealCandidateCheckpoint(key, "key-2", "match-b", "rules-v1", []byte("private"))
	if err != nil {
		t.Fatal(err)
	}
	cases := []struct {
		name string
		key []byte
		keyID, matchID, version string
		sealed SealedCheckpoint
	}{
		{"wrong key", keyOf(0x99), "key-2", "match-b", "rules-v1", sealed},
		{"wrong key id", key, "key-other", "match-b", "rules-v1", sealed},
		{"wrong match", key, "key-2", "match-other", "rules-v1", sealed},
		{"wrong rules version", key, "key-2", "match-b", "rules-v2", sealed},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			if _, err := OpenCandidateCheckpoint(tc.key, tc.keyID, tc.matchID, tc.version, tc.sealed); !errors.Is(err, ErrInvalidCheckpoint) {
				t.Fatalf("accepted invalid context: %v", err)
			}
		})
	}
	altered := sealed
	altered.Ciphertext = append([]byte(nil), sealed.Ciphertext...)
	altered.Ciphertext[len(altered.Ciphertext)-1] ^= 1
	if _, err := OpenCandidateCheckpoint(key, "key-2", "match-b", "rules-v1", altered); !errors.Is(err, ErrInvalidCheckpoint) {
		t.Fatal("accepted tampered ciphertext")
	}
	altered = sealed
	altered.Nonce = append([]byte(nil), sealed.Nonce...)
	altered.Nonce[0] ^= 1
	if _, err := OpenCandidateCheckpoint(key, "key-2", "match-b", "rules-v1", altered); !errors.Is(err, ErrInvalidCheckpoint) {
		t.Fatal("accepted tampered nonce")
	}
}

func TestPrivateCheckpointAEADRejectsInvalidInputs(t *testing.T) {
	cases := []struct { name string; key []byte; data []byte }{
		{"short key", []byte("short"), []byte("data")},
		{"empty data", keyOf(0x10), nil},
		{"oversize", keyOf(0x10), make([]byte, MaxCheckpointBytes+1)},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			if _, err := SealCandidateCheckpoint(tc.key, "key-3", "match-c", "rules-v1", tc.data); !errors.Is(err, ErrInvalidCheckpoint) {
				t.Fatalf("invalid envelope accepted: %v", err)
			}
		})
	}
}

func TestPrivateCheckpointNonceUniqueness(t *testing.T) {
	key := keyOf(0x44)
	a, err := SealCandidateCheckpoint(key, "key-4", "match-d", "rules-v1", []byte("same"))
	if err != nil { t.Fatal(err) }
	b, err := SealCandidateCheckpoint(key, "key-4", "match-d", "rules-v1", []byte("same"))
	if err != nil { t.Fatal(err) }
	if bytes.Equal(a.Nonce, b.Nonce) || bytes.Equal(a.Ciphertext, b.Ciphertext) {
		t.Fatal("encrypted checkpoints unexpectedly reused a nonce")
	}
}
