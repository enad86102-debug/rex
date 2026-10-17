# REX SWARM — Current Review Board and First Work Orders
Evidence cutoff: 2026-10-17. **Not release approval.**
Source: existing GitHub PRs, actual code paths, and `production/docs/COMPREHENSIVE_SUPERVISOR_REPORT_2026-10-17.md` on documentation branch.

## Baselines
- Legacy main `1c6698b2d456252cda1b61526016214f95d83a2d`.
- Engineering production tip `production/connection-admission-hardening` / PR#11 @ `4e6f414e753c15783c0d5811a351838ef441c70b`.
- Later comprehensive documentation PR#12 @ `82304867a42097eb5bfc0841e247c89165e48a96` (branch atop #11).
- CI for #11: `39012654604` successful for four jobs. This proves tests in that run, not release readiness.
- PR dependencies: #1(base main) → #2 → #3 → #4 → #5 → #7 → #8 → #9 → #10 → #11 → #12. PR#6 is a separate report based on #5. Do not treat independent docs report as a required runtime merge.
- At audit all listed PRs were draft and open. Each is a diff against its immediate predecessor, **not** an independently mergeable branch against main without rebase/stack consideration.

## Verdicts
| Item | Supervisor result | Evidence or reason |
|---|---|---|
| Real guest identity/room/invitation/ready | VERIFIED_IN_SCOPE | Go+Flutter waiting room plus emulator smoke; not an actual gameplay match. |
| Candidate Go Trix engine | VERIFIED_IN_SCOPE as draft only | Go unit/race tests and internal replay; no approved gameplay rules, persistence or live API. |
| Public start | BLOCKED | `rules_not_approved` must remain until required human rule sign-offs. |
| Production persistence | BLOCKED | JSON whole-state atomic snapshot is single-process review adapter. |
| Online match transport | BLOCKED | Waiting-room polling is not a verified real-time match protocol. |
| Cinematic production art | BLOCKED | Guide-only GLBs not rigged/release-approved, and independent environments absent. |
| Tarneeb | NOT IMPLEMENTED; REQUIRED_TARGET | Keep separate V1 module & rules contract. |
| Play release | BLOCKED | Missing real multi-client matches, signed AAB, approved art, security/ops/device validation. |

## Priority board and owner/reviewer routing
**P0-A Human rules input**: Trix 0.9.0-draft open decisions: seat order, leader, queen/king rules, doubles, redeal, ties, timeouts/reconnect. Rules Custodian writes decision matrix and fixture examples; Go Engine and QA review. Owner is human founder for final rule variant; technical review by Abdulaziz. Do not alter live rules gate without evidence.

**P0-B Atomic match-state design review**: Storage and Security jointly assess options against exactly-one durable action/state/receipt/event transaction, per-seat privacy and failure injection. Networking reviews protocol coupling; Skeptic ensures one smallest viable transport/store. This is D2: propose tradeoffs and migration, do not silently adopt provider/stack.

**P0-C Complete-real-match integration after gates**: Go Engine + Networking implement authorized rules match lifecycle; Security checks auth/seat scope; QA runs four independent client match completion and kill/restart/resume; Android reviewer validates real user journey. No fabricated matchmaking or results.

**P0-D Professional art intake (parallel nonblocking engineering)**: Art lead prepares source/provenance/rig/UV/PBR/animation checklist and 2D/3D renderer comparison for Abdulaziz. Do not promote a GLB validator pass to production art or create a fake "final" character.

**P1-A PR chain stabilization**: QA + Skeptic inventory each stacked PR diff, blockers, fast regression and stale merges, then propose bottom-up merge/rebase sequence after authorized review. Do not merge drafts or rewrite history on supervisor initiative.

**P1-B Tarneeb rule contracting**: Rules Custodian records precise bidding/trick/scoring variants requiring human input, then prepare separate Tarneeb engine once approved.

**P1-C Android and service readiness**: Android/SRE run real-device flows, connection recovery, secure storage, load measured against actual matches, release/signing readiness; never infer global scale from a 4,096-request waiting-room stress test.

## Swarm task packet template
```yaml
id: REX-SW-YYYY-NNN
class: D0 | D1 | D2 | D3
base_branch: ...
base_sha: ...
owner_role: SW-...
reviewers: [SW-..., SW-..., SW-11]
product_value: ...
approved_scope: ...
forbidden_scope: ...
human_decisions_required: []
acceptance_tests: []
security_and_privacy_invariants: []
expected_artifacts: []
rollback: ...
```

## Reviewer report template
```md
## SW-XX review for [task / commit / PR]
Verdict: PASS | REQUEST_CHANGES | BLOCK
Base SHA: ...
Changed files inspected: ...
Critical findings (file:line, impact, reproduction):
Tests run (exact command; result; environment):
Unknown or unverified:
Human approvals still required:
Smallest next corrective action:
```

## First Codex Cloud orchestration directive
Read this board and `supervision/REX_SWARM_CHARTER.md` in its branch plus current production code. Establish a review-only, independent **multi-role audit** on existing stacked PRs and the Trix draft. Simulate multiple reviewers only if the environment lacks true subagent spawning, disclose the distinction, and produce separate reviewer records with evidence. The immediate result should be: 1) bottom-up PR disposition matrix; 2) real gap between Trix candidate and end-to-end authoritative play; 3) storage/network decision brief for Abdulaziz; 4) human Trix rule-approval sheet; 5) one smallest authorized D0/D1 code fix with regression tests if truly justified. Do not modify game rules, deploy, merge, or assert release readiness. Do not spend cycles gathering another broad 1,548-repository catalogue.
