---
name: rex-live-four-client-e2e
description: "Require four distinct client identities to complete genuine server-authoritative Trix/Tarneeb matches. Use for the relevant REX source changes or review."
---

# rex-live-four-client-e2e

## Scope
Require four distinct client identities to complete genuine server-authoritative Trix/Tarneeb matches.

## Work procedure
1. Create four independent client sessions and join an actual room.
2. Validate private hand views from server, legal/illegal actions and actual score deltas.
3. Run full eight-deal approved Trix game, then separately approved Tarneeb, preserving end-to-end trace.
4. Interrupt one client and server process at predictable boundaries, reconnect, and verify no duplicate play.
5. Record whether test used Dart transports, emulator or four physical Android devices; never conflate them.

## Sources to consult, not auto-execute
- [flutter-integration](https://docs.flutter.dev/cookbook/testing/integration/introduction) — research reference, not a runtime dependency
- [go-security](https://go.dev/doc/security/best-practices) — research reference, not a runtime dependency

## Evidence contract
Report actual source SHA, inspected paths and lines, exact tests (or NOT_RUN), security implications, reviewer dissent, and one of PASS / REQUEST_CHANGES / BLOCK. The tool or external skill must not be claimed installed unless actually verified in the active environment. Approval classes D2/D3 remain human-gated.
