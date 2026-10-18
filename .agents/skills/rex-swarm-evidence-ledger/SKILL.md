---
name: rex-swarm-evidence-ledger
description: "Preserve independent reviewer disagreements and reject inflated AI progress claims. Use for the relevant REX source changes or review."
---

# rex-swarm-evidence-ledger

## Scope
Preserve independent reviewer disagreements and reject inflated AI progress claims.

## Work procedure
1. Collect branch, SHA, actual subagent IDs or explicit sequential review disclosure.
2. For each reviewer save precise files, reproducer or test run, PASS/REQUEST_CHANGES/BLOCK and uncovered risk.
3. Use audit_router selected assignments only; do not mark all 1000 as checked.
4. Report implementer modifications and separate security/QA critique.
5. Summarize player-usable result, real remaining blockers and smallest next improvement.

## Sources to consult, not auto-execute
- [openai-multiagent](https://developers.openai.com/api/docs/guides/agents-api/multi-agent) — research reference, not a runtime dependency
- [openai-repo-pattern](https://developers.openai.com/blog/skills-agents-sdk) — research reference, not a runtime dependency

## Evidence contract
Report actual source SHA, inspected paths and lines, exact tests (or NOT_RUN), security implications, reviewer dissent, and one of PASS / REQUEST_CHANGES / BLOCK. The tool or external skill must not be claimed installed unless actually verified in the active environment. Approval classes D2/D3 remain human-gated.
