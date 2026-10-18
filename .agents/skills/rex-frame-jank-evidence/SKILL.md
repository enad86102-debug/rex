---
name: rex-frame-jank-evidence
description: "Measure sustained REX card table rendering performance with Flutter integration timelines. Use for the relevant REX source changes or review."
---

# rex-frame-jank-evidence

## Scope
Measure sustained REX card table rendering performance with Flutter integration timelines.

## Work procedure
1. Choose actual handset or emulator and document device/build/scene.
2. Use official integration-test performance timeline and profile mode where supported.
3. Measure frame build/raster, memory, jank, startup and thermal under interactive play.
4. Test low quality mode and reduced motion without altering card readability.
5. Record raw evidence and refuse unsourced 60-FPS claims.

## Sources to consult, not auto-execute
- [flutter-profile](https://docs.flutter.dev/cookbook/testing/integration/profiling) — research reference, not a runtime dependency
- [flutter-integration](https://docs.flutter.dev/cookbook/testing/integration/introduction) — research reference, not a runtime dependency

## Evidence contract
Report actual source SHA, inspected paths and lines, exact tests (or NOT_RUN), security implications, reviewer dissent, and one of PASS / REQUEST_CHANGES / BLOCK. The tool or external skill must not be claimed installed unless actually verified in the active environment. Approval classes D2/D3 remain human-gated.
