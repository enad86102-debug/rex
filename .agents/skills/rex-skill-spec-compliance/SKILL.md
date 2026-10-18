---
name: rex-skill-spec-compliance
description: "Validate REX repo-local skills against Agent Skills spec and safe scope boundaries. Use for the relevant REX source changes or review."
---

# rex-skill-spec-compliance

## Scope
Validate REX repo-local skills against Agent Skills spec and safe scope boundaries.

## Work procedure
1. Check name/folder, description, YAML frontmatter and progressive disclosure.
2. Audit linked scripts, references and licenses before executable bundling.
3. Keep SKILL.md focused; avoid recursively loading 1000 auditor packets into context.
4. Run swarm_check.py and audit_router --validate plus unit tests.
5. Do not claim a registered skill is installed in a Cloud session until discovery confirmed.

## Sources to consult, not auto-execute
- [agent-skills-spec](https://agentskills.io/specification) — research reference, not a runtime dependency
- [google-gemini-skills-guide](https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/skills-best-practices.md) — research reference, not a runtime dependency

## Evidence contract
Report actual source SHA, inspected paths and lines, exact tests (or NOT_RUN), security implications, reviewer dissent, and one of PASS / REQUEST_CHANGES / BLOCK. The tool or external skill must not be claimed installed unless actually verified in the active environment. Approval classes D2/D3 remain human-gated.
