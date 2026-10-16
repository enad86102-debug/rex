// Package trixcomplex implements the explicitly proposed 0.9.0 Trix Complex
// rules as a pure candidate engine. It is not connected to public match start.
package trixcomplex

import (
	"errors"

	"rex/production/server/internal/cards"
)

type MatchID string
type RulesVersion string
type SeatID uint8
type Kingdom uint8
type ContractType string
type Phase string
type ActionType string

const (
	GameID       = "trix_complex"
	DraftVersion = RulesVersion("REX-GAME-TRIX-COMPLEX/0.9.0-draft")
	Complex      = ContractType("complex")
	Trix         = ContractType("trix")

	ContractSelection = Phase("contract_selection")
	ComplexActive     = Phase("complex_active")
	TrixActive        = Phase("trix_active")
	DealSettlement    = Phase("deal_settlement")
	MatchComplete     = Phase("match_complete")

	ChooseContract = ActionType("choose_contract")
	PlayCard       = ActionType("play_card")
	Pass           = ActionType("pass")
	DeclareDouble  = ActionType("declare_double")
)

var (
	ErrInvalidRules    = errors.New("invalid_rules_profile")
	ErrUnapproved      = errors.New("rules_not_approved")
	ErrInvalidState    = errors.New("invalid_match_state")
	ErrInvalidAction   = errors.New("invalid_match_action")
	ErrWrongTurn       = errors.New("wrong_turn")
	ErrIllegalCard     = errors.New("illegal_card")
	ErrPassForbidden   = errors.New("pass_forbidden")
	ErrActionConflict  = errors.New("action_id_conflict")
	ErrVersionConflict = errors.New("match_version_conflict")
	ErrUnauthorized    = errors.New("unauthorized_match_actor")
	ErrUnsupported     = errors.New("unsupported_rule_policy")
)

// CandidateProfile requires every choice that affects deterministic play to
// be explicit. These are test choices, not a release configuration.
type CandidateProfile struct {
	GameID               string
	Version              RulesVersion
	Status               string
	ApprovalReference    string
	SeatOrder            [4]SeatID
	OpeningLeaderPolicy  string // "owner" is the test candidate, not approval.
	HeartsLeadPolicy     string // Only explicit "unrestricted" is implemented.
	PenaltyDiscardPolicy string // Only explicit "unrestricted" is implemented.
	DoublingPolicy       string // Only explicit "disabled_candidate" is implemented.
	RedealPolicy         string // Only explicit "none_candidate" is implemented.
	TimeoutPolicy        string // Only explicit "manual_candidate" is implemented.
	ResignationPolicy    string // Only explicit "disabled_candidate" is implemented.
}

func (p CandidateProfile) Validate() error {
	if p.GameID != GameID || p.Version != DraftVersion || p.Status != "PROPOSED" || p.ApprovalReference != "" ||
		p.OpeningLeaderPolicy != "owner" || p.HeartsLeadPolicy != "unrestricted" ||
		p.PenaltyDiscardPolicy != "unrestricted" || p.DoublingPolicy != "disabled_candidate" ||
		p.RedealPolicy != "none_candidate" || p.TimeoutPolicy != "manual_candidate" ||
		p.ResignationPolicy != "disabled_candidate" {
		return ErrInvalidRules
	}
	seen := [4]bool{}
	for _, seat := range p.SeatOrder {
		if seat > 3 || seen[seat] {
			return ErrInvalidRules
		}
		seen[seat] = true
	}
	return nil
}

// PublicActivation is deliberately denied for this draft, even if a caller
// edits an approval-reference string. A new approved version needs review.
func (p CandidateProfile) PublicActivation() error { return ErrUnapproved }

type GameAction struct {
	MatchID         MatchID      `json:"match_id"`
	ActorID         string       `json:"actor_id"`
	ClaimedSeat     *SeatID      `json:"claimed_seat,omitempty"`
	ActionID        string       `json:"action_id"`
	ExpectedVersion uint64       `json:"expected_version"`
	RulesVersion    RulesVersion `json:"rules_version"`
	Type            ActionType   `json:"type"`
	Contract        ContractType `json:"contract,omitempty"`
	Card            cards.Card   `json:"card,omitempty"`
}

type Play struct {
	Seat SeatID     `json:"seat"`
	Card cards.Card `json:"card"`
}

type TrickState struct {
	Leader SeatID `json:"leader"`
	Plays  []Play `json:"plays"`
}

type TrixLayout struct {
	Low  [4]uint8 `json:"low"`
	High [4]uint8 `json:"high"`
}

type GameEvent struct {
	Type       string       `json:"type"`
	Seat       SeatID       `json:"seat"`
	Contract   ContractType `json:"contract,omitempty"`
	Card       *cards.Card  `json:"card,omitempty"`
	Winner     *SeatID      `json:"winner,omitempty"`
	ScoreDelta [4]int       `json:"score_delta,omitempty"`
}

type ScoringResult struct {
	Delta [4]int `json:"delta"`
}

type MatchResult struct {
	Scores [4]int `json:"scores"`
	// Tie policy is unresolved; no winner is fabricated from these scores.
}

type ActionResult struct {
	Version uint64      `json:"version"`
	Events  []GameEvent `json:"events"`
}

type PlayerMatchView struct {
	MatchID        MatchID      `json:"match_id"`
	RulesVersion   RulesVersion `json:"rules_version"`
	Version        uint64       `json:"version"`
	Seat           SeatID       `json:"seat"`
	Kingdom        Kingdom      `json:"kingdom"`
	Owner          SeatID       `json:"owner"`
	Phase          Phase        `json:"phase"`
	Contract       ContractType `json:"contract,omitempty"`
	Turn           SeatID       `json:"turn"`
	Hand           []cards.Card `json:"hand"`
	OpponentCounts [4]int       `json:"opponent_counts"`
	Trick          TrickState   `json:"trick"`
	Layout         TrixLayout   `json:"layout"`
	FinishOrder    []SeatID     `json:"finish_order"`
	Scores         [4]int       `json:"scores"`
	CompletedDeals uint8        `json:"completed_deals"`
}
