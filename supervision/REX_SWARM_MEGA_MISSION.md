# REX — Codex Cloud Swarm Mega Mission (production-focused)

## Purpose
Deliver the maximum feasible amount of **real working code** toward a full, verified Android REX V1.0, not a shell demo or thousand-page report. Keep the work honest and resumable across cloud tasks. The supervisor toolkit is a decision/routing layer and does not run automatically.

## Mandatory Cloud environment preflight (before development task)
The Codex Cloud environment must be configured by an authorized user and prepared before production work. See `supervision/cloud/CLOUD_ACCESS_AND_SETUP.md`, `REX_CLOUD_PROFILE.json`, `REX_ACCESS_MATRIX.json` and `CODEX_CLOUD_PREFLIGHT_PROMPT.md`. Inventory Go 1.27.2, Flutter 3.35.7, Java 17 and Android SDK 36; use `setup_rex_cloud.sh --profile android --check` and `cloud_doctor.py`. Enable narrowly scoped GitHub repository/PR/Actions access and official dependency-host network access through the actual Codex environment UI. Do not insert credentials into files or claim this blueprint automatically grants permissions. Preserve release signing and production access for human operators. Cloud runtime and full product readiness are distinct statuses.

## Source of truth
- Inspect actual PR heads and CI first.
- Swarm instructions: `supervision/REX_SWARM_CHARTER.md`, `REX_SWARM_WORKBENCH.md`.
- 1000 review assignments: `supervision/SWARM_AUDITS_1000.json` and `AUDIT_EXECUTION_PROTOCOL.md`.
- 34 skills: root `.agents/skills/`, including `$rex-thousand-audit-dispatch`, `$rex-external-skill-guard`, `$rex-go-engine`, `$rex-match-privacy`.
- Source research: `SWARM_EXTERNAL_SOURCES.json` for references; no auto-install unverified external skill scripts.
- Production runtime: `production/swarm-reviewed-recovery` or latest reviewed descendant, NOT old main branch.

## Work decomposition
Use up to 3 nonoverlapping source-edit streams (CORE / ANDROID / ART) and up to 4 genuinely spawned specialist reviewers when runtime supports it. 1000 assignments are a selection pool. Choose up to 16 checks relevant to changed files, then add mandatory risk reviewers. Keep each reviewer read-only unless assigned exclusive files.

### CORE
1. Review existing Trix candidate and tests rather than reimplementing them.
2. Produce exact human decision packet for remaining regional Trix rules and legal fixtures. Do not invent approvals.
3. Build safe match integration seams behind disabled rule gate while D2 transaction/realtime choices await Abdulaziz.
4. Implement real atomic action+receipt+event+state once technical review is recorded; run crash/retry tests.
5. After rules approval, run actual four-player Trix match, full eight deals, score settlement, disconnect/reconnect/replay and privacy.
6. Preserve Tarneeb as required V1 game; obtain separate rules contract, then implement genuine engine and E2E.

### ANDROID
1. Use production/mobile and existing secure vault; render actual server data only.
2. Implement real hand, legal move, active turn, contract, points and results once match API exists.
3. Test two ambiguous repeated sends, force-stop, stale state and connection recovery.
4. Run Flutter analyze/test/build and real-device integration where available; record device details.

### ART
1. Use actual REX royal concept art as references, do not bake a full screenshot into interactive scene.
2. Source or create licensed editable art with UV/PBR/rig/animation/GLB; source/rights/human approval matter.
3. Evaluate renderer with real Android performance and Abdulaziz technical review.
4. Produce integrated coherent Royal Hall + four-seat table as production reference, then other locations/skins.

### OPERATIONS
1. Strengthen player account recovery, support/moderation, safe rollback, real match storage backup and observability.
2. Realistic live match load and abuse/failure tests, no claims of millions from waiting-room pressure tests.
3. Signed Play-ready AAB only after real user flow and human legal/visual/launch signoffs.

## Mandatory execution loop
A. Select smallest high-value unblocked implementation unit with exact acceptance test.
B. Spawn actual reviewers (or disclose sequential role checks) to independently inspect code and tests.
C. Use audit router `--paths` on changed paths, cap 8–16 assignments.
D. Implement source code, not a documentation-only result; tests first where possible.
E. Run unit, race, fuzz, integration, Android and relevant security/asset validators; report commands/results and skipped checks.
F. Review critical failures and dissent, fix, retest, open PR. Do not auto-merge/publish.
G. Return comprehensive Arabic supervisor report: feature status, PR graph, actual playable device state, exact evidence, audit IDs executed, introduced dependencies, art source rights, blockers, rollback and next task.

## Hard stop rules
- Trix 0.9-draft is not approved; public `/start` must not be enabled without actual human approval.
- PostgreSQL/SQLite choice, realtime transport, renderer, production network/auth architecture need Abdulaziz D2 technical review.
- Game variants, scope/payment/legal rights and public launch need required human approval.
- No false '1000 agents running', fabricated CI, fake online game, fake rigged model, or 'release ready' claim.

Begin the highest-value safe implementation immediately and continue in resumable scoped cloud tasks. One Codex run cannot truthfully promise to finish all product work or override required human decisions.
