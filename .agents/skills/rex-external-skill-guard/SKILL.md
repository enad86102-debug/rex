---
name: rex-external-skill-guard
description: "Vet internet-hosted Agent Skills before any Codex installation or script execution. Use for the relevant REX source changes or review."
---

# rex-external-skill-guard

## Scope
Vet internet-hosted Agent Skills before any Codex installation or script execution.

## Work procedure
1. Confirm exact upstream owner, HTTPS URL, immutable commit hash and individual license.
2. Inspect SKILL.md and all linked scripts for network, filesystem, shell, secrets and installation behavior.
3. Prefer adapting documented principles into original REX instructions without copying executable third-party code.
4. Use the source registry and mark discovery, review, installation and test statuses independently.
5. Deny auto-run, uncontrolled curl pipe bash, token exfiltration and repo edits outside authorized scope.

## Sources to consult, not auto-execute
- [agent-skills-spec](https://agentskills.io/specification) — research reference, not a runtime dependency
- [anthropic-skill-creator](https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md) — research reference, not a runtime dependency
- [google-gemini-skills-guide](https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/skills-best-practices.md) — research reference, not a runtime dependency

## Evidence contract
Report actual source SHA, inspected paths and lines, exact tests (or NOT_RUN), security implications, reviewer dissent, and one of PASS / REQUEST_CHANGES / BLOCK. The tool or external skill must not be claimed installed unless actually verified in the active environment. Approval classes D2/D3 remain human-gated.
