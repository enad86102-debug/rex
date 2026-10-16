#!/usr/bin/env bash
# Pinned development tools only; no AI-assisted scans or uploaded source code.
set -euo pipefail
rex_root="$(cd "$(dirname "$0")/../.." && pwd)"
rex_qa_bin="$(mktemp -d)"
trap 'rm -rf "$rex_qa_bin"' EXIT
GOBIN="$rex_qa_bin" go install github.com/securego/gosec/v2/cmd/gosec@v2.29.1-0.20261015133444-707f2271f665
GOBIN="$rex_qa_bin" go install honnef.co/go/tools/cmd/staticcheck@v0.8.2
GOBIN="$rex_qa_bin" go install github.com/zricethezav/gitleaks/v8@v8.30.1
cd "$rex_root/production/server"
"$rex_qa_bin/staticcheck" ./...
rex_gosec_status=0
"$rex_qa_bin/gosec" -fmt=json -out="$rex_qa_bin/gosec.json" ./... >"$rex_qa_bin/gosec.log" 2>&1 || rex_gosec_status=$?
python3 - "$rex_qa_bin/gosec.json" "$rex_gosec_status" <<'PY'
import json, sys
from pathlib import Path
report=json.loads(Path(sys.argv[1]).read_text())
errors=report.get('Golang errors') or {}
issues=report.get('Issues') or []
print(json.dumps({'gosec_stats':report.get('Stats'),'analysis_errors':len(errors),
                  'issues':[{'rule':i['rule_id'],'file':i['file'],'line':i['line']} for i in issues]}))
# Never call a skipped SSA/failed type check a clean security scan.
raise SystemExit(1 if int(sys.argv[2]) or errors or issues else 0)
PY
go run golang.org/x/vuln/cmd/govulncheck@v1.9.0 ./...
cd "$rex_root"
"$rex_qa_bin/gitleaks" git --redact --no-banner .
git diff HEAD | "$rex_qa_bin/gitleaks" stdin --redact --no-banner
