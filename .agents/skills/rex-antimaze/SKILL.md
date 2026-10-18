---
name: rex-antimaze
description: "Reject circular planning, research inflation and unrelated infrastructure that delays a real playable match."
---

# rex-antimaze

## When to use
Reject circular planning, research inflation and unrelated infrastructure that delays a real playable match.

## Workflow
1. Identify exactly which player journey becomes usable after the proposed patch.
2. Ask whether a working component already exists in production/server or production/mobile.
3. Reject duplicated layers, unapproved economy, guide-only final art, fake wins and speculative architecture.
4. Keep three active streams maximum and demand a regression/falsifiable acceptance test for each task.
5. Produce next smallest shippable code change plus explicitly blocked human decisions.

## Checks to run when appropriate
- `python3 supervision/tools/swarm_check.py --root .`

## Delivery standard
Record branch and exact SHA, reviewed files, commands actually run, failure evidence, human approvals still needed, and verdict PASS / REQUEST_CHANGES / BLOCK. Never fabricate tools, real subagents, tests or approval.
