---
name: rex-thousand-audit-dispatch
description: "Use the 1000-item REX audit registry to select bounded relevant checks for each real PR. Use for the relevant REX source changes or review."
---

# rex-thousand-audit-dispatch

## Scope
Use the 1000-item REX audit registry to select bounded relevant checks for each real PR.

## Work procedure
1. Run python3 supervision/tools/audit_router.py --validate to confirm metadata.
2. Collect actual changed files from PR; route 8–16 audit assignments by --paths.
3. Spawn only actual supported reviewers, assign different read-only reviews with unambiguous evidence requests.
4. Keep registry NOT_RUN; write actual PASS/REQUEST_CHANGES/BLOCK findings in separate per-commit files.
5. Escalate API/privacy/persistence concerns, preserve blockers and stop D2/D3 approvals.

## Sources to consult, not auto-execute
- [openai-multiagent](https://developers.openai.com/api/docs/guides/agents-api/multi-agent) — research reference, not a runtime dependency
- [agent-skills-spec](https://agentskills.io/specification) — research reference, not a runtime dependency

## Evidence contract
Report actual source SHA, inspected paths and lines, exact tests (or NOT_RUN), security implications, reviewer dissent, and one of PASS / REQUEST_CHANGES / BLOCK. The tool or external skill must not be claimed installed unless actually verified in the active environment. Approval classes D2/D3 remain human-gated.
