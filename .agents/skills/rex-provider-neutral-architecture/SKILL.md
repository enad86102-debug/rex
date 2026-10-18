---
name: rex-provider-neutral-architecture
description: "Review whether proposed backend/hosting/renderer dependencies reduce risk without locking REX prematurely. Use for the relevant REX source changes or review."
---

# rex-provider-neutral-architecture

## Scope
Review whether proposed backend/hosting/renderer dependencies reduce risk without locking REX prematurely.

## Work procedure
1. Demand a concrete performance/security/maintenance pain point before provider selection.
2. Document smallest viable baseline and at least one alternative with migration/rollback.
3. Require Abdulaziz review for D2 transaction store, real-time transport and renderer decisions.
4. Do not silently install Kubernetes, distributed DB, paid SaaS or a game engine.
5. Propose measurable tests and real operator cost estimate for later approval.

## Sources to consult, not auto-execute
- [go-security](https://go.dev/doc/security/best-practices) — research reference, not a runtime dependency
- [openai-multiagent](https://developers.openai.com/api/docs/guides/agents-api/multi-agent) — research reference, not a runtime dependency

## Evidence contract
Report actual source SHA, inspected paths and lines, exact tests (or NOT_RUN), security implications, reviewer dissent, and one of PASS / REQUEST_CHANGES / BLOCK. The tool or external skill must not be claimed installed unless actually verified in the active environment. Approval classes D2/D3 remain human-gated.
