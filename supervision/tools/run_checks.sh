#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MODE="${1:---policy}"
if [[ "${MODE}" != "--policy" && "${MODE}" != "--production" && "${MODE}" != "--all" ]]; then
  echo "Usage: bash supervision/tools/run_checks.sh [--policy|--production|--all]" >&2
  exit 2
fi
cd "$ROOT"
if [[ "$MODE" == "--policy" || "$MODE" == "--all" ]]; then
  python3 supervision/tools/swarm_check.py --root .
  python3 -m unittest discover -s supervision/tools -p 'test_*.py' -v
fi
if [[ "$MODE" == "--production" || "$MODE" == "--all" ]]; then
  if [[ ! -d production/server || ! -d production/mobile ]]; then
    echo "BLOCKED: checked-out branch does not contain production/server and production/mobile." >&2
    echo "Run on the appropriate production branch; a supervision-only branch does not prove runtime tests." >&2
    exit 2
  fi
  for x in go flutter; do
    if ! command -v "$x" >/dev/null 2>&1; then
      echo "BLOCKED: missing $x; no success claimed for unavailable tool." >&2
      exit 2
    fi
  done
  (cd production/server && go test -race ./... && go vet ./...)
  (cd production/mobile && flutter pub get && flutter analyze && flutter test && flutter build apk --debug)
fi
echo "PASS: selected checks actually executed. This is NOT production-release approval."
