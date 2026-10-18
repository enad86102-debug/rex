---
name: rex-github-build-provenance
description: "Track exact code, toolchain, dependencies and signed Android artifact provenance. Use for the relevant REX source changes or review."
---

# rex-github-build-provenance

## Scope
Track exact code, toolchain, dependencies and signed Android artifact provenance.

## Work procedure
1. Link PR commit SHA to the full CI workflow and relevant job logs.
2. Ensure third-party actions and dependencies are least privilege and version-reviewed.
3. Document SDK versions, inputs, build mode, generated APK/AAB hash and test context.
4. Keep release signing keys outside Git; separate debug and actual Play-signed release.
5. Use SLSA principles as guidance, not a claim of attaining a specific SLSA level.

## Sources to consult, not auto-execute
- [slsa](https://slsa.dev/spec/v1.1/) — research reference, not a runtime dependency
- [android-api-target](https://developer.android.com/google/play/requirements/target-sdk) — research reference, not a runtime dependency

## Evidence contract
Report actual source SHA, inspected paths and lines, exact tests (or NOT_RUN), security implications, reviewer dissent, and one of PASS / REQUEST_CHANGES / BLOCK. The tool or external skill must not be claimed installed unless actually verified in the active environment. Approval classes D2/D3 remain human-gated.
