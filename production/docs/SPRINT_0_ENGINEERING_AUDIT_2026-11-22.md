# REX — Sprint 0 Engineering Audit (2026-11-22)

**Status:** IN PROGRESS — engineering evidence, not release approval.
**Working branch:** `production/rex-sprint0-20261122`, based on PR #18 head `0bbea8c0549cb2807e10290f93796fdbb449b1e7`.
**Decision authority:** product scope and game rules remain with Ammar; major architecture decisions require Abdulaziz's technical review. No merge, production deployment or release is authorized by this document.

## 1. Product requirements carried forward
- REX is a distinct, extensible social card-game platform; not a Jawaker copy.
- Original Arabic-first brand, premium table/character/environment vision; final art is not yet delivered.
- Initial recorded game scope: Trix Complex and Tarneeb. Deliver sequentially; do not quietly drop Tarneeb from V1.0.
- Explicit cross-platform requirement (19 Nov 2026): **build and test Android and iOS from project inception**. Android may release first; iOS follows shortly once its *independent* acceptance gates pass.
- No pay-to-win, wagering, cash-out or unapproved monetization features; avoid fake progression or purchases.

## 2. Verified repository baseline
| Component | Evidence / current reality | Action |
|---|---|---|
| Git branch stack | PR #18 is a **draft** targeting PR #17. Multiple stacked draft PRs remain open; main is not the checked implementation branch. | Preserve ancestry and identify an integration strategy only after review. |
| Android | `production/mobile/android/app/build.gradle.kts` and `android-native` job exist; debug Android build passed in run 43711059466. | Keep; validate on physical devices before launch. |
| iOS | Fetches of `production/mobile/ios/Runner/Info.plist`, `ios/Runner.xcodeproj/project.pbxproj`, and `ios/Podfile` return NOT_FOUND on PR #18 head. No iOS job in the reviewed CI workflow. | Recreate native iOS Runner on macOS using Flutter, commit files, add macOS CI and test on iOS simulator/device. |
| Flutter | `production/mobile/lib/` and tests exist. The foundation job in run 43711059466 failed at `dart format --set-exit-if-changed`; four files changed under Dart formatter. | Apply official formatter output, then rerun format, analyze and tests. |
| Credential vault | `production/mobile/lib/main.dart` directly instantiates `AndroidVault()`; `vault.dart` uses a platform channel with Android Keystore implementation. | Introduce platform-neutral factory and native iOS Keychain implementation with no plaintext fallback. |
| Go gameplay | Candidate Trix engine, API, and security tests exist. `candidate-go-fast` passed in run 43711059466. | Keep candidate isolated until rules review/approval. |
| PostgreSQL | `database-contract` job passed in run 43711059466. `production/server/db/README.md` explicitly states SQL is **not** connected to live Go server or approved for production. | Abdulaziz D2 review, then transactional integration and restore drills. |
| Tarneeb | Recorded in V1.0 scope; authoritative versioned game-rules contract and engine missing. | Separate rules approval and implementation milestone. |
| Release | `production/docs/RELEASE_ACCEPTANCE.md` marks V1.0 **BLOCKED**. | No public publication, fake match, or claims of completed release. |

## 3. Sprint 0 work packages (in order)
1. **S0-001 — CI repair:** capture exact `dart format` output, commit formatted four Flutter files, require latest full suite PASS.
2. **S0-002 — iOS Runner:** create `ios/` with a pinned Flutter toolchain on macOS, iOS build configuration and non-production bundle ID; commit reproducible scaffold.
3. **S0-003 — Credential parity:** keep Android Keystore; implement iOS Keychain with matching channel semantics (read/write/delete), safe error handling, persistence/recovery tests. Never silently downgrade to preferences.
4. **S0-004 — Dual-platform CI:** Linux Android + macOS iOS simulator build on every relevant PR; record exact successful commit SHA and artifacts.
5. **S0-005 — Rules / D2 decision log:** document unresolved Trix policies, Tarneeb scope, storage and real-time transport proposals; do not set them as approved.
6. **S0-006 — Real device matrix:** run Android/iOS low/mid-range smoke tests; track app launch, account recovery, rooms, turn sync, reconnect and frame times.

## 4. Gate G1 (all required)
- `dart format`, `flutter analyze`, `flutter test`, Go race tests and security checks PASS on the **same reviewed commit**.
- Android debug build and **iOS simulator build** PASS independently; physical-device tests are separately tracked.
- A platform-appropriate encrypted `SessionVault` is exercised on both Android and iOS, including pending-action replay.
- No candidate rules public activation; no production secrets, unsafe test-only billing, unapproved app-store release or PR merge.

## 5. Audit constraints / honesty
- A successful Android CI build is not an iOS success and not evidence of four physical clients playing a complete match.
- Passing candidate SQL tests is not live transactional persistence.
- This audit was performed via GitHub connector and previous approved project sources. No macOS/iPhone device was available for local testing.
- CI formatter diagnostic step in this branch is temporary; it must be removed after applying formatter changes and validating checks. Do not weaken the mandatory formatting gate.

**Next confirmed priority:** S0-001, followed by iOS native Runner + Keychain + CI work.
