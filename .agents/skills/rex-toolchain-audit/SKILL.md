---
name: rex-toolchain-audit
description: "Choose and secure Go, Flutter, Android, Blender, validation and security tools needed for REX development."
---

# rex-toolchain-audit

## When to use
Choose and secure Go, Flutter, Android, Blender, validation and security tools needed for REX development.

## Workflow
1. Identify the concrete test/asset/build capability missing before proposing a tool.
2. Prefer built-in maintained tools; review license, ownership, versions, provenance, network privileges and costs.
3. Do not auto-install third-party skill scripts, random GitHub tools or secrets.
4. Mark studied tools separately from installed/executed tools; pin and smoke-test additions.
5. Document fallback when Cloud lacks ADB, Android SDK, Blender or a license asset.

## Checks to run when appropriate
- `go version`
- `flutter --version`
- `python3 --version`

## Delivery standard
Record branch and exact SHA, reviewed files, commands actually run, failure evidence, human approvals still needed, and verdict PASS / REQUEST_CHANGES / BLOCK. Never fabricate tools, real subagents, tests or approval.
