# REX Phase 1 — source comparison and explicit owner decisions

**Research reference, not an REX approval or permission to copy another game's code/assets.**
Source (accessed 2026-11-23): [Jawaker official Arabic Trix Complex rules](https://blog.jawaker.com/trix-complex-rules/), originally published 2020-12-06.

## Well-supported comparison

| Topic | Jawaker published rule | Current REX 0.9.0-draft | Engineering judgement |
|---|---|---|---|
| Participants | 4 players; individual and partnership are distinct versions | 4 individuals only | Good draft alignment; founder chooses V1 mode |
| Deck | 52 cards, no jokers, 13 each | Same | Covered by four-seat deal validation |
| Kingdoms | 4 kingdoms, 2 contracts (Complex and Trix) each | 4 × 2 = 8 deals | Covered by 8-deal simulation; needs explicit acceptance |
| First owner | Player holding 7♥ in initial deal | Same | Covered |
| Kingdom handoff | After two contracts, ownership to player on right | Candidate seat-order 0→1→2→3 | **Do not equate screen right with numeric seat order** before UX mapping |
| First move in Complex | Kingdom owner leads | Owner in candidate | Covered for Complex; Trix initial turn convention still confirm |
| Complex legal move | Must follow led suit when held; winner highest played card of led suit | Same, no trump | Covered |
| Complex scoring | Trick -15, each diamond -10, each queen -25, K♥ -75 | Same without doubling | Golden fixtures; total = -500 undoubled |
| Trix placement | Each suit begins J, stretches consecutively to 2 and A; no legal card means pass | Same | Covered |
| Trix scoring | Finish-order +200/+150/+100/+50 | Same | Covered |
| Double | In Complex, may reveal K♥ or queens; capturing a doubled card costs twice, declarer gets original value as bonus | **Disabled** | Major missing business decision; do not enable until exact timing/eligibility/self-capture defined |
| Final winner | Highest points | Draft exposes scores only, no tie-break winner | Winner on unique max is suggested; ties need explicit policy |
| Partnership scoring | Opposite players total their team's points | Not supported | Separate profile/variant if approved |

## Unresolved even after reference research
- Exact seat order and dealer's physical mapping, card-dealing rotation, and whether the app should support reverse orientation.
- Restrictions on leading hearts or discarding penalty cards where unable to follow suit (the cited page does not specify special restrictions).
- Double declaration timing and visibility in every edge case, especially if declarer captures their own doubled card, if Q♦ is doubled, or if several cards are doubled.
- Time limits, disconnects, leave/forfeit, pause/AI substitute, invalid/redeal and rematch rules.
- Tie handling, rankings, reward settlement, manipulation prevention, and commercial release policy.

## Suggested fastest owner signoff path

**Owner-only decisions:** adopt (or revise) the cited **individual** rules for O-01–O-08, decide if doubling is required in the first REX version (if yes, specify complete policy), and decide interruption and tie policies with examples. Avoid inventing missing rules as implicit defaults.

**Technical requirement:** approved V1 rules must become a **new immutable version** with corresponding tests. Do not change `REX-GAME-TRIX-COMPLEX/0.9.0-draft` from PROPOSED to APPROVED or remove its `ErrUnapproved` gate.

**Status:** RESEARCH ONLY — founder signoff pending; PR not merge-ready.
