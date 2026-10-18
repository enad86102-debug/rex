---
name: rex-orchestrate
description: "Route REX engineering tasks to specialized reviewers and control scope, approvals and PR handoffs."
---

# rex-orchestrate

## When to use
Route REX engineering tasks to specialized reviewers and control scope, approvals and PR handoffs.

## Workflow
1. Inspect actual Git status, latest PR head, documents, human approvals and code before choosing tasks.
2. Choose one code owner, at most three simultaneous implementation work packages, up to four disjoint reviewer subagents if real subagents are available.
3. Apply D0-D3 decision classes from the charter; D2 architecture and D3 rules/release require human sign-off.
4. Require independent game/security/storage/QA review according to affected code; do not permit self-approval.
5. Return evidence, dissent and next smallest safe patch, not an unbounded research request.

## Checks to run when appropriate
- `git status --short`
- `python3 supervision/tools/swarm_check.py --root .`

## Delivery standard
Record branch and exact SHA, reviewed files, commands actually run, failure evidence, human approvals still needed, and verdict PASS / REQUEST_CHANGES / BLOCK. Never fabricate tools, real subagents, tests or approval.
