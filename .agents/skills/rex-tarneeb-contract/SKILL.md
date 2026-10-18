---
name: rex-tarneeb-contract
description: "Prepare a separate versioned Tarneeb bidding, trick and score contract for future production engine."
---

# rex-tarneeb-contract

## When to use
Prepare a separate versioned Tarneeb bidding, trick and score contract for future production engine.

## Workflow
1. Read REX product scope and RULES_DECISIONS; Tarneeb remains required by targeted V1.
2. Enumerate seat/team configuration, bid range, all-pass behavior, trump choice, follow suit and overtrumping options.
3. Enumerate tricks, contract success/failure, overtricks, special 13 bids, win threshold and tie/redeal policy.
4. Record unresolved regional differences rather than defaulting to copied competitor rules.
5. Produce candidate scenarios and explicit human-rule approval sheet before implementing scoring.

## Checks to run when appropriate
- `cd production/server && go test ./...`

## Delivery standard
Record branch and exact SHA, reviewed files, commands actually run, failure evidence, human approvals still needed, and verdict PASS / REQUEST_CHANGES / BLOCK. Never fabricate tools, real subagents, tests or approval.
