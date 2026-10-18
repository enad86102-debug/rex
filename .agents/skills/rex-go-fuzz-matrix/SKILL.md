---
name: rex-go-fuzz-matrix
description: "Design bounded fuzz/property tests for REX Go rules, JSON and action receipt parsing. Use for the relevant REX source changes or review."
---

# rex-go-fuzz-matrix

## Scope
Design bounded fuzz/property tests for REX Go rules, JSON and action receipt parsing.

## Work procedure
1. Identify high-risk parsers and pure deterministic rule functions.
2. Generate seeds for valid/invalid decks, duplicate cards, malformed IDs and state-version overflow.
3. Use Go built-in fuzz capability with time/CPU caps and record seed count and coverage limits.
4. Retain reproducing corpus for every confirmed crash or invariant violation.
5. Do not call a brief fuzz run a mathematical proof.

## Sources to consult, not auto-execute
- [go-fuzz](https://go.dev/doc/security/fuzz/) — research reference, not a runtime dependency
- [go-security](https://go.dev/doc/security/best-practices) — research reference, not a runtime dependency

## Evidence contract
Report actual source SHA, inspected paths and lines, exact tests (or NOT_RUN), security implications, reviewer dissent, and one of PASS / REQUEST_CHANGES / BLOCK. The tool or external skill must not be claimed installed unless actually verified in the active environment. Approval classes D2/D3 remain human-gated.
