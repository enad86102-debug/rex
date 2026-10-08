# Decision register

## Evidence and baseline

Source `SRC-001`: `REX — MASTER PROJECT ONBOARDING FOR CODEX`, provided by
Ammar on 2026-10-04. This supplied baseline establishes the current operating
constraints. Historical signatures, approval dates, and individual technical
review records were not supplied; do not invent them.

Source `SRC-002`: `REX — GOVERNANCE CORRECTION 001`, explicitly supplied by
Ammar on 2026-10-04. It corrects role descriptions and decision flow and
supersedes ambiguous earlier governance wording. It does not approve any
separate architecture, technology, feature or application implementation.

Source `SRC-003`: `REX — GOVERNANCE CORRECTION 002 — CODEX SUPERVISION ROLE`,
explicitly supplied by Ammar on 2026-10-04. It clarifies ChatGPT's planning,
review and supervision of Codex execution, superseding the blanket denial of
supervision in SRC-002. Founder governance and application scope are unchanged.

Registered baseline direction: Android first, Flutter/Dart client, Go backend,
initial modular monolith, server authority, versioned rules, and sequential
game delivery. These remain current constraints without manufacturing a
historical decision record.

## Approval and execution boundaries

Ammar and Muawiya are the original founders. Ammar is the primary owner,
principal project leader and current principal funder, with explicit final
approval of major new decisions in the current workflow. Muawiya's founder
status is preserved.

Abdulaziz is a principal partner, principal programmer, technical lead and
internal management lead and the primary human technical authority for REX.
His technical review is required before settling
major changes to architecture, stack, security, scalability, maintainability,
game infrastructure, backend design or development direction. His role also
includes building technical systems, future programmer evaluation/onboarding
and the expected future Director/Manager of Programmers role.

ChatGPT acts as the planning, review, and supervisory layer for Codex within
the REX development workflow. This supervision applies to Codex execution and
does not grant ChatGPT managerial authority over REX, its founders, or
Abdulaziz. ChatGPT does not supervise the REX company or its founders and has
no founder, ownership, executive, company-management, legal-representation
or founder-level approval authority. Recommendations remain advisory until
authorized adoption; Codex supervision does not override Abdulaziz.
Codex executes authorized scoped tasks without governing REX, approving
decisions, inferring founder approval or independently changing scope.

Engineering workflow: founders/approved direction → Abdulaziz technical
leadership → ChatGPT Codex planning/review/supervision → Codex execution →
ChatGPT + Abdulaziz review → next authorized task. Execution review checks
mission scope, deviations, reported failures/tests/risks/debt and continuity;
it supports Abdulaziz's next safe step and prevents unauthorized Codex scope
expansion. It does not substitute for founder approval or human technical review.

Proposal → research/discussion → Abdulaziz technical review where relevant →
founder review → Ammar explicit final approval → documented decision →
implementation through Abdulaziz/Codex/the engineering team → verification.

A ChatGPT recommendation, research document, Codex suggestion or implemented
experiment is never evidence of founder approval by itself.

## Status definitions

| Status | Meaning |
| --- | --- |
| PROPOSED | A concrete proposal exists; it is not adopted. |
| UNDER_REVIEW | Review has actually begun; approval is still pending. |
| APPROVED | Required approval evidence exists, including Ammar's explicit final approval for major new decisions and Abdulaziz's technical review where relevant; implementation may not exist. |
| IMPLEMENTED | The approved decision is represented in the project; verification is not implied. |
| VERIFIED | Relevant checks have succeeded and their evidence is recorded. |
| SUPERSEDED | A later recorded decision replaces it; preserve the old record and link the replacement. |

Typical progression is PROPOSED → UNDER_REVIEW → APPROVED → IMPLEMENTED →
VERIFIED. Do not advance a status without evidence. Keep the status history;
record SUPERSEDED with a replacement reference where applicable. An experiment
does not bypass review/approval or automatically qualify as an implemented
approved decision. Verification records checks, not AI approval authority.

## Major decision entries

No new major architecture or product decision is adopted by this onboarding.
No historical major-decision records have been reconstructed without evidence.

### REX-GOV-001 — Governance Correction 001

- Date: 2026-10-04.
- Topic: accurate project roles and approval/execution boundaries.
- Decision: apply the explicit supplied correction to repository documentation;
  preserve Ammar/Muawiya as original founders, Abdulaziz's partnership and
  technical/internal leadership, and the advisory/execution limits of AI tools.
- Status: VERIFIED (documentation correction only).
- Source / evidence: SRC-002, the user's explicit correction instruction.
- Technical impact: documentation only; no stack, architecture or code change.
- Scope impact: governance clarification only; onboarding remains documentation-only.
- Abdulaziz technical review: NOT RECORDED; no technical implementation path
  was selected or settled by this correction.
