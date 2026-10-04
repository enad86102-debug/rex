# Incremental roadmap

Source: the master onboarding baseline supplied by Ammar on 2026-10-04.
This is an execution sequence, not a dated schedule, budget, or approval to
activate every listed feature. Each later mission must be explicitly scoped.

## Phase 0 — project context (current)

Inspect local state; create AGENTS.md and the project knowledge documents;
separate current constraints, recorded scope, deferrals, and undecided matters.
No application bootstrap, dependencies, gameplay, or provider selection.

Completion evidence: required documents exist, navigation links resolve, and
the actual workspace state is reported without invented Git/audit claims.

## Phase 1 — scoped engineering bootstrap

A later mission establishes the canonical repository/linkage and scopes
Flutter/Dart Android and Go setup. Resolve required toolchain/device decisions
using technical review and appropriate approval; add reproducible build/test
instructions. Select only infrastructure needed by the mission.

This phase is not authorized by the current onboarding task.

## Phase 2 — first game contract and focused design

Explicitly select the first game while preserving both Trix Complex and
Tarneeb in the recorded vision. Approve a versioned rules contract. Define
relevant server-authoritative boundaries, permitted player views, retries,
recovery, and meaningful rule tests before production implementation.

Do not assume competitor rules or build both games simultaneously.

## Phase 3 — complete first vertical slice

Prove the scoped flow:

Launch → Identity/guest access → Lobby → Table → Players → Match start →
Distribution → Turns → Complete game → Correct result → Reconnect/recovery →
Result → Replay/rematch → Invitation → Basic reporting → Analytics.

Each subsystem remains subject to its execution task. A polished lobby alone
is insufficient. Test legal/illegal actions, visibility boundaries, scores,
duplicate/retried actions, settlement, and reconnect where implemented.

## Phase 4 — measured Android reliability and quality

Validate Arabic/RTL, mixed names, responsive screens, lifecycle transitions,
poor networks, real-device performance, app size, battery/thermal/resource
use, and relevant security/privacy boundaries. Record actual results and debt;
do not fabricate budgets, metrics, or readiness claims.

## Phase 5 — controlled expansion

After the first complete game loop works, scope the next game and shared
platform capabilities progressively. Activate economy, content, social,
LiveOps, and administration only with their required integrity, safety, and
audit controls. Historical deferrals remain deferred until explicitly changed.

Release configuration, billing, ads, and voice require separate explicit tasks.
No delivery dates, staffing commitments, or commercial terms are set here.
