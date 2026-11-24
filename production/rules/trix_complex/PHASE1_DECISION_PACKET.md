# REX Phase 1 — Trix Complex decision and acceptance packet

**Status: ENGINEERING DRAFT / NOT APPROVED FOR PUBLIC PLAY.**  
**Prepared:** 2026-11-23. **Product approver:** عمار. **Technical reviewer:** عبدالعزيز.  
**Source of current behavior:** `RULES_CONTRACT_0.9.0_DRAFT.md`, `profile-0.9.0-draft.json`, and the isolated Go `trixcomplex` candidate. No unrecorded business decision has been promoted to "approved."

## 1. Explicit proposal in the existing source

| Ref | Draft assertion to confirm or revise | Evidence and implementation |
|---|---|---|
| R-01 | 4 *individual* players, 52 unique cards per deal, 13 cards per player | `matchcore.NewDeal`; `TestPhase1CompleteEightDealMatrix` |
| R-02 | 4 kingdoms × 2 distinct contracts per kingdom = 8 deals | `engine.go`, `TestFullCandidateEightDealMatchAndReplay` |
| R-03 | First kingdom holder of **7 of hearts**; subsequent owners rotate by a chosen seat order | `NewCandidateMatch`; final seat rotation NOT approved |
| R-04 | Complex follows led suit if held; winner is highest led-suit card, no trump | `complex.go`, `TestPhase1GoldenUndoubledComplexTricks` |
| R-05 | Complex *candidate only* score: -15 per trick, -10 per diamond, -25 per queen, -75 for king of hearts; Q♦ gets both; full deal sums -500 | `TrickPenalty`; golden fixtures and full-match matrix |
| R-06 | Trix starts each suit at J, extends consecutively to 2 and A, must pass if no legal card, cannot pass otherwise | `trix.go`, `legal_moves_test.go` |
| R-07 | Trix *candidate only* scores finish order +200,+150,+100,+50; full deal sums +500 | `engine.go`, matrix settlement checks |
| R-08 | Complete draft example match totals zero across 4 Complex + 4 Trix deals | full-match and randomized matrix tests |
| R-09 | Draft cannot be publicly activated, even by spoofing an "approval" reference | `CandidateProfile.PublicActivation()`, `TestExplicitCandidatePolicyAndDraftGate` |
| R-10 | Server alone owns the deck, turn and scores. Player receives only own cards and counts for other seats | `View`/`LegalMoves`, authorization tests |

The rows above record **what the code and draft currently say**, not founder approval or standard rules of Trix in general.

## 2. Required founder decisions — do not infer

| ID | Founder approval needed | Recorded candidate setting / current unknown |
|---|---|---|
| O-01 | Confirm four players **individually** vs partnerships | `individual_candidate` ONLY |
| O-02 | Confirm 4 kingdoms, 2 contracts and 8-deal match | Proposed; not accepted |
| O-03 | Pick clockwise/counterclockwise seat direction, dealing direction and mapping between displayed chairs and seat IDs | Testing uses `0→1→2→3`, no owner approval |
| O-04 | Decide who begins each Complex trick and each Trix deal, whether it is always the owner, and whether dealing starts from any specific seat | Testing uses owner |
| O-05 | Confirm 7♥ holder as first owner, order of later kingdoms, contract choice restrictions | Candidate as shown |
| O-06 | Confirm Complex base penalties, double-counting Q♦, lead restrictions on hearts, and forced discard when unable to follow suit | Candidate: unrestricted; exceptions UNKNOWN |
| O-07 | Confirm legal Trix placements, passing and finish-order scores | Candidate as shown |
| O-08 | Decide **doubling**: eligible cards, announcer, time window, reveal, multipliers/awards, self-capture | Unsupported; cannot auto-activate |
| O-09 | Decide reshuffle/redeal, invalid deal and cancellation | Unsupported except manual candidate |
| O-10 | Decide disconnects, turn timeout, idle player, resignation, substitute player and resulting score | Unsupported; no automatic penalties |
| O-11 | Decide ties, final ranking and winner, rematch | Raw scores only; no fabricated winner |
| O-12 | Confirm whether training/private matches share the exact public rules profile | Separate explicit contracts recommended |

**Approval template (fill in by humans):**

- Product owner: **عمار**
- Rule profile ID and signed contract version: **NOT YET ASSIGNED**
- For each O-01…O-12: approved choice, rationale, example edge case, and approval date **NOT YET RECORDED**
- Technical review by **عبدالعزيز**: **PENDING**
- Release gate: **CLOSED** until versioned approved contract + golden tests + cross-platform evidence + persistent match architecture pass.

## 3. Engineering test evidence to require

- Canonical shuffled deck: exactly 52 unique cards, 4 authenticated seats.
- Legal move authority and follow-suit; no double-turn, out-of-turn, reused action ID, spoofed seat, or private-hand leak.
- At least 12 deterministic random-seed full **eight-deal** draft matches, varying deck and card choice. Every complete run: 52 Complex tricks across 4 contracts, 16 Trix finishers, 8 settled deals, 4 complete kingdoms, 1 match complete, aggregate score zero.
- Replaying the private journal yields identical match; private checkpoint round-trip yields identical match; duplicates return identical receipts without mutations.
- Golden score fixtures: simple trick; Q♦ + K♥ cumulative penalty; all diamonds; no-trump when an off-suit ace appears.
- Verify `PublicActivation()` remains `rules_not_approved`; public server does not register experimental gameplay.

**Evidence class distinctions:** Go unit tests validate a **candidate rules simulation**, not accepted card-game rules, mobile gameplay, four remote devices, or production database recovery.

## 4. Implementation gate and next changes

1. عمار fills the twelve owner-rule decisions and formally approves an immutable **new** contract version. This document cannot serve as self-approval.
2. عبدالعزيز checks the technical consistency, ambiguity, edge cases and test fixtures.
3. Engineer creates a separate approved profile and golden fixtures; retain the draft intact for provenance. No one flips the string `PROPOSED` to `APPROVED` in place.
4. Only after persistence/auth/reconnect architecture and integration tests can an approved game version be enabled in the actual public server.
5. Tarneeb remains in REX V1 scope but has its own independent contract.
