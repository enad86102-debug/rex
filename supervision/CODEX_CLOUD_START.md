# REX Codex Cloud — Swarm Launch Instructions

This is the human-initiated launch packet. Repository files do not autonomously schedule Codex runs or provision any agents.

1. Open Codex Cloud for the GitHub repository `enad86102-debug/rex`.
2. BEFORE the Mega Mission, prepare and test the real published Codex environment using `supervision/cloud/CLOUD_ACCESS_AND_SETUP.md` and `supervision/cloud/CODEX_CLOUD_PREFLIGHT_PROMPT.md`. A checked-in profile cannot grant permissions: user must connect GitHub, approve network settings and publish the environment; inspect actual toolchain and SDK status.
3. Inspect the toolkit in branch `supervision/rex-swarm-control`: `supervision/REX_SWARM_WORKBENCH.md`, `supervision/REX_SWARM_PRODUCTION_MISSION.md`, root `.agents/skills/`.
4. Inspect actual latest Go/Flutter production code on `production/swarm-reviewed-recovery` (or latest reviewed successor), not `main`. Verify base SHA, PR#14 and CI anew.
5. Create an isolated implementation branch from the reviewed production tip. Bring the approved toolkit files to that branch without rewriting Git history; if the Codex environment can't read across branches, fetch them explicitly and document the inability.
6. Validate and route the 1000 registered audit assignments with `python3 supervision/tools/audit_router.py --validate` and `--paths <actual changed files> --limit 12`; do not spawn 1000 agents or claim 1000 checks passed.
7. Invoke `$rex-orchestrate` and `$rex-thousand-audit-dispatch`; delegate separate read-only specialist reviews where real subagents are supported. Use up to four reviewers, not eighteen agents editing the same files. Delegate Go engine, storage/security, Android and art/toolchain as applicable.
8. Start actual D0/D1 source fixes or integration code that passes approval gates; no entire-product 'done' claim on one cloud run.
9. Run `python3 supervision/tools/swarm_check.py --root .` and `bash supervision/tools/run_checks.sh --all` on a branch that genuinely contains `production/server` and `production/mobile` plus necessary toolchains.
10. Provide a detailed report using `supervision/REX_SWARM_REPORT_TEMPLATE.md` and actual source changes / PR / CI evidence. Keep rule, storage, renderer and Play approvals blocked until recorded.
11. **Do not auto-merge, deploy publicly, enable payments or public matches, buy infrastructure, or treat a successful debug APK as a production game.**

One-line initiating instruction:

> Inspect REX swarm toolkit on supervision/rex-swarm-control and production Go/Flutter on the current stacked production branch. Act as orchestrator with independent specialists if supported; implement the highest-value safe source changes toward an authentic four-client card match, preserve approval gates, run tests, open reviewable PR and return a comprehensive evidence-backed report. Do not stop at documentation; do not fake completion.
