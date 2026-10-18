---
name: rex-ci-qa
description: "Run evidence-linked Go, Flutter, Android native, assets and security verification for changed code."
---

# rex-ci-qa

## When to use
Run evidence-linked Go, Flutter, Android native, assets and security verification for changed code.

## Workflow
1. Record SHA, environment, exact command, pass/fail/skipped, logs and CI run URL.
2. Run appropriate go test -race, go vet, Flutter analyze/test/build and security checks.
3. Add regression fixtures for actual defects and retain deterministic test artifacts.
4. Distinguish emulator vs physical device, unit replay vs durable replay, and lobby vs live match.
5. Block if critical regression or command failed; never infer product approval from green CI.

## Checks to run when appropriate
- `cd production/server && go test -race ./...`
- `cd production/mobile && flutter test`

## Delivery standard
Record branch and exact SHA, reviewed files, commands actually run, failure evidence, human approvals still needed, and verdict PASS / REQUEST_CHANGES / BLOCK. Never fabricate tools, real subagents, tests or approval.
