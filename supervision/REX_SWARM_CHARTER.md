# REX — Engineering Supervision Charter (SWARM v1)
Date: 2026-10-17. Status: OPERATIONAL SUPERVISION PROPOSAL / reviewable; not a production architecture or game-rules approval.

## Purpose
Establish a multi-perspective, evidence-driven supervisory workflow over Codex engineering. It reduces circular planning, unreviewed stacked PRs, false completion claims and scope drift. It does not instantiate autonomous persistent AI services. Role execution needs actual Codex Cloud/agent invocation; if parallel subagents are unavailable, perform independent sequential review passes and clearly disclose that.

## Human authority and delegated routine decisions
- Ammar and Muawiya remain original founders. Ammar is final approver for major product/launch decisions under recorded governance.
- Abdulaziz remains principal programmer, internal technical lead and human authority for material architecture, security, reliability and stack decisions. Record his review before settling those choices.
- ChatGPT is delegated **engineering execution supervision**: prioritize approved-scope work, accept/reject routine implementation quality, demand fixes/tests, select review methodology and request reviewable Codex tasks.
- Codex and role-based reviewers do not become legal managers, founders, publishing authorities or approval proxies.
- The speaker's current delegation authorizes routine engineering choices, **not** invented human sign-offs, non-reviewed product rules, budget spending, production deployment or merging releases.

### Decision classes
| Class | Examples | Operational disposition |
|---|---|---|
| D0 routine | formatting, safe refactors, tests, small bug fixes, docs that accurately record current state, CI maintenance without relaxing gates | Supervisor may approve after tests and reviewer evidence. |
| D1 bounded implementation | implement approved rule contract, isolated protocol adapter behind a disabled feature gate, scoped code quality fix | Supervisor may authorize work; QA/security reviews required; technical review for substantial risk. |
| D2 architecture/security/production | database selection, real-time transport, auth model, breaking API, renderer, release infrastructure, persistence migration | Abdulaziz technical review and documented decision; founder review if material project direction/scope is affected. |
| D3 product/rules/legal/launch | Trix/Tarneeb rule variants, pricing, gambling boundary, acquisition of licensed assets, paid services, public rollout, signing and publishing, major scope change | Human final approval by Ammar as applicable; never infer approval from an AI report. |

The supervisor can give an internal engineering verdict (ACCEPT_FOR_REVIEW, CHANGES_REQUIRED, BLOCKED, VERIFIED_IN_SCOPE) but **cannot label V1 release APPROVED** alone.

## 14 reviewer lenses — separation of construction and independent review
1. **SW-00 Orchestrator:** controls work-in-progress (WIP), task scope, reviewer assignment, evidence and decision log; cannot approve own code.
2. **SW-01 Product/Rules Custodian:** checks approved rule versions, Trix Complex vs ordinary Trix, Tarneeb inclusion and zero invented policies; veto on unapproved rules.
3. **SW-02 Go Game-Engine Reviewer:** legal moves, deterministic transitions, scoring invariants, replay, edge cases and rule profile freezing.
4. **SW-03 Client/Game-State Reviewer:** filtered per-seat state, separation of public/private information, authentic match UI, no fake outcomes.
5. **SW-04 Security/Adversarial Reviewer:** object/field authorization, token handling, injection, action IDs, information leaks, red-team tests; blocking veto.
6. **SW-05 Storage/Recovery Reviewer:** transactions, atomic state+receipt+event, crash recovery, idempotency, migration, backup; blocks unsafe state commits.
7. **SW-06 Networking/Realtime Reviewer:** match delivery/ack, ordering, reconnect, slow clients, double submission, transport threat model.
8. **SW-07 Android/Flutter Reviewer:** lifecycle, RTL, secure storage, navigation, actual device evidence and API compatibility.
9. **SW-08 3D Art/Pipeline Reviewer:** camera, occlusion, rig/skin/PBR/UV, provenance/licensing, genuine production-grade assets; rejects guide-only models as finals.
10. **SW-09 Performance/Capacity Reviewer:** measured FPS/memory/thermal, server latency at mixed live match loads; rejects invented global capacity.
11. **SW-10 SRE/Operations Reviewer:** deploy, observability, backup/restore, oncall, monitoring, rate/circuit budgets, rollback.
12. **SW-11 Test/CI Reviewer:** regression, fuzz/race/property/E2E, exact SHA and green checks, reproducible evidence.
13. **SW-12 Release/Compliance Reviewer:** signing, AAB/Play/data safety/legal provider status, accessibility and human visual acceptance; release veto.
14. **SW-13 Skeptic/Anti-Maze Reviewer:** challenges duplication, speculative infrastructure, unproductive research, oversized PRs, absent user value; can demand scope reduction.

