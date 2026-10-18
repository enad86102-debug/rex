---
name: rex-art-glb-intake
description: "Enforce GLB structural validation plus original asset-source, rig and licensing checks for royal REX art. Use for the relevant REX source changes or review."
---

# rex-art-glb-intake

## Scope
Enforce GLB structural validation plus original asset-source, rig and licensing checks for royal REX art.

## Work procedure
1. Inspect Blender editable source and ownership/license record first.
2. Run Khronos glTF Validator on actual delivered GLBs; record skins, animations, PBR, UV and counts.
3. Compare table/chair/character pose, camera, lighting and occlusion to REX references.
4. Test Android render load, LOD and texture budget; store screenshots and perf evidence.
5. Never call a syntactically valid GUIDE_ONLY mesh release ready.

## Sources to consult, not auto-execute
- [khronos-validator](https://github.com/KhronosGroup/glTF-Validator) — research reference, not a runtime dependency
- [flutter-profile](https://docs.flutter.dev/cookbook/testing/integration/profiling) — research reference, not a runtime dependency

## Evidence contract
Report actual source SHA, inspected paths and lines, exact tests (or NOT_RUN), security implications, reviewer dissent, and one of PASS / REQUEST_CHANGES / BLOCK. The tool or external skill must not be claimed installed unless actually verified in the active environment. Approval classes D2/D3 remain human-gated.
