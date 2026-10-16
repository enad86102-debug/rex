#!/usr/bin/env bash
# Four real Flutter transports against an isolated Go process. No Android claim.
set -euo pipefail
rex_root="$(cd "$(dirname "$0")/../.." && pwd)"
rex_temp="$(mktemp -d)"
rex_server_pid=""
cleanup() {
  if [[ -n "$rex_server_pid" ]]; then
    kill "$rex_server_pid" 2>/dev/null || true
    wait "$rex_server_pid" 2>/dev/null || true
  fi
  rm -rf "$rex_temp"
}
trap cleanup EXIT
cd "$rex_root/production/server"
go build -trimpath -o "$rex_temp/rexd" ./cmd/rexd
REX_SERVER_BINARY="$rex_temp/rexd" python3 "$rex_root/production/tools/test_server_process.py"
REX_STORE="$rex_temp/state.json" REX_LISTEN=127.0.0.1:18081 "$rex_temp/rexd" >"$rex_temp/server.log" 2>&1 &
rex_server_pid=$!
for ((attempt=0; attempt<50; attempt++)); do
  if curl --noproxy '*' -fsS http://127.0.0.1:18081/healthz >/dev/null 2>&1; then break; fi
  if ! kill -0 "$rex_server_pid" 2>/dev/null; then cat "$rex_temp/server.log"; exit 1; fi
  sleep 0.1
done
curl --noproxy '*' -fsS http://127.0.0.1:18081/healthz >/dev/null
cd "$rex_root/production/mobile"
REX_TEST_SERVER_URL=http://127.0.0.1:18081 flutter test test/live_server_test.dart --reporter expanded
