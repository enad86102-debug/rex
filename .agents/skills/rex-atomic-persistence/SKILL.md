---
name: rex-atomic-persistence
description: "Review transactionally durable match actions, receipts, events and recovery without data loss."
---

# rex-atomic-persistence

## When to use
Review transactionally durable match actions, receipts, events and recovery without data loss.

## Workflow
1. Document current JSON snapshot O(state-size) single-writer limitations and migration needs.
2. Propose a smallest viable transactional store and compare alternatives; D2 requires Abdulaziz review.
3. Demand atomic state + action receipt + event commit, stable schema and rules version.
4. Inject failures before/after commit, restart and duplicated retries; prove no double-action and replay correctness.
5. Specify backup/restore, retention, audit and rollback; no unapproved vendor selection.

## Checks to run when appropriate
- `cd production/server && go test -race ./internal/service/...`

## Delivery standard
Record branch and exact SHA, reviewed files, commands actually run, failure evidence, human approvals still needed, and verdict PASS / REQUEST_CHANGES / BLOCK. Never fabricate tools, real subagents, tests or approval.
