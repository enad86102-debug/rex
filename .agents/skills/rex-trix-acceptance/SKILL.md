---
name: rex-trix-acceptance
description: "Review the proposed Trix Complex contract and isolate unapproved variants before enabling matches."
---

# rex-trix-acceptance

## When to use
Review the proposed Trix Complex contract and isolate unapproved variants before enabling matches.

## Workflow
1. Compare RULES_CONTRACT_0.9.0_DRAFT.md and implemented tests; keep draft blocked.
2. Check 4 kingdoms and 8 deals, Complex undoubled -500 and Trix +500 scoring with Q diamonds double category.
3. Collect founder decisions on leading hearts, forced discard, doubles, redeal, tie, direction, dealer, reconnect and resign.
4. Provide legal/illegal move fixture examples and exact expected results for each proposed policy.
5. Do not change public /start while approval evidence is absent; preserve Tarneeb.

## Checks to run when appropriate
- `cd production/server && go test -race ./internal/games/trixcomplex/...`

## Delivery standard
Record branch and exact SHA, reviewed files, commands actually run, failure evidence, human approvals still needed, and verdict PASS / REQUEST_CHANGES / BLOCK. Never fabricate tools, real subagents, tests or approval.
