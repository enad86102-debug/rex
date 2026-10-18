---
name: rex-match-privacy
description: "Adversarially validate per-player hidden hands, match views, logs and authorization boundaries."
---

# rex-match-privacy

## When to use
Adversarially validate per-player hidden hands, match views, logs and authorization boundaries.

## Workflow
1. List endpoints and fields that can expose cards, tokens, action receipts or future shuffle information.
2. Derive active actor and seat from verified server session; never trust client-supplied identity.
3. Test unauthorized table/match IDs, historical receipt replay, forged actions and opponent view reads.
4. Inspect WebSocket/reconnect/spectator/admin/error/log paths for hidden-hand leaks.
5. Block on exposure of private state and provide a reproducible exploit test, not a speculative claim.

## Checks to run when appropriate
- `cd production/server && go test -race ./internal/api/... ./internal/service/...`

## Delivery standard
Record branch and exact SHA, reviewed files, commands actually run, failure evidence, human approvals still needed, and verdict PASS / REQUEST_CHANGES / BLOCK. Never fabricate tools, real subagents, tests or approval.
