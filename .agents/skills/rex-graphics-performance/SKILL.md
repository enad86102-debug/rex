---
name: rex-graphics-performance
description: "Measure Android scene FPS, jank, texture memory, thermal and startup on representative devices."
---

# rex-graphics-performance

## When to use
Measure Android scene FPS, jank, texture memory, thermal and startup on representative devices.

## Workflow
1. Document device model/API/SoC, build variant, reference scene, assets, renderer and quality preset.
2. Measure frame time, jank, memory, startup, battery and thermal under sustained use.
3. Quantify texture, vertex, draw-call and animation costs; reduce before sacrificing play readability.
4. Distinguish desktop render, emulator screenshot and real phone metrics.
5. Reject unsupported 60FPS or photoreal claims.

## Checks to run when appropriate
- `cd production/mobile && flutter test`

## Delivery standard
Record branch and exact SHA, reviewed files, commands actually run, failure evidence, human approvals still needed, and verdict PASS / REQUEST_CHANGES / BLOCK. Never fabricate tools, real subagents, tests or approval.
