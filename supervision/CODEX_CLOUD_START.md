# REX Codex Cloud — Swarm Launch Instructions

This is the human-initiated launch packet. Repository files do not autonomously schedule Codex runs or provision any agents.

1. Open Codex Cloud for the GitHub repository `enad86102-debug/rex`.
2. Inspect the toolkit in branch `supervision/rex-swarm-control`: `supervision/REX_SWARM_WORKBENCH.md`, `supervision/REX_SWARM_PRODUCTION_MISSION.md`, root `.agents/skills/`.
3. Inspect actual latest Go/Flutter production code on `production/swarm-reviewed-recovery` (or latest reviewed successor), not `main`. Verify base SHA, PR#14 and CI anew.
4. Create an isolated implementation branch from the reviewed production tip. Bring the approved toolkit files to that branch without rewriting Git history; if the Codex environment can't read across branches, fetch them explicitly and document the inability.
5. Validate and route the 1000 registered audit assignments with `python3 supervision/tools/audit_router.py --validate` and `--paths <actual changed files> --limit 12`; do not spawn 1000 agents or claim 1000 checks passed.
6. Invoke `$rex-orchestrate` and `$rex-thousand-audit-dispatch`; delegate separate read-only specialist reviews where real subagents are supported. Use up to four reviewers, not eighteen agents editing the same files. Delegate Go engine, storage/security, Android and art/toolchain as applicable.
7. Start actual D0/D1 source fixes or integration code that passes approval gates; no entire-product 'done' claim on one cloud run.
8. Run `python3 supervision/tools/swarm_check.py --root .` and `bash supervision/tools/run_checks.sh --all` on a branch that genuinely contains `production/server` and `production/mobile` plus necessary toolchains.
9. Provide a detailed report using `supervision/REX_SWARM_REPORT_TEMPLATE.md` and actual source changes / PR / CI evidence. Keep rule, storage, renderer and Play approvals blocked until recorded.
10. **Do not auto-merge, deploy publicly, enable payments or public matches, buy infrastructure, or treat a successful debug APK as a production game.**

One-line initiating instruction:

> Inspect REX swarm toolkit on supervision/rex-swarm-control and production Go/Flutter on the current stacked production branch. Act as orchestrator with independent specialists if supported; implement the highest-value safe source changes toward an authentic four-client card match, preserve approval gates, run tests, open reviewable PR and return a comprehensive evidence-backed report. Do not stop at documentation; do not fake completion.
