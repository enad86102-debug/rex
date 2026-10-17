#!/usr/bin/env bash
# Smoke-test the actual production/mobile debug application on an already
# booted, isolated API 36 emulator. This does not approve release gameplay.
set -euo pipefail

rex_root="$(cd "$(dirname "$0")/../.." && pwd)"
rex_device="${REX_ANDROID_DEVICE:-emulator-5554}"
rex_package="dev.rex.internal.rex_production"
rex_apk="$rex_root/production/mobile/build/app/outputs/flutter-apk/app-debug.apk"
rex_screenshot="${REX_ANDROID_SCREENSHOT:-/tmp/rex-android-home.png}"
rex_room_screenshot="${REX_ANDROID_ROOM_SCREENSHOT:-/tmp/rex-android-room.png}"
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

# The default debug endpoint is 10.0.2.2:8080. Use an isolated, disposable
# local service so the installed app can complete real guest and table calls.
cd "$rex_root/production/server"
go build -trimpath -o "$rex_temp/rexd" ./cmd/rexd
REX_LISTEN=127.0.0.1:8080 REX_STORE="$rex_temp/state.json" "$rex_temp/rexd" >"$rex_temp/server.log" 2>&1 &
rex_server_pid=$!
for ((rex_attempt=0; rex_attempt<50; rex_attempt++)); do
  if curl --noproxy '*' -fsS http://127.0.0.1:8080/healthz >/dev/null 2>&1; then break; fi
  if ! kill -0 "$rex_server_pid" 2>/dev/null; then
    echo 'Isolated REX service exited before Android smoke test.' >&2
    exit 1
  fi
  sleep 0.1
done
curl --noproxy '*' -fsS http://127.0.0.1:8080/healthz >/dev/null

rex_find_text() {
  local rex_target="$1"
  local rex_coordinates=""
  for ((rex_attempt=0; rex_attempt<12; rex_attempt++)); do
    if adb -s "$rex_device" shell uiautomator dump /sdcard/rex-app-smoke.xml >/dev/null 2>&1; then
      adb -s "$rex_device" exec-out cat /sdcard/rex-app-smoke.xml > "$rex_temp/ui.xml"
      rex_coordinates="$(python3 - "$rex_temp/ui.xml" "$rex_target" <<'PY'
import re
import sys
from xml.etree import ElementTree

root = ElementTree.parse(sys.argv[1]).getroot()
for node in root.iter('node'):
    label = node.attrib.get('text', '') + ' ' + node.attrib.get('content-desc', '')
    if sys.argv[2] not in label:
        continue
    bounds = re.fullmatch(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', node.attrib.get('bounds', ''))
    if bounds:
        left, top, right, bottom = map(int, bounds.groups())
        print((left + right) // 2, (top + bottom) // 2)
        break
else:
    raise SystemExit(1)
PY
)" && {
        printf '%s\n' "$rex_coordinates"
        return 0
      }
    fi
    sleep 1
  done
  echo "Android UI did not render expected control: $rex_target" >&2
  return 1
}

rex_tap_text() {
  local rex_x rex_y rex_coordinates
  rex_coordinates="$(rex_find_text "$1")"
  read -r rex_x rex_y <<< "$rex_coordinates"
  adb -s "$rex_device" shell input tap "$rex_x" "$rex_y"
}

test -s "$rex_apk"
adb -s "$rex_device" install -r "$rex_apk" >/dev/null
adb -s "$rex_device" shell pm path "$rex_package" | grep -Fq 'package:'
adb -s "$rex_device" shell am force-stop "$rex_package"
adb -s "$rex_device" shell am start -W -n "$rex_package/.MainActivity" | grep -Fq 'Status: ok'

# A live process alone can show only the launch splash. Require rendered
# controls, then exercise the real guest and table flow through Android taps.
rex_find_text 'الدخول كضيف' >/dev/null
adb -s "$rex_device" shell pidof "$rex_package" >/dev/null
adb -s "$rex_device" exec-out screencap -p > "$rex_screenshot"
test -s "$rex_screenshot"
rex_tap_text 'الدخول كضيف'
rex_find_text 'إنشاء طاولة' >/dev/null
rex_tap_text 'إنشاء طاولة'
rex_find_text 'الشمال' >/dev/null
adb -s "$rex_device" exec-out screencap -p > "$rex_room_screenshot"
test -s "$rex_room_screenshot"
echo 'Production debug APK installed, launched, entered as guest, and created a server-backed table on Android emulator.'
