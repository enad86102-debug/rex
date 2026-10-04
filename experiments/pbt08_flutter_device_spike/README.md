# PBT08 — Flutter Android Device Spike

PBT08 is an experimental REX Android rendering/build feasibility spike. It is not
the production REX application, a final design, or a production architecture
decision. Abdulaziz remains the human technical lead; this scoped experiment
does not adopt new production decisions.

## Verified tool baseline

- Flutter: **3.47.3 stable**, Windows x64, installed outside REX at
  `C:\Users\Ammar\develop\flutter` from the official Flutter GitHub tag.
- Framework revision: `e8113bf45620cbeb8aff64947ee4c93e16adb4cf`.
- Engine revision: `06a2e2a110089dff50fe635cffd2a61e1b24fbcd`.
- Dart: **3.13.3 stable**, Windows x64.
- Java: Android Studio bundled JBR, OpenJDK **25.0.3**.
- Android namespace/application ID: **`dev.rex.spike.pbt08`**. This identifier is
  temporary and is not the final REX package ID.
- Android only. Flutter template SDK/Gradle defaults apply to this experiment
  and do not establish REX production minSdk, stack versions, or device policy.

## Scene and scope

The screen contains the REX title, `PBT08 • Flutter Device Spike`, a central
table/deck, four bilingual seats, and exactly 13 fixed face-up local card widgets.
The Arabic `اختبار التوزيع` button starts a repeatable three-second visual
sequence: eight card flights, two toward each seat, at most four flights active
concurrently. The center deck uses three static back-card widgets. The animation
does not change a real hand or implement a dealing contract.

All card graphics use Flutter widgets. No external card assets were downloaded.
A speed icon toggles Flutter's performance overlay in debug mode only.

No backend, game rules, real shuffling, fairness RNG, networking, accounts,
database, bots, economy, payments, ads, or application analytics SDK exists here.
There are zero direct third-party Flutter dependencies: the only direct packages
are SDK `flutter` and SDK `flutter_test`. Their standard SDK-managed transitive
packages are resolved in `pubspec.lock`; they are not additional app libraries.

## Verification

Run from this experiment directory, with Flutter and Android platform-tools on
PATH and Android Studio JBR/Android SDK environment variables configured:

```powershell
flutter pub get
dart format .
flutter analyze
flutter test --reporter expanded
flutter build apk --debug
adb devices -l
flutter devices
flutter emulators
```

- Format: passed, final run changed zero files.
- Analyze: passed, no issues.
- Tests: **6 passed**: scene/seats, button, 13 face-up cards, animated movement
  and repeatability, and layouts at 320×568 and 640×360.
- The first test run exposed a Future-returning `setState` callback. It was
  corrected; all six tests passed before APK building began.
- APK build: **BUILD SUCCESS**, exit code 0; wall time **362.6956648 seconds**
  (Gradle task: 352.4 seconds), including first-build downloads/tool setup.
- Actual APK: `D:\Rex folder\experiments\pbt08_flutter_device_spike\build\app\outputs\flutter-apk\app-debug.apk`.
- Exact APK size: **150,383,226 bytes** (approximately 143.42 MiB).
- Android device subsequently connected: **Xiaomi 23030RAC7Y, Android 15 / API 35**.
  Emulator software is installed, but no AVD is configured. Windows/Chrome/Edge
  entries are not Android targets.
- The first installation attempt returned **INSTALL_FAILED_USER_RESTRICTED:
  Install canceled by user**. After Ammar confirmed phone approval, the second
  `adb install -r` succeeded and `am start -W` returned `Status: ok`.
- Runtime screenshot inspection confirms the REX header/subtitle, central
  table/deck, all four seats, exactly 13 visible local cards, the Arabic button,
  and completed-deal counters 2 and 3 on successive captures. The application
  process remained alive; a filtered app-process log check found no matching
  fatal/uncaught Flutter or RenderFlex-overflow errors.
- ADB input injection was refused with `INJECT_EVENTS` SecurityException. No
  phone security settings were changed by this agent. Manual on-device animation
  confirmation was requested. Ammar confirmed that cards visibly move from the
  center toward the seats, the animation repeats, and the button becomes usable
  again. **DEVICE SMOKE TEST = PASS**, with animation motion confirmed by the
  human tester rather than automated touch injection.
- `am start -W` reported a cold launch TotalTime of 5246 ms / WaitTime 5274 ms.
  This is a single debug/install launch observation, not a controlled cold-start
  benchmark or a first-render metric. No emulator was installed or created.
- Runtime screenshots are ignored outputs in `build/pbt08-runtime.png` and
  `build/pbt08-animation.png`; the latter captures a completed state, not motion.
  Two screenshot copies were also created in the phone's Download directory as
  `rex-pbt08-runtime.png` and `rex-pbt08-animation.png`.

`flutter doctor -v` verifies Flutter and JBR, but reports unaccepted Android
licenses and missing Visual Studio. The official license workflow was inspected
without accepting the unrelated Google TV agreement. No acceptance files were
fabricated. Windows desktop development is outside this Android-only experiment.

The first build reported failed connections to the Kotlin compile daemon and
continued through the toolchain's fallback compiler. The APK build ultimately
succeeded without replacing JBR, changing template versions, or applying a
workaround. This warning remains relevant for later build reliability checks.

## Installation and environment changes

User-level `JAVA_HOME` points to Android Studio's JBR; `ANDROID_HOME` and
`ANDROID_SDK_ROOT` point to `C:\Users\Ammar\AppData\Local\Android\Sdk`.
Flutter `bin` and SDK `platform-tools` were appended to the existing User PATH.
Already-running terminals/app processes may need a restart to inherit them.

