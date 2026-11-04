// Package matchstorage contains reusable, production-independent security
// primitives for candidate durable match checkpoints. It does not select,
// open or migrate a commercial database.
package matchstorage

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"encoding/json"
	"errors"
)

const (
	KeySize = 32
	NonceSize = 12
	MaxCheckpointBytes = 1 << 20
)

var ErrInvalidCheckpoint = errors.New("invalid_encrypted_checkpoint")

// SealedCheckpoint contains no encryption key. Only ciphertext may be sent
// to a storage backend; never expose it to player-facing HTTP responses.
type SealedCheckpoint struct {
	Schema uint8 `json:"schema"`
	KeyID string `json:"key_id"`
	Nonce []byte `json:"nonce"`
	Ciphertext []byte `json:"ciphertext"`
}

func validContext(key []byte, keyID, matchID, rulesVersion string) bool {
	return len(key) == KeySize && len(keyID) >= 1 && len(keyID) <= 100 &&
		len(matchID) >= 1 && len(matchID) <= 128 &&
		len(rulesVersion) >= 1 && len(rulesVersion) <= 180
}

func associatedData(matchID, rulesVersion string) ([]byte, error) {
	// Fixed-order JSON encoding is unambiguous even for punctuation in IDs.
	return json.Marshal(struct {
		Domain string `json:"domain"`
		MatchID string `json:"match_id"`
		RulesVersion string `json:"rules_version"`
	}{
		Domain: "rex.match.private-checkpoint.v1",
		MatchID: matchID,
		RulesVersion: rulesVersion,
	})
}

// SealCandidateCheckpoint encrypts private source bytes using AES-256-GCM and
// authenticated context binding. The caller supplies an externally held key.
// Key loading, rotation and at-rest operational controls require human D2 review.
func SealCandidateCheckpoint(key []byte, keyID, matchID, rulesVersion string, plaintext []byte) (SealedCheckpoint, error) {
	if !validContext(key, keyID, matchID, rulesVersion) ||
		len(plaintext) == 0 || len(plaintext) > MaxCheckpointBytes {
		return SealedCheckpoint{}, ErrInvalidCheckpoint
	}
	block, err := aes.NewCipher(key)
	if err != nil {
		return SealedCheckpoint{}, ErrInvalidCheckpoint
	}
	aead, err := cipher.NewGCM(block)
	if err != nil {
		return SealedCheckpoint{}, ErrInvalidCheckpoint
	}
	nonce := make([]byte, aead.NonceSize())
	if _, err = rand.Read(nonce); err != nil {
		return SealedCheckpoint{}, ErrInvalidCheckpoint
	}
	aad, err := associatedData(matchID, rulesVersion)
	if err != nil {
		return SealedCheckpoint{}, ErrInvalidCheckpoint
	}
	ciphertext := aead.Seal(nil, nonce, plaintext, aad)
	return SealedCheckpoint{Schema: 1, KeyID: keyID, Nonce: nonce, Ciphertext: ciphertext}, nil
}

// OpenCandidateCheckpoint rejects tampered data, mismatched keys and material
// copied between matches or rules versions. It never returns partial plaintext.
func OpenCandidateCheckpoint(key []byte, expectedKeyID, matchID, rulesVersion string, sealed SealedCheckpoint) ([]byte, error) {
	if !validContext(key, expectedKeyID, matchID, rulesVersion) ||
		sealed.Schema != 1 || sealed.KeyID != expectedKeyID ||
		len(sealed.Nonce) != NonceSize ||
		len(sealed.Ciphertext) <= 16 ||
		len(sealed.Ciphertext) > MaxCheckpointBytes+16 {
		return nil, ErrInvalidCheckpoint
	}
	block, err := aes.NewCipher(key)
	if err != nil {
		return nil, ErrInvalidCheckpoint
	}
	aead, err := cipher.NewGCM(block)
	if err != nil {
		return nil, ErrInvalidCheckpoint
	}
	aad, err := associatedData(matchID, rulesVersion)
	if err != nil {
		return nil, ErrInvalidCheckpoint
	}
	plaintext, err := aead.Open(nil, sealed.Nonce, sealed.Ciphertext, aad)
	if err != nil || len(plaintext) == 0 || len(plaintext) > MaxCheckpointBytes {
		return nil, ErrInvalidCheckpoint
	}
	return plaintext, nil
}
