# Codex Cloud — REX cloud preparation task (run BEFORE the mega mission)

Repository: `enad86102-debug/rex`.
Toolkit: `supervision/rex-swarm-control`.
Runtime source: `production/swarm-reviewed-recovery` (or newly verified reviewed successor).

**Work mode: environment-preparation only, not a rewrite of REX.**

1. Read `supervision/cloud/CLOUD_ACCESS_AND_SETUP.md`, `REX_CLOUD_PROFILE.json`, `REX_ACCESS_MATRIX.json` and `setup_rex_cloud.sh`. Verify that the code and versions match the latest real `production/.github` and `production/mobile` checkout.
2. Inspect tools, Android SDK 36, Java 17, permissions, repository branches and available memory. Run `bash supervision/cloud/setup_rex_cloud.sh --profile android --check`. Do not fabricate tools or rights.
3. If the environment allows dependency downloads and the script has been reviewed, run its explicit opt-in setup modes to install missing **Go 1.27.2** and **Flutter 3.35.7** from the official sources. Do not autoaccept Android licenses. If `sdkmanager` is present and licenses preaccepted, Android package install is a separate opt-in action. Do not use sudo or curl | bash.
4. Check that real Go server and Flutter production client are present in a new isolated production-based branch with the supervision toolkit brought in safely; never merge/reset human branches or work on stale `main`.
5. Run `python3 supervision/cloud/cloud_doctor.py --profile android --json`, policy unit tests and production-relevant `go test -race ./...`, `flutter analyze`, `flutter test`, and Android debug build when actual toolchains and dependencies exist. Use the existing production GitHub Actions for native emulator evidence when Cloud lacks KVM.
6. Verify GitHub read, isolated code branch push and PR creation *using already connected identity and minimum scope*. If not available, request the exact operator action, without asking for passwords or pasting access tokens.
7. Present a concise Arabic setup report: actual CPU/memory if exposed, versions, Android SDK/JDK, allowed network, GitHub access, missing connections, commands and real results, environment blocked items, and exact next working production task.
8. Do not configure real Google Play publishing, production database passwords, customer data, signing keys, paid subscriptions, or high-privilege access. Preserve REX D2/D3 human review gates.

Success means the Cloud execution environment is honestly prepared for **real REX engineering**. It does not mean REX V1.0 is ready, that 1000 reviewers ran, or that production artwork exists.
