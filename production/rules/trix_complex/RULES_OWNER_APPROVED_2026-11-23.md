# REX Trix Complex — owner-approved rules / engineering review pending

**Owner decision document:** `REX_V1_Rules_and_Game_Code_Separation_AR.docx`, signed in the document as **عمار، 23 تشرين الثاني 2026**.
**Source of truth:** The uploaded owner report; this file is a faithful engineering transcription of decisions rather than an independent interpretation of a competitor's game.
**Approval scope:** **gameplay policy agreed by the owner**. **Not** approval of code implementation, public gameplay activation, or app-store publication.
**Previous technical baseline:** `RULES_CONTRACT_0.9.0_DRAFT.md` is retained for provenance; do not relabel it approved.
**Implementation release gate:** CLOSED until technical review by عبدالعزيز, functional tests, client/transport/DB integration and production signoff.
**Rule profile candidate for implementation:** `REX/TRIX-COMPLEX/2026-11-23-owner-rules`. The profile is not wired into public match start.

## Twelve owner-approved decisions

1. **Individual table:** exactly four independent players and independent ranking. Partnerships 2v2 deferred.
2. **Match:** four kingdoms, two different contracts (`complex` and `trix`) per kingdom, eight deals total. Kingdom owner sees their hand and has **15 seconds** to select the first contract; if deadline expires, `complex` is chosen automatically. A fresh valid deal precedes the second contract. No contract repeats within one kingdom.
3. **Seating and dealer:** play advances **rightward**. Relative to the bottom player the cycle is bottom → right → top → left → bottom. The server chooses the **first dealer at random**; from later deals the **kingdom owner** deals. The first card goes to the dealer's right. A standard 52-card deck, no jokers, 13 unique cards per player; invalid/duplicate deals are rejected.
4. **Lead:** the kingdom owner leads both contracts. Complex winner leads the following trick. In Trix a seat with no legal card **passes automatically**, including the first turn.
5. **Kingdom owner:** first owner is whoever has 7♥ in the first valid deal. After two contracts, owner changes to the rightward next player. Later 7♥ holders never change ownership.
6. **Complex:** 13 tricks, follow led suit when holding that suit, highest rank of led suit wins (A highest); no trump. The trick winner pays **−15 per trick, −10 per diamond, −25 per queen, −75 for king of hearts**. Queen of diamonds incurs both −25 and −10 plus any trick −15, making −50 for a trick whose only penalty card is Q♦.
7. **Leading/discarding:** leading hearts is permitted from trick one; with no led-suit card, any owned card can be played. No mandatory penalty-card discard.
8. **Trix:** each suit starts with J and extends consecutively to A upwards or 2 downwards; one legal card per turn; automatic pass only if no legal card. Placement scores **+200, +150, +100, +50**. Last remaining player automatically receives fourth position and the deal ends.
9. **Doubling:** enabled **only during Complex** for K♥ and the four queens. Before any Complex card play, all four players privately select their held eligible cards for **10 seconds concurrently**; all selections are revealed together after the deadline. No selection means pass. Each card can be doubled at most once; max five eligible marked cards at the table. A marked K♥ incurs −150 (instead of −75), a marked queen −50 (instead of −25). Its holder gains +75 or +25 if a different player takes the doubled card; if holder captures it, no bonus and the doubled debit applies to themselves. Q♦ still has its independent −10 diamond debit. A trick featuring doubled Q♦ as its only penalty card incurs **−75** to the taker, plus **+25 bonus to its original holder** only if different from taker.
10. **Technical redeal/recovery:** a proven failure before the first play may cause a redeal. Completed contract results must be preserved. If a valid earlier deal already identified kingdom owner and contract, preserve those choices. After play begins, restore the last valid state **using the same cards**, not a new deal. If unrecoverable, cancel match for technical failure **without competitive result**.
11. **Timeouts, bot and withdrawal:** **15 seconds per card**, **60 seconds reconnect grace** from disconnect. On turn timeout, the server makes **one legal move**. Returning within grace resumes the current state. On grace expiry or explicit resignation, a bot continues that seat; the human is recorded withdrawn/lost. Seat points remain in history, but only players who finish are winner-eligible. Human and bot obey the same move legality; neither can inspect opponent hands.
12. **Result/rematch:** after all four kingdoms highest cumulative score wins. A **tie for first** goes to the tied player who finished earliest in the **last Trix contract**. Rematch requires four explicit approvals, retains the same seats, resets scores to zero, and shuffles anew.

## Architecture and game separation

- Every game owns its own engine, score/turn rules, timers, bot, private match-state schema, event validation, routes, UI/game table and independent tests.
- No game can directly import a second game's code or access another game's save. Every stored match, event and action is namespaced with both **game ID** and **match ID**; reject mismatches.
- Platform-level authentication, transport and general storage can be shared only through game-neutral interfaces and without leaking game-specific rules.
- `complex` and `trix` here are two **internal contracts of one Trix Complex game**, not a decision to remove separately requested games from REX V1. The exact V1 game menu still requires a separate product scope decision.
- A game module must build and test without installing or registering another game's module.

## Implementation matrix

| Area | Status at transcription | Gate |
|---|---|---|
| Existing draft Complex/Trix deterministic play and candidate match replay | Tested in prior candidate suite, *not an approved-rules run* | New approved integration |
| Owner-approved seat/contract/timing/double/tie **pure functions** | Implemented in `owner_approved_v1_rules.go` and tested separately | Integrate with authoritative match |
| Private double selection and owner-bonus calculation | Pure policy and tests implemented; not yet persisted/connected to player transport | Simultaneous reveal + durable transaction + UI |
| 15-second selection and timed turn / 60-second reconnect | Constants and selection fallback pure functions; scheduling/reconnect not integrated | Server clock, atomic receipts, idempotency |
| Dealer, auto-pass, 4-seat bot, technical rollback, winner/rematch | Approved policy written above; some tested draft semantics | Full match integration tests still required |
| Cross-game import and save isolation | Architecture requirement recorded | Per-game CI build and negative cross-ID tests |
| Public play / publishing | NOT AUTHORIZED | Technical review and launch authorization |

## Acceptance tests required before coding gate can close

- Clock-controlled selection/double/turn and reconnect tests, including simultaneous submit, cutoff race, late request, reconnect during double and bot turn.
- Golden score ledger checks for doubled Q♦, self-capture, multiple different doubled cards, base trick penalty and declaration bonus.
- Eight complete deals across both contract orders; exact rightward kingdom/seat order and first dealer, valid unique decks and automatic Trix pass.
- Atomic state/replay after restart; single accepted action/score even if timeout and reconnect race; irrecoverable technical failure has no competitive winner.
- Authentication and deck confidentiality for humans **and bots**, game-ID and match-ID mismatch rejection.
- Four explicit rematch approvals; equal leader score resolved by latest Trix finish; withdrawn player never wins.
- Game code import boundaries and separate CI test/build; player sees reasons for score changes, timer, bot state, and double indicators.

**Important:** this document must not be treated as a signed review by عبدالعزيز. Document approval by عمار concerns game rules, not code readiness.
