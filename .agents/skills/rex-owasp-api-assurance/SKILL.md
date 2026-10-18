---
name: rex-owasp-api-assurance
description: "Apply OWASP API object, property and function authorization checks to Go match endpoints. Use for the relevant REX source changes or review."
---

# rex-owasp-api-assurance

## Scope
Apply OWASP API object, property and function authorization checks to Go match endpoints.

## Work procedure
1. Map endpoint to caller session, table and seat; identify object IDs and exposed properties.
2. Test forged actor, other match IDs, deleted-room replay, stale expected_version and invalid action_id.
3. Test response filtering of private cards and admin records, including errors and reconnect.
4. Constrain bodies, concurrency, timeouts and rate limits without claiming DDoS immunity.
5. Produce explicit regression tests and exact file:line findings.

## Sources to consult, not auto-execute
- [owasp-api](https://api-security.owasp.org/editions/2023/en/0x11-t10/) — research reference, not a runtime dependency
- [go-security](https://go.dev/doc/security/best-practices) — research reference, not a runtime dependency

## Evidence contract
Report actual source SHA, inspected paths and lines, exact tests (or NOT_RUN), security implications, reviewer dissent, and one of PASS / REQUEST_CHANGES / BLOCK. The tool or external skill must not be claimed installed unless actually verified in the active environment. Approval classes D2/D3 remain human-gated.