- Founder review: no separate review record supplied; do not infer one.
- Ammar approval: SRC-002 is explicit authorization to apply this governance
  correction only; it is not approval for other project decisions.
- Supersedes: ambiguous earlier role wording; no prior formal decision ID supplied.
- Superseded by: REX-GOV-002 for ChatGPT supervision wording only; founder
  roles, Abdulaziz's leadership and founder-level approval rules remain in force.
- Implementation evidence: AGENTS.md, GOVERNANCE.md, DECISIONS.md,
  PROJECT_VISION.md and ONBOARDING_REPORT.md updated for SRC-002.
- Verification evidence: 2026-10-04; all 11 Markdown documents inspected,
  32 internal links resolved, all five required files contain corrected roles,
  and a file-hash comparison confirmed only those five documents changed.
  No files were added/deleted. Wording-search results were explicit role
  denials or a clearly identified historical quotation, not authority claims.
- Status history: explicit correction received and documentation implemented
  on 2026-10-04, then verified through documentation checks on the same date;
  no historical signatures or review events reconstructed.

### REX-GOV-002 — Codex supervision clarification

- Date: 2026-10-04.
- Topic: separate Codex execution supervision from company governance.
- Decision: ChatGPT plans, reviews and supervises Codex execution within the
  development workflow, without governing REX, its founders or Abdulaziz.
  Abdulaziz remains the primary human technical authority; major decisions
  retain founder governance.
- Status: VERIFIED (documentation clarification only).
- Source / evidence: SRC-003, the user's explicit correction instruction.
- Technical impact: documentation only; no implementation path or stack change.
- Scope impact: workflow clarification only; application scope unchanged.
- Abdulaziz technical review: NOT RECORDED; this does not infer a technical
  review or settle any application implementation decision.
- Founder review: no separate review record supplied; do not infer one.
- Ammar approval: SRC-003 explicitly authorizes this clarification only.
- Supersedes: REX-GOV-001's blanket denial of ChatGPT supervision only.
- Superseded by: NONE.
- Implementation evidence: AGENTS.md, GOVERNANCE.md, DECISIONS.md and
  ONBOARDING_REPORT.md updated; PROJECT_VISION.md reconciled to avoid stale
  contradictory role wording.
- Verification evidence: 2026-10-04; all 11 Markdown documents and 32 internal
  links checked successfully. Canonical role wording exists in all five changed
  documents; all eight Codex-supervision responsibilities are present in
  GOVERNANCE.md. No stale blanket supervision denial remains. File hashes
  confirm changes only to the five named documents, with no added/deleted files.
- Status history: explicit correction received, implemented and verified through
  documentation checks on 2026-10-04. Verification does not grant AI governance
  or founder approval authority.

Use the following template for future concrete proposals:

```text
ID: REX-DEC-<number>
Date: YYYY-MM-DD
Topic:
Decision / concrete proposal:
Status: PROPOSED | UNDER_REVIEW | APPROVED | IMPLEMENTED | VERIFIED | SUPERSEDED
Source / evidence:
Technical impact:
Scope impact:
Abdulaziz technical review where relevant: NOT RECORDED / evidence reference
Founder review: NOT RECORDED / evidence reference
Ammar explicit final approval when required: NOT RECORDED / evidence reference
Supersedes decision: NONE / ID
Superseded by: NONE / ID
Implementation evidence:
Verification evidence:
Status history:
```

`NOT RECORDED` means evidence is unavailable; it does not imply approval or
rejection. Unknown choices are not automatically proposals or under review.

## Open decision queue

| ID | Topic | State / gate |
| --- | --- | --- |
| OPEN-001 | First implementation game | UNKNOWN / TO BE DECIDED; explicit selection. |
| OPEN-002 | Exact versioned rules | UNKNOWN / TO BE DECIDED; rules approval before production implementation. |
| OPEN-003 | Android API/device targets and budgets | UNKNOWN / TO BE DECIDED; engineering analysis and approval. |
| OPEN-004 | Toolchain versions, libraries, transport, persistence | UNKNOWN / TO BE DECIDED; scoped technical review. |
| OPEN-005 | Database/cloud/auth/analytics/ads/payments | UNKNOWN / TO BE DECIDED; outside current phase. |
| OPEN-006 | Remote repository and local Git linkage | VERIFIED / IMPLEMENTED; `https://github.com/enad86102-debug/rex.git` is configured as `origin` and `main` is pushed. |
| OPEN-007 | Incorporation and commercial/legal terms | UNKNOWN / TO BE DECIDED; no software-development dependency. |

These IDs track questions, not approved decisions. Convert an item into a
decision entry only when a concrete proposal is made. Major technical changes
need Abdulaziz's technical review before the path is settled, founder review
and Ammar's explicit final approval under [governance](GOVERNANCE.md).
