---
name: rex-android-masvs-assurance
description: "Apply OWASP MASVS verification to REX Android credential lifecycle and network boundaries. Use for the relevant REX source changes or review."
---

# rex-android-masvs-assurance

## Scope
Apply OWASP MASVS verification to REX Android credential lifecycle and network boundaries.

## Work procedure
1. Map Keystore token, pending action ID and any local data to MASVS-STORAGE and CRYPTO concerns.
2. Review client auth/network/origin and HTTPS, backup exclusions, platform lifecycle and data-safety.
3. Exercise corrupted vault records, logout, force-stop/relaunch and replay of ambiguous pending actions.
4. Record emulator versus physical-device proof and non-testable controls separately.
5. Do not certify MASVS compliance without full control-by-control evidence.

## Sources to consult, not auto-execute
- [owasp-masvs](https://mas.owasp.org/MASVS/) — research reference, not a runtime dependency
- [flutter-integration](https://docs.flutter.dev/cookbook/testing/integration/introduction) — research reference, not a runtime dependency

## Evidence contract
Report actual source SHA, inspected paths and lines, exact tests (or NOT_RUN), security implications, reviewer dissent, and one of PASS / REQUEST_CHANGES / BLOCK. The tool or external skill must not be claimed installed unless actually verified in the active environment. Approval classes D2/D3 remain human-gated.
