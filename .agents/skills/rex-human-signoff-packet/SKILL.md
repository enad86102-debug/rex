---
name: rex-human-signoff-packet
description: "Convert unresolved REX product decisions into a concise approval packet without inventing founder consent. Use for the relevant REX source changes or review."
---

# rex-human-signoff-packet

## Scope
Convert unresolved REX product decisions into a concise approval packet without inventing founder consent.

## Work procedure
1. Distinguish technical D0/D1 from human D2/D3 using REX charter.
2. Record rules version, policy variants, risks, alternatives and deterministic score fixtures.
3. Record exact Abdulaziz technical review evidence and required Ammar decision where applicable.
4. Lock public activation of unapproved game contracts and spending.
5. Output a specific decision question and separate implementation path after approval.

## Sources to consult, not auto-execute
- [agent-skills-spec](https://agentskills.io/specification) — research reference, not a runtime dependency
- [openai-repo-pattern](https://developers.openai.com/blog/skills-agents-sdk) — research reference, not a runtime dependency

## Evidence contract
Report actual source SHA, inspected paths and lines, exact tests (or NOT_RUN), security implications, reviewer dissent, and one of PASS / REQUEST_CHANGES / BLOCK. The tool or external skill must not be claimed installed unless actually verified in the active environment. Approval classes D2/D3 remain human-gated.
