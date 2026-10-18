---
name: rex-game-client-reconcile
description: "Test Flutter server state reconciliation and idempotent action transport under lost packets. Use for the relevant REX source changes or review."
---

# rex-game-client-reconcile

## Scope
Test Flutter server state reconciliation and idempotent action transport under lost packets.

## Work procedure
1. Start with actual production/mobile controller and server match protocol, not legacy demo.
2. Simulate missing acknowledgement, duplicate retry, out-of-order event and server version conflict.
3. Require one authoritative server result and a client-visible consistent hand/score after reconnection.
4. Validate secure pending-action storage and cleanup through app restart.
5. Run widget and integration tests, report unverified real Android device behavior.

## Sources to consult, not auto-execute
- [flutter-integration](https://docs.flutter.dev/cookbook/testing/integration/introduction) — research reference, not a runtime dependency
- [owasp-masvs](https://mas.owasp.org/MASVS/) — research reference, not a runtime dependency

## Evidence contract
Report actual source SHA, inspected paths and lines, exact tests (or NOT_RUN), security implications, reviewer dissent, and one of PASS / REQUEST_CHANGES / BLOCK. The tool or external skill must not be claimed installed unless actually verified in the active environment. Approval classes D2/D3 remain human-gated.