Official Google command-line tools **22.0** were installed into SDK
`cmdline-tools/latest` from `commandlinetools-win-15859902_latest.zip` after
verifying SHA-256
`90ae805d20434428bffcb699c290860f19bb5f66a67e6b330067e3de801fb04a`.
The download and extraction staging directory remain outside REX under
`C:\Users\Ammar\develop`. Flutter and Gradle maintain their normal external
tool caches. No Go, Node/npm, GitHub CLI, Android Studio, or emulator was installed.

Gradle also installed the official Android SDK Platform **36 revision 2** and
NDK **28.2.13676358 (r28c)** required by the Flutter template. Existing
`android-sdk-license` acceptance was sufficient for these build components.
Existing platform-tools **37.0.1**, build-tools **36.0.0**, Android platform
**37.0**, and emulator binary **37.2.12.0** were retained. A normal debug signing
key may be generated by Android tooling outside REX; production signing was not
configured.

## Git and preservation

Normal Git operates on `main` without a safe.directory override. No ownership
repair was repeated. All 11 original REX Markdown documents and `.editorconfig`
retain their SHA-256 hashes. Root `.gitignore` received only `/.idea/` with a
comment after machine-local IDE state appeared at the repository root during
execution. Those files were not created through this agent's commands and were
not deleted or edited. This minimal exclusion is authorized by the task.
The experiment's generated ignores exclude build/APK, `.dart_tool`, Android
`local.properties`, Gradle caches, IDE files and signing keys.

Neither Git user.name nor user.email is configured:
**COMMIT BLOCKED — GIT IDENTITY REQUIRED**. Nothing was staged or committed,
no REX remote was added, and nothing was pushed.

## Limits and later device measurements

Widget tests validate logical behavior and layout; they do not establish Android
production performance. The device smoke check covers only the visible scene
and immediate launch, not comprehensive runtime correctness. This debug APK is not a release
artifact. The template release signing configuration is not production signing.
Fixed sample cards and seat labels are only rendering placeholders.

The next separately authorized task should collect a controlled PBT08 performance
baseline on the connected physical Android device, including these measurements:

| Measurement | Current evidence |
| --- | --- |
| Cold-start time | PENDING |
| RAM | PENDING |
| FPS | PENDING |
| Frame jank | PENDING |
| APK size | 150,383,226 bytes, debug universal APK |
| Device model | Xiaomi 23030RAC7Y |
| Android version | Android 15 / API 35 |

Debug overlay observations are preliminary; profile-mode measurements require
a separately authorized follow-up. No first game or game rules were selected.

## REX-EXEC-004 qualification

The detailed measurements are in [PBT08_PERFORMANCE_REPORT.md](PBT08_PERFORMANCE_REPORT.md).
Quality gates remained green: formatting unchanged, analyzer clean, and 6 widget
tests passed. Debug, profile, release, and split-per-ABI release APKs all built.
The connected Xiaomi 23030RAC7Y profile run launched and rendered the scene.
Five Android activity cold-start samples had a 3,327 ms median, with 2,957 ms
minimum and 4,015 ms maximum. Profile memory samples ranged from 126,806 to
172,293 KiB Total PSS. Flutter profile timing captured 295 frame events with
9.837 ms median elapsed time and 0.68% above 16.667 ms in that capture window.
Android `gfxinfo` did not expose useful View frame counts for the Flutter Vulkan
surface. A manual smoke check passed; the 50-cycle automated loop was not
qualified because the phone rejected ADB touch injection. Verdict: **PASS WITH
CONDITIONS** for this device-specific experiment. **LOW-END FLOOR VALIDATION =
PENDING**.

## Created source/configuration file inventory

All 32 files below are new relative to the original documentation-only
repository. Template files customized after creation include `pubspec.yaml`,
`analysis_options.yaml`, `lib/main.dart`, `README.md`,
`android/app/build.gradle.kts`, and the main Android manifest. No pre-existing
REX document was modified, deleted, moved, or renamed. The sole pre-existing
configuration change is the root `.gitignore` exclusion described above.

```text
.gitignore
.metadata
README.md
analysis_options.yaml
android/.gitignore
android/app/build.gradle.kts
android/app/src/debug/AndroidManifest.xml
android/app/src/main/AndroidManifest.xml
android/app/src/main/kotlin/dev/rex/spike/pbt08/MainActivity.kt
android/app/src/main/res/drawable-v21/launch_background.xml
android/app/src/main/res/drawable/launch_background.xml
android/app/src/main/res/mipmap-hdpi/ic_launcher.png
android/app/src/main/res/mipmap-mdpi/ic_launcher.png
android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
android/app/src/main/res/values-night/styles.xml
android/app/src/main/res/values/styles.xml
android/app/src/profile/AndroidManifest.xml
android/build.gradle.kts
android/gradle.properties
android/gradle/wrapper/gradle-wrapper.properties
android/settings.gradle.kts
lib/main.dart
lib/pbt08/pbt08_screen.dart
lib/pbt08/widgets/rex_card.dart
lib/pbt08/widgets/rex_hand.dart
lib/pbt08/widgets/rex_player_seat.dart
lib/pbt08/widgets/rex_table.dart
pubspec.lock
pubspec.yaml
test/pbt08_widget_test.dart
```

Ignored generated files also exist under `.dart_tool/`, `build/`, `.idea/`,
`android/.gradle/`, and as local Android/IDE/wrapper outputs. These are tooling
outputs, not source files or commit candidates. Flutter SDK/cache, Android SDK
packages, Gradle caches and the download/staging files exist outside REX.

`EXECUTION_FILE_INVENTORY.csv` lists every file present in the new experiment,
including ignored generated outputs, with relative paths and byte sizes. It is
an execution snapshot rather than a promise that tool caches never change.
The inventory file itself is a new documentation artifact.
