# REX Thousand-Audit Routing Protocol

## Reality boundary
1000 records are **bounded audit assignments**, not simultaneously running reviewers and not 1000 test scripts. Every entry begins NOT_RUN. A selected audit is only ASSIGNED_NOT_RUN until a real reviewer supplies evidence.

## Validate the index
```
python3 supervision/tools/audit_router.py --validate
python3 -m unittest discover -s supervision/tools -p 'test_*.py' -v
```

## Route edits without flooding the context
```
python3 supervision/tools/audit_router.py --paths production/server/internal/games/trixcomplex/engine.go --limit 12
python3 supervision/tools/audit_router.py --paths production/server/internal/api/api.go production/mobile/lib/controller.dart --limit 16 --json
```

## Review dispatch
1. Inspect real PR diff and select the exact changed files.
2. Route 8–16 checks (or none for docs-only edits); add mandatory rules, security, persistence, QA and Android reviewers when changes warrant.
3. Spawn only actual supported subagents, never invent an execution result. Running 1000 agents is not a goal.
4. Reviewers deliver file:line, exploit/repro or test command/output; record PASS/REQUEST_CHANGES/BLOCK and disagreements in a separate per-SHA report.
5. A skipped or irrelevant assignment is not a passed test. The registry never needs editing to claim execution.
6. Stop D2/D3 changes until reviewed by Abdulaziz or final founder authority as required.

For a proposed Trix match update, prioritize real game legality, opponent privacy, action idempotency, atomic save and four clients. For art updates, require physical Android performance, licensed source and human visual review.
