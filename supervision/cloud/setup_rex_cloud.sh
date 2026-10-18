#!/usr/bin/env bash
# REX Codex Cloud opt-in setup. No sudo, no implicit license agreement,
# no untrusted third-party installers, no repository deletion, no secrets.
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CACHE_ROOT="$HOME/.cache/rex-cloud"
GO_VERSION="1.27.2"
FLUTTER_VERSION="3.35.7"
INSTALL_GO=0
INSTALL_FLUTTER=0
INSTALL_ANDROID_PACKAGES=0
PREPARE_DEPS=0
PROFILE="core"
DRY_RUN=0

usage() {
  cat <<'HELP'
Usage: bash supervision/cloud/setup_rex_cloud.sh [options]
  --profile core|android|art   Select capability report (default: core)
  --check                      Run doctor only; no installs (default)
  --install-go                 Opt-in pinned Go 1.27.2 from go.dev with SHA256
  --install-flutter            Opt-in Flutter 3.35.7 git release checkout
  --android-packages           Opt-in Android SDK36 package installation via existing sdkmanager (preaccepted licenses only)
  --prepare-deps               Opt-in go mod download / flutter pub get (requires production branch and tools)
  --dry-run                    Explain selected work, don't install anything
  --help                       Show instructions
Commands never use sudo, modify system PATH, autoaccept Android licenses, or set credentials.
After optional installation, source "$HOME/.cache/rex-cloud/env.sh" in your shell.
HELP
}
while [ "$#" -gt 0 ]; do
  case "$1" in
    --profile) PROFILE="$2"; shift 2 ;;
    --check) shift ;;
    --install-go) INSTALL_GO=1; shift ;;
    --install-flutter) INSTALL_FLUTTER=1; shift ;;
    --android-packages) INSTALL_ANDROID_PACKAGES=1; shift ;;
    --prepare-deps) PREPARE_DEPS=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) echo "ERROR: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done
case "$PROFILE" in core|android|art) ;; *) echo "ERROR: unknown profile $PROFILE" >&2; exit 2 ;; esac
echo "REX cloud workspace: $ROOT"
echo "Profile: $PROFILE"
echo "Setup mode: Go=$INSTALL_GO Flutter=$INSTALL_FLUTTER Android=$INSTALL_ANDROID_PACKAGES deps=$PREPARE_DEPS dry-run=$DRY_RUN"
if [ "$DRY_RUN" -eq 1 ]; then
  echo "Dry run: nothing installed or altered."
  exit 0
fi
mkdir -p "$CACHE_ROOT"
# This shell fragment is not automatically sourced; user/environment must opt in.
cat > "$CACHE_ROOT/env.sh" <<EOF
# REX local cloud toolchain paths; contains NO secrets.
export PATH="$CACHE_ROOT/go-$GO_VERSION/bin:$CACHE_ROOT/flutter-$FLUTTER_VERSION/bin:\$PATH"
export PUB_CACHE="$CACHE_ROOT/pub-cache"
export GRADLE_USER_HOME="$CACHE_ROOT/gradle"
EOF
# Use installed pinned versions for this invocation when they already exist.
# shellcheck disable=SC1090
source "$CACHE_ROOT/env.sh"

install_go() {
  if command -v go >/dev/null 2>&1 && go version | grep -q "go$GO_VERSION "; then
    echo "Already available: Go $GO_VERSION"
    return
  fi
  [ "$(uname -s)" = "Linux" ] && [ "$(uname -m)" = "x86_64" ] || { echo "Go auto-install supports Linux x86_64 only" >&2; exit 3; }
  for command_name in curl sha256sum tar; do
    command -v "$command_name" >/dev/null 2>&1 || { echo "Missing $command_name" >&2; exit 3; }
  done
  target="$CACHE_ROOT/go-$GO_VERSION"
  if [ -x "$target/bin/go" ]; then
    echo "Go toolchain cache exists: $target"
    return
  fi
  tmp="$(mktemp -d "$CACHE_ROOT/go-download.XXXXXX")"
  trap 'rm -rf "$tmp"' RETURN
  url="https://go.dev/dl/go$GO_VERSION.linux-amd64.tar.gz"
  curl --proto '=https' --tlsv1.2 -fL --retry 2 -o "$tmp/go.tar.gz" "$url"
  curl --proto '=https' --tlsv1.2 -fL --retry 2 -o "$tmp/go.sha256" "$url.sha256"
  expected="$(tr -d ' \r\n' < "$tmp/go.sha256")"
  [[ "$expected" =~ ^[0-9a-fA-F]{64}$ ]] || { echo "Invalid official checksum response" >&2; exit 3; }
  printf '%s  %s\n' "$expected" "$tmp/go.tar.gz" | sha256sum -c -
  mkdir -p "$tmp/unpack"
  tar -xf "$tmp/go.tar.gz" -C "$tmp/unpack"
  test -x "$tmp/unpack/go/bin/go"
  mv "$tmp/unpack/go" "$target"
  echo "Installed Go to $target"
}
install_flutter() {
  if command -v flutter >/dev/null 2>&1 && flutter --version --machine 2>/dev/null | grep -q '"frameworkVersion": "3.35.7"'; then
    echo "Already available: Flutter $FLUTTER_VERSION"
    return
  fi
  command -v git >/dev/null 2>&1 || { echo "git required" >&2; exit 3; }
  target="$CACHE_ROOT/flutter-$FLUTTER_VERSION"
  if [ -x "$target/bin/flutter" ]; then
    echo "Flutter cache exists: $target"
    return
  fi
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$target"
  git -C "$target" rev-parse HEAD
  "$target/bin/flutter" --version
}
install_android() {
  command -v sdkmanager >/dev/null 2>&1 || { echo "sdkmanager missing: configure Android command-line tools in Codex Cloud environment first" >&2; exit 3; }
  echo "Installing Android SDK 36 via existing sdkmanager; NO license acceptance."
  sdkmanager --install "platform-tools" "platforms;android-36" "build-tools;36.0.0" </dev/null
}
prepare_deps() {
  test -f "$ROOT/production/server/go.mod" || { echo "Production Go tree missing. Check out production branch in isolated workspace." >&2; exit 4; }
  test -f "$ROOT/production/mobile/pubspec.yaml" || { echo "Production Flutter tree missing. Check out production branch." >&2; exit 4; }
  command -v go >/dev/null 2>&1 || { echo "Go missing"; exit 4; }
  command -v flutter >/dev/null 2>&1 || { echo "Flutter missing"; exit 4; }
  (cd "$ROOT/production/server" && go mod download)
  (cd "$ROOT/production/mobile" && flutter pub get --enforce-lockfile)
}
if [ "$INSTALL_GO" -eq 1 ]; then install_go; fi
if [ "$INSTALL_FLUTTER" -eq 1 ]; then install_flutter; fi
if [ "$INSTALL_ANDROID_PACKAGES" -eq 1 ]; then install_android; fi
if [ "$PREPARE_DEPS" -eq 1 ]; then prepare_deps; fi
python3 "$SCRIPT_DIR/cloud_doctor.py" --root "$ROOT" --profile "$PROFILE"
echo "Complete. For interactive shells: source $CACHE_ROOT/env.sh"
