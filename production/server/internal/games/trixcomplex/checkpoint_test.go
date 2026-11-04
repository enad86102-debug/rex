package trixcomplex

import (
	"bytes"
	"encoding/json"
	"errors"
	"reflect"
	"testing"
)

func TestCloneIsolatesCandidateTransition(t *testing.T) {
	original := newTestMatch(t)
	before, err := original.PrivateCheckpoint()
	if err != nil {
		t.Fatal(err)
	}
	clone, err := original.Clone()
	if err != nil {
		t.Fatal(err)
	}
	action := candidateAction(clone, clone.owner, ChooseContract, 1)
	action.Contract = Complex
	if _, err := clone.Apply(action); err != nil {
		t.Fatal(err)
	}
	after, err := original.PrivateCheckpoint()
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(before, after) || original.phase != ContractSelection {
		t.Fatal("uncommitted clone changed authoritative match")
	}
}

func TestPrivateCheckpointRoundTripPreservesReceipt(t *testing.T) {
	m := newTestMatch(t)
	action := candidateAction(m, m.owner, ChooseContract, 1)
	action.Contract = Complex
	first, err := m.Apply(action)
	if err != nil {
		t.Fatal(err)
	}
	checkpoint, err := m.PrivateCheckpoint()
	if err != nil {
		t.Fatal(err)
	}
	restored, err := RestoreCandidateMatch(checkpoint)
	if err != nil {
		t.Fatal(err)
	}
	got, err := restored.Apply(action)
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(first, got) {
		t.Fatalf("receipt changed after restart: %#v != %#v", first, got)
	}
	wantView, _ := m.View(testMembers[0])
	gotView, _ := restored.View(testMembers[0])
	if !reflect.DeepEqual(wantView, gotView) {
		t.Fatal("restored private view differs")
	}
}

func TestRestoreCandidateMatchRejectsAlteredData(t *testing.T) {
	m := newTestMatch(t)
	checkpoint, err := m.PrivateCheckpoint()
	if err != nil {
		t.Fatal(err)
	}
	cases := [][]byte{
		nil,
		checkpoint[:len(checkpoint)/2],
		append(append([]byte(nil), checkpoint...), []byte("{}")...),
	}
	var decoded map[string]any
	if err := json.Unmarshal(checkpoint, &decoded); err != nil {
		t.Fatal(err)
	}
	decoded["unknown"] = true
	unknown, _ := json.Marshal(decoded)
	cases = append(cases, unknown)
	decoded = map[string]any{}
	if err := json.Unmarshal(checkpoint, &decoded); err != nil {
		t.Fatal(err)
	}
	decoded["version"] = float64(999)
	wrongVersion, _ := json.Marshal(decoded)
	cases = append(cases, wrongVersion)
	for i, data := range cases {
		if _, err := RestoreCandidateMatch(data); !errors.Is(err, ErrInvalidState) {
			t.Fatalf("case %d accepted altered checkpoint: %v", i, err)
		}
	}
}
