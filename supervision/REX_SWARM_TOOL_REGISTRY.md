# REX — Tools and Skills Registry

Tool registration is not installation. Installed does not mean executed, and executed does not mean approved. All external source code and third-party skills must undergo license/security review before use.

| Domain | Tools/capabilities | Purpose | Guardrail |
|---|---|---|---|
| GitHub and Codex | Git, PRs, Actions, Codex Cloud, repo-local SKILL.md | code work, review, CI, subagents if supported | no default merge/deploy or invented subagents |
| Go game/server | Go, gofmt, go test -race, fuzz, go vet | match correctness, state | match version, per-seat privacy |
| Go security | staticcheck, gosec, govulncheck, gitleaks | static/secret checks | pinned compatible tools; no 100%-safe claims |
| Flutter Android | Flutter/Dart, Android SDK, JDK/Gradle, adb/emulator | real app and secure storage | distinguish emulator and device |
| API | Go HTTP tests, OWASP API checklist; ZAP candidate | object/field auth and fuzz | ZAP only in isolated authorized test environment |
| Match persistence | transactional DB evaluation (PostgreSQL or SQLite candidates) | action/event/receipt atomicity | Abdulaziz technical approval before adoption |
| Realtime | WebSocket or alternative protocol candidate | ordered match events | protocol approval and actual reconnect tests |
| Art | Blender, licensed source, Khronos glTF validator | meshes, rigs, UV/PBR/animation validation | guide-only models cannot be shipped as final art |
| Asset optimization | glTF Transform, meshoptimizer candidates | lower device memory and jank | license/compatibility review |
| Load/chaos | existing rexpressure, k6 and Toxiproxy candidates | realistic server pressure | no millions-of-users claims from lobby test |
| Mobile QA | Flutter tests, Android Lint, MobSF/Patrol candidates | security, lifecycle, release | install only when missing capability demonstrated |
| Infra | Docker, backups, readiness and rollback | real operations | no public production deploy without approval |
| Reporting | Python stdlib policy checker, Markdown, JSON | reproducible evidence | checks validate docs only, not game quality |

Before enabling any new tool: verify exact gap, trusted publisher/source, license, pinned version, required privileges, secrets boundary, smoke result, rollback, and CI cost. Avoid copying random GitHub skill scripts from the 1,548-repository research metadata. Credentials live outside Git.

Skill discovery: repository-local `.agents/skills` may be read by Codex; if Cloud does not discover, open the relevant SKILL.md manually. A skill is an instruction workflow; it does not create access to Blender, Android phones, private services, external model APIs or accounts.
