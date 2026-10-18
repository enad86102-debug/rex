---
name: rex-go-engine
description: "Implement deterministic Go card-rule transitions and match events with real server authority."
---

# rex-go-engine

## When to use
Implement deterministic Go card-rule transitions and match events with real server authority.

## Workflow
1. Read production/server/internal/cards and matchcore plus existing games/trixcomplex engine tests.
2. Use typed Match, Phase, Action, Event and RulesVersion with explicit legal transitions.
3. Validate turn, seat, ownership, card-in-hand, legal move and scoring before state change.
4. Ensure rejected actions preserve state and duplicate action IDs cannot double-score.
5. Write deterministic fixtures, adversarial tests and replay evidence; no invented rule policy.

## Checks to run when appropriate
- `cd production/server && go test -race ./internal/games/trixcomplex/...`
- `cd production/server && go vet ./...`

## Delivery standard
Record branch and exact SHA, reviewed files, commands actually run, failure evidence, human approvals still needed, and verdict PASS / REQUEST_CHANGES / BLOCK. Never fabricate tools, real subagents, tests or approval.
