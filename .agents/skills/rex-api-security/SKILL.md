---
name: rex-api-security
description: "Review REX Go and Flutter security with executable negative tests and privacy safeguards."
---

# rex-api-security

## When to use
Review REX Go and Flutter security with executable negative tests and privacy safeguards.

## Workflow
1. Review object/property/function authorization, session bearer origin, JSON parsing, rate limits and input validation.
2. Attack action ID collisions, deleted-room receipts, seat forgery and duplicate settlement.
3. Run current security scripts where available; record actual tool versions and skipped checks.
4. Keep tokens/secrets/hidden hands out of API errors, analytics and logs.
5. Never claim 'unhackable'; provide exact file:line and reproduction for confirmed findings.

## Checks to run when appropriate
- `bash production/tools/check_security.sh`
- `cd production/server && go test -race ./...`

## Delivery standard
Record branch and exact SHA, reviewed files, commands actually run, failure evidence, human approvals still needed, and verdict PASS / REQUEST_CHANGES / BLOCK. Never fabricate tools, real subagents, tests or approval.
