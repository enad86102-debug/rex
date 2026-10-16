#!/usr/bin/env bash
# Requires an already booted, isolated Android emulator. Does not accept licenses.
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
REX_LISTEN=127.0.0.1:18081 REX_STORE="$rex_temp/state.json" "$rex_temp/rexd" >"$rex_temp/server.log" 2>&1 &
rex_server_pid=$!
for ((attempt=0;attempt<50;attempt++)); do
  if curl --noproxy '*' -fsS http://127.0.0.1:18081/healthz >/dev/null 2>&1; then break; fi
  if ! kill -0 "$rex_server_pid" 2>/dev/null; then cat "$rex_temp/server.log"; exit 1; fi
  sleep 0.1
done
curl --noproxy '*' -fsS http://127.0.0.1:18081/healthz >/dev/null
cd "$rex_root/production/qa/android_harness"
flutter drive --driver=test_driver/integration_driver.dart \
  --target=integration_test/session_vault_test.dart --device-id emulator-5554 \
  --dart-define=REX_TEST_API_URL=http://10.0.2.2:18081 --keep-app-running
adb -s emulator-5554 shell run-as dev.rex.qa.native \
  cat shared_prefs/rex_session_vault.xml > "$rex_temp/vault.xml"
python3 - "$rex_temp/vault.xml" <<'PY'
from pathlib import Path
import sys
data=Path(sys.argv[1]).read_text()
assert 'rex-qa-public-persistence-marker' not in data, 'Plaintext marker leaked'
assert 'ciphertext' in data, 'Encrypted record missing; empty storage is not a pass'
print('Native encrypted preferences contain ciphertext and no plaintext QA marker.')
PY
adb -s emulator-5554 shell am force-stop dev.rex.qa.native
test -z "$(adb -s emulator-5554 shell pidof dev.rex.qa.native 2>/dev/null || true)"
flutter drive --driver=test_driver/integration_driver.dart \
  --target=integration_test/restart_vault_test.dart --device-id emulator-5554 \
  --dart-define=REX_TEST_API_URL=http://10.0.2.2:18081 --keep-app-running
adb -s emulator-5554 shell pm clear dev.rex.qa.native >/dev/null
