---
name: rex-flutter-android
description: "Implement real server-backed Android match screens and validate session lifecycle plus Arabic RTL."
---

# rex-flutter-android

## When to use
Implement real server-backed Android match screens and validate session lifecycle plus Arabic RTL.

## Workflow
1. Work in production/mobile, never copy flattened legacy visuals for final game scene.
2. Render authenticated real hand, turn, contract, table, score and validated result; no fake gameplay.
3. Preserve Keystore AES-GCM and durable pending action IDs; test corrupt session and crash recovery.
4. Test RTL, small screens, lifecycle, offline/resume and actual Android build.
5. Label emulator results honestly and demand physical device testing before release.

## Checks to run when appropriate
- `cd production/mobile && flutter analyze`
- `cd production/mobile && flutter test`
- `cd production/mobile && flutter build apk --debug`

## Delivery standard
Record branch and exact SHA, reviewed files, commands actually run, failure evidence, human approvals still needed, and verdict PASS / REQUEST_CHANGES / BLOCK. Never fabricate tools, real subagents, tests or approval.
