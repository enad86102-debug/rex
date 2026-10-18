---
name: rex-crash-consistency-chaos
description: "Inject storage/network failures into accepted match actions to prove exactly-once business effects. Use for the relevant REX source changes or review."
---

# rex-crash-consistency-chaos

## Scope
Inject storage/network failures into accepted match actions to prove exactly-once business effects.

## Work procedure
1. Identify durable transaction boundary for state, event and receipt; propose under D2 review.
2. Introduce failpoints before/after commit with deterministic test cleanup.
3. Kill/restart process at each failpoint and retry same action ID, checking score and hand invariants.
4. Test concurrent conflicting submissions and recovery with a stale client cursor.
5. Block deployment if a reported accepted move disappears or duplicates.

## Sources to consult, not auto-execute
- [go-security](https://go.dev/doc/security/best-practices) — research reference, not a runtime dependency
- [owasp-api](https://api-security.owasp.org/editions/2023/en/0x11-t10/) — research reference, not a runtime dependency

## Evidence contract
Report actual source SHA, inspected paths and lines, exact tests (or NOT_RUN), security implications, reviewer dissent, and one of PASS / REQUEST_CHANGES / BLOCK. The tool or external skill must not be claimed installed unless actually verified in the active environment. Approval classes D2/D3 remain human-gated.
