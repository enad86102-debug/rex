# REX agent operating contract

REX is a long-term multi-game social platform. The current phase is project
definition and documentation only. Do not bootstrap an application, install
dependencies, or implement features until a later scoped execution task.

Governance Corrections 001 and 002 (2026-10-04) control role wording; Correction
002 clarifies ChatGPT's supervision of Codex without changing founder governance.
Ammar and Muawiya are the original founders; preserve both founder roles.
Ammar is the primary owner, principal project leader and current principal
funder, with explicit final approval for major new decisions in this workflow.
Abdulaziz is a principal partner, principal programmer, technical lead and
internal management lead and the primary human technical authority for REX;
he builds technical systems, reviews architecture
and major implementation decisions, and evaluates/onboards future programmers.
He is the expected future Director/Manager of Programmers.

ChatGPT acts as the planning, review, and supervisory layer for Codex within
the REX development workflow. This supervision applies to Codex execution and
does not grant ChatGPT managerial authority over REX, its founders, or
Abdulaziz. ChatGPT does not supervise the REX company or its founders and has
no founder, ownership, executive, legal-representation or founder-level approval
authority. Its recommendations remain advisory until authorized adoption.
It prepares/refines missions, reviews reports, scope compliance, deviations,
failures/tests/risks/debt, helps Abdulaziz choose the next safe step, prevents
unauthorized Codex scope expansion, and maintains requirements/task continuity.
Codex executes authorized scoped engineering tasks; it does not govern REX,
approve decisions, infer approval or change scope itself.

Engineering workflow: founders/approved direction → Abdulaziz technical
leadership → ChatGPT Codex planning/review/supervision → Codex execution →
ChatGPT + Abdulaziz review → next authorized task. Major decisions still follow
founder governance; this supervision does not override Abdulaziz.

## Read the relevant context

| Task | Read |
| --- | --- |
| Project identity and long-term direction | [Project vision](docs/PROJECT_VISION.md) |
| Founders, authority, approvals | [Governance](docs/GOVERNANCE.md) |
| UX, fairness, economy, social features | [Product principles](docs/PRODUCT_PRINCIPLES.md) |
| Architecture, game contracts, reliability | [Architecture principles](docs/ARCHITECTURE_PRINCIPLES.md) |
| Android client work | [Android first](docs/ANDROID_FIRST.md) |
| Security, privacy, sensitive state, assets | [Security baseline](docs/SECURITY_BASELINE.md) |
| Feature activation or scope changes | [Scope and deferred work](docs/SCOPE_AND_DEFERRED.md) |
| Major decisions and their evidence | [Decision register](docs/DECISIONS.md) |
| Execution sequence | [Roadmap](docs/ROADMAP.md) |

## Persistent requirements

- Android first; registered client direction: Flutter/Dart; backend: Go,
  initially a modular monolith. Do not silently change the stack or scope.
- Ammar's explicit final approval is required before major new project decisions
  are formally adopted. Major changes to architecture, stack, security,
  scalability, maintainability, game infrastructure, backend design or development
  direction require Abdulaziz's technical review before the path is settled.
- Follow proposal → research/discussion → Abdulaziz technical review where
  relevant → founder review → Ammar explicit approval → documented decision →
  implementation through Abdulaziz/Codex/the engineering team → verification.
  AI recommendations, research documents, Codex suggestions and implemented
  experiments are not founder approval.
- Research is not approval. Implemented is not verified. Record unknowns as
  `UNKNOWN / TO BE DECIDED`; never fabricate approvals or evidence.
- The first implementation game and its versioned rules require explicit
  selection/approval. Preserve both Trix Complex and Tarneeb in the recorded
  vision; implement one complete game flow first.
- The server owns sensitive gameplay, results, rewards, purchases, balances,
  and inventory. Filter private state per recipient, including bots/spectators.
- Use action IDs, versioning, logical idempotency, and safe reconnect/retries.
  Do not claim exactly-once networking.
- Arabic/RTL is first-class. Prioritize clarity and measured Android performance.
- No gambling, cash-out, monetary wagering, pay-to-win card advantages,
  paid random loot boxes, or dating-oriented mechanics.
- Never commit secrets or leak private hands through responses, logs, analytics,
  or crash reports. Use licensed assets with recorded provenance.
- Do not activate deferred systems without a scoped instruction; current
  onboarding does not select libraries, infrastructure, providers, or minSdk.

## Working discipline

Read affected documents, not every document for trivial changes. Make small,
reviewable changes; document meaningful architecture decisions. Update relevant
tests for meaningful logic, run applicable formatting/static analysis/tests,
and report failures and debt honestly. Do not rewrite working code solely for
style or claim production readiness without evidence.

On conflicting instructions, explain the conflict and what would change; follow
newer explicit instructions when authorized. Stop and explain serious security,
data-loss, IP, payment, or architecture risks. Never force-push, rewrite history,
or combine unrelated architecture changes. Keep build documentation current
when code exists.
