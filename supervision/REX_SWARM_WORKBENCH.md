# REX Swarm — Engineering Workbench

**Goal:** REX V1.0 with true Trix Complex and Tarneeb, safe four-player live matches, production-grade art and actual Android release. This file is a task board, not a running cloud service.

## Observed baseline (recheck before editing)
- main: 1c6698b; production PR#11: 4e6f414, successful CI [39012654604](https://github.com/enad86102-debug/rex/actions/runs/39012654604).
- Production PR#14: `production/swarm-reviewed-recovery` at a77bc80, includes guest-session recovery and reported five real subagent reviews; inspect PR head and latest CI again.
- Legacy UI is not current production. Core Go candidate Trix engine is in production/server/internal/games/trixcomplex; `/start` remains rules_not_approved.
- Tarneeb not implemented, no production database/real-time protocol approved, no full online match and no licensed cinematic human 3D release assets.

## Execution dashboard
| Lane | Deliverable | Required gate | Owner skill | Independent checks |
|---|---|---|---|---|
| CORE | Draft Trix -> signed approved rules -> durable four-seat game lifecycle | D3 rules, D2 persistence/transport | rex-go-engine | rex-trix-acceptance, rex-match-privacy, rex-ci-qa |
| ANDROID | Real server-backed match hand, turn, score, reconnect | no fake match; backend accepted | rex-flutter-android | rex-api-security, rex-ci-qa |
| ART | Royal hall, tables, chairs, realistic skinned players, source files | rights, renderer D2, human visual review | rex-cinematic-assets | rex-graphics-performance, rex-toolchain-audit |
| OPERATIONS | Accounts, support, real load, release readiness | D2/D3 and published evidence | rex-operations-recovery | rex-release-supervisor, rex-api-security |

Three active implementation tasks maximum, up to four reviewers concurrently if genuinely supported; code owner writes, reviewers inspect independently. Never have multiple agents editing the same files simultaneously.

## Cloud environment foundation
- Platform setup and operator permissions: `supervision/cloud/CLOUD_ACCESS_AND_SETUP.md` and `REX_ACCESS_MATRIX.json`.
- Actual production CI toolchain: Go 1.27.2; Flutter 3.35.7; Java 17; Android SDK 36. Legacy Flutter version is separate.
- Opt-in tool installer: `bash supervision/cloud/setup_rex_cloud.sh --profile android --check`; no sudo, no license autoaccept, no secrets.
- Doctor: `python3 supervision/cloud/cloud_doctor.py --profile android --json`.
- Cloud setup tests: `python3 -m unittest discover -s supervision/cloud -p 'test_*.py' -v` and dedicated GitHub Actions check.
- Cloud tool access cannot be conferred via Git; human must connect repo, configure network/credentials and publish a reusable environment.

## Tooling
- Skills: `.agents/skills/<name>/SKILL.md` (35 focused workflows).
- Thousand-audit register: `supervision/SWARM_AUDITS_1000.json` (25 domains × 40 probes, all initially NOT_RUN). Select with `python3 supervision/tools/audit_router.py --paths <changed-file> --limit 12`.
- Internet research: `supervision/SWARM_EXTERNAL_SOURCES.json` (17 references, no untrusted external scripts installed).
- Tool inventory: `supervision/REX_SWARM_TOOL_REGISTRY.md`.
- Machine-readable queue: `supervision/SWARM_TASK_BOARD.json`.
- Repeatable checks: `python3 supervision/tools/swarm_check.py --root .` and `bash supervision/tools/run_checks.sh --policy`.
- Complete mission and quality gate: `supervision/REX_SWARM_PRODUCTION_MISSION.md`.
- Honest final report: `supervision/REX_SWARM_REPORT_TEMPLATE.md`.

## Status vocabulary
PROPOSED = proposed only; IMPLEMENTED = code present; TESTED = specified tests on SHA passed; REVIEWED = independent findings recorded; APPROVED = required humans signed; RELEASE_READY = end-to-end production gates actually closed.

**Do not inflate work:** a tested in-memory engine is not online gameplay, a structurally valid GLB is not a finished 3D character, and green CI is not a Google Play release.
