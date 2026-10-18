---
name: rex-operations-recovery
description: "Prepare recoverable Go server operations, backups, observability, secrets and incident handling."
---

# rex-operations-recovery

## When to use
Prepare recoverable Go server operations, backups, observability, secrets and incident handling.

## Workflow
1. Document TLS edge/proxy, trust boundaries, rate limits, liveness/readiness and service alerts.
2. Build deterministic backup/restore migration tests and simulate kill/restart/rollback.
3. Prepare clear operational runbook and risk-controlled rollout, not a speculative Kubernetes stack.
4. Protect secrets and service admin permissions; require independent security review.
5. Do not equate Docker image success with operating a public match service.

## Checks to run when appropriate
- `bash production/tools/check_live.sh`

## Delivery standard
Record branch and exact SHA, reviewed files, commands actually run, failure evidence, human approvals still needed, and verdict PASS / REQUEST_CHANGES / BLOCK. Never fabricate tools, real subagents, tests or approval.
