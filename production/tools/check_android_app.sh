#!/usr/bin/env bash
# Smoke-test the actual production/mobile debug application on an already
# booted, isolated API 36 emulator. This does not approve release gameplay.
set -euo pipefail

rex_root="$(cd "$(dirname "$0")/../.." && pwd)"
rex_device="${REX_ANDROID_DEVICE:-emulator-5554}"
rex_package="dev.rex.internal.rex_production"
rex_apk="$rex_root/production/mobile/build/app/outputs/flutter-apk/app-debug.apk"
rex_screenshot="${REX_ANDROID_SCREENSHOT:-/tmp/rex-android-home.png}"

test -s "$rex_apk"
adb -s "$rex_device" install -r "$rex_apk" >/dev/null
adb -s "$rex_device" shell pm path "$rex_package" | grep -Fq 'package:'
adb -s "$rex_device" shell am force-stop "$rex_package"
adb -s "$rex_device" shell am start -W -n "$rex_package/.MainActivity" | grep -Fq 'Status: ok'

# A live process alone can show only the launch splash. Require the Arabic
# guest-entry control in Android's accessibility tree after Flutter renders.
rex_rendered=false
for ((rex_attempt=0; rex_attempt<12; rex_attempt++)); do
  if adb -s "$rex_device" shell uiautomator dump /sdcard/rex-app-smoke.xml >/dev/null 2>&1 &&
    adb -s "$rex_device" exec-out cat /sdcard/rex-app-smoke.xml | grep -F 'الدخول كضيف' >/dev/null; then
    rex_rendered=true
    break
  fi
  sleep 1
done
if [[ "$rex_rendered" != true ]]; then
  echo 'Production app installed but Arabic guest-entry UI was not rendered.' >&2
  exit 1
fi
adb -s "$rex_device" shell pidof "$rex_package" >/dev/null
adb -s "$rex_device" exec-out screencap -p > "$rex_screenshot"
test -s "$rex_screenshot"
echo 'Production debug APK installed, launched, and rendered Arabic guest entry on Android emulator.'
