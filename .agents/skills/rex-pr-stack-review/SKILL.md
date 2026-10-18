---
name: rex-pr-stack-review
description: "Audit stacked production PR bases, hidden dependencies and minimal safe merge order."
---

# rex-pr-stack-review

## When to use
Audit stacked production PR bases, hidden dependencies and minimal safe merge order.

## Workflow
1. Query actual open PR base/head, commit SHA, changed files and CI, including PR14 and reporting side branches.
2. Review each diff against its immediate base, not only main; identify inherited changes and dependency order.
3. Check breakages introduced by the latest code and security fixes before any merge.
4. Return per-PR PASS/REQUEST_CHANGES/BLOCK with evidence, required tests and rollback.
5. Do not merge or force-push without explicit authorized direction.

## Checks to run when appropriate
- `git log --graph --oneline --all -30`

## Delivery standard
Record branch and exact SHA, reviewed files, commands actually run, failure evidence, human approvals still needed, and verdict PASS / REQUEST_CHANGES / BLOCK. Never fabricate tools, real subagents, tests or approval.
