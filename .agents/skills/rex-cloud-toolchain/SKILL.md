---
name: rex-cloud-toolchain
description: "Prepare and verify secure Codex Cloud toolchains, GitHub repository access, Android SDK, dependency hosts and approved test connectors for REX."
---

# REX Cloud Toolchain & Access Readiness

Use when preparing or troubleshooting the REX Codex Cloud environment, or when a coding task needs Go, Flutter, Android, Blender, network or GitHub permissions.

## Procedure

1. Read `supervision/cloud/CLOUD_ACCESS_AND_SETUP.md`, `REX_CLOUD_PROFILE.json` and `REX_ACCESS_MATRIX.json`. Verify real current production branch and CI pins first.
2. Run `bash supervision/cloud/setup_rex_cloud.sh --profile android --check` and `python3 supervision/cloud/cloud_doctor.py --profile android --json` to inspect, not to claim deployment.
3. If required tools are absent, request operator-provided Codex network/package permissions. Use only explicit reviewed `--install-go`, `--install-flutter`, or `--android-packages` modes. Never run arbitrary third-party curl-to-shell installers.
4. Verify GitHub repository read and only isolated branch/PR write via connected identity. Do not request repository admin, secrets management, main branch force push or production deployment.
5. Do not claim physical device access, KVM, graphics authoring, licensed assets or cloud publication unless genuinely confirmed; use GitHub Actions for native emulator work where needed.
6. Check network allowlist and redirect domains using platform controls. Do not print token values or store credentials in `.env`, logs, source, screenshots or chat.
7. Execute appropriate reproducible tests only after the actual production checkout and toolchain are present. Keep old `app/rex_mobile` / Flutter 3.47.3 separate from `production/mobile` / Flutter 3.35.7.
8. Deliver a short capability report (READY/BLOCKED per item), exact tests, approval owner, next operator action and production implementation next step.

## Commands

- `python3 -m unittest discover -s supervision/cloud -p 'test_*.py' -v`
- `bash -n supervision/cloud/setup_rex_cloud.sh`
- `bash supervision/cloud/setup_rex_cloud.sh --profile android --dry-run`
- `python3 supervision/cloud/cloud_doctor.py --profile android --json`

## Boundaries

The skill and repository configs cannot grant user-account permissions, publish Codex environments, accept Android licenses, access a local Windows drive, spend money, or certify REX as release-ready.