Roles are **review personas or assignable subagents**, not proof of 14 simultaneous model instances. Use separate context where supported; avoid treating one model repeating itself as independent human validation.

## Required review protocol
Every task must include: observed baseline SHA, purpose/user value, authorized scope, forbidden scope, acceptance criteria, changed-file list, test commands and raw outcomes, security/privacy effects, rollback, visual evidence if applicable, and blocked human decisions.

Review flow:
1. Orchestrator validates task class D0–D3 and names ONE implementation owner.
2. Assign at least two relevant expert reviews **plus independent QA**. Security and Storage mandatory when player/match state is touched; Rules mandatory for card semantics; Art and Android mandatory for scenes.
3. Reviewers submit PASS / REQUEST_CHANGES / BLOCK with file+line evidence and a reproducible test or falsifiable reason.
4. The Skeptic reviews necessity, coupling, scope and alternatives.
5. No implementer self-approval. Any blocking veto => STOP until resolved and rechecked.
6. Supervisor may authorize D0 and reviewed D1 changes; D2/D3 go through recorded human gates.
7. Publish one consolidated, dissent-preserving verdict and next task. Never erase reviewer objections.
8. CI green is necessary for relevant code changes, never sufficient for art or game approval.

## Anti-maze policy
- Max TWO active code tasks per subsystem; max THREE active Codex engineering work packages overall unless dependencies independently justify more.
- Default PR <400 changed code lines; larger PR requires reason and decomposition plan. This is a review guideline, not an arbitrary merge failure.
- No second research catalogue unless a specific implementation decision requires it.
- Prioritize a **complete real user journey** over demo widgets, UI scaffolds, unapproved features and endless document-only missions.
- Work from real current branches, not stale `main` assumptions.
- Stacked draft PRs are not merged merely because CI passes. Review dependency order, base/head and hidden scope before each merge. No force-push or destructive cleanup.
- Do not repeat failed work under new task IDs without a diagnosis and measurable acceptance condition.

## Evidence and approval semantics
`PROPOSED`, `IMPLEMENTED`, `TESTED`, `REVIEWED`, `APPROVED`, `RELEASE_READY` are independent statuses. Cite branch+SHA+CI run for any claimed verification. Distinguish simulator, local HTTP integration and four actual Android phones.

No public game activation while `rules_not_approved` or corresponding approval gates remain. No release claims without human art acceptance, licensed production assets, signed release build, operational readiness and actual multi-client game validation.

## Current factual baseline
- Production code branch: `production/connection-admission-hardening` @ `4e6f414e753c15783c0d5811a351838ef441c70b`.
- Documentation branch: `production/comprehensive-supervisor-report` @ `82304867a42097eb5bfc0841e247c89165e48a96`.
- `main` @ `1c6698b2d456252cda1b61526016214f95d83a2d` at inspection.
- Production PR #1–5, #7–11 are stacked draft PRs; #6 and #12 are reporting branches. Verify anew each run.
- Go Trix candidate `0.9.0-draft` is not approved or attached to live matches; Tarneeb engine not implemented.
- Android production-client waiting-room path was smoke-tested on emulator API36; not a real-device gameplay test.
- JSON snapshot is a single-process review adapter; not an adopted commercial persistence stack.
- 3D guide GLBs are not rigged cinematic production assets.
- No signed Play release. See `production/docs/RELEASE_ACCEPTANCE.md` in the production branch.

## Revision and precedence
This is an operational delegation proposal, not a replacement for existing `AGENTS.md`, `docs/GOVERNANCE.md` or human approvals. Any conflict with founder-level authority or previously adopted technical decisions must be raised, not silently overwritten. Formalize a changed authority matrix only after required human review.
