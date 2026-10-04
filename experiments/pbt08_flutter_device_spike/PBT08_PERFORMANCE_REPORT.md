# PBT08 Android Performance Qualification

Date: 2026-10-05 (Asia/Amman)

This is a measurement report for the PBT08 experiment. It does not establish a
production performance budget or validate the REX low-end device floor.

## Environment

- Flutter 3.47.3 stable, framework `e8113bf45620cbeb8aff64947ee4c93e16adb4cf`
- Dart 3.13.3
- Device: Xiaomi 23030RAC7Y, `arm64-v8a`
- Android 15 / API 35
- Resolution: 1080×2400 physical pixels
- Density: 440 dpi
- Refresh-rate configuration reported by Android: up to 90 Hz
- Approximate device `MemTotal`: 7,892,276 kB
- Test mode: profile APK for runtime measurements; debug was used only for the
  earlier baseline APK and release builds were measured as artifacts.

## Quality gates

`dart format --output=none --set-exit-if-changed .`, `flutter analyze`, and
`flutter test --reporter expanded` passed. The test suite reported **6 passed**.
No application source or dependency changed during qualification.

## APK artifacts

All paths are relative to this experiment unless shown otherwise. SHA-256 values
are recorded so the measurements can be reproduced against the same artifact.

| Mode / ABI | Bytes | MiB | Build seconds | SHA-256 |
| --- | ---: | ---: | ---: | --- |
| Debug universal | 150,383,226 | 143.4166 | 27.53 | `E356E1E397EB835E1E45C1052C2C9B8E7C6F04D503F4B00C9C34D3E51BB24610` |
| Profile universal | 59,998,959 | 57.2195 | 38.51 | `9DAD5A579EC4AAEA3EFE9E1667AC5A7A7BC87DA5884ADC0BED8641A1A678B434` |
| Release universal | 44,085,726 | 42.0434 | 85.97 | `A463A57FF9EA6A900C2C163D818CF8B18D214F979F0E3763BAE5B10783022887` |
| Release `armeabi-v7a` | 12,616,328 | 12.0319 | 36.70 split build | `29FAE53229D46E4DAC99C3B98B98EF7C0C9B048E2ABA3A9B3E8D0E0043E41D77` |
| Release `arm64-v8a` | 15,436,992 | 14.7219 | 36.70 split build | `C6A30CECD53601D101FA3AD04F3697F09A1163BB181447DDB7D645A4255FE257` |
| Release `x86_64` | 16,806,082 | 16.0275 | 36.70 split build | `8A745A7EE3FDF13C659A16F4CE790B6B2EB36E2CAA5A5A8B06877ECAC8124CA0` |

The device ABI is `arm64-v8a`; the split arm64 artifact is the relevant release
size for this phone. APK output remains ignored and was not staged.

## Cold start

Command per sample:

```powershell
adb -s DURCMNMVEUYXD6AA shell am force-stop dev.rex.spike.pbt08
adb -s DURCMNMVEUYXD6AA shell am start -W -n dev.rex.spike.pbt08/.MainActivity
```

These five samples were collected while the profile APK was installed. Android
reported activity launch timing, not Flutter first-frame timing:

| Sample | TotalTime | WaitTime |
| ---: | ---: | ---: |
| 1 | 4,015 ms | 4,032 ms |
| 2 | 3,327 ms | 3,343 ms |
| 3 | 3,043 ms | 3,057 ms |
| 4 | 3,541 ms | 3,569 ms |
| 5 | 2,957 ms | 3,002 ms |

TotalTime median: **3,327 ms**. Minimum: **2,957 ms**. Maximum: **4,015 ms**.
The one-time `am start -W` result includes Android activity launch work and is not
a controlled first-frame benchmark.

## Memory

Command:

```powershell
adb -s DURCMNMVEUYXD6AA shell dumpsys meminfo dev.rex.spike.pbt08
```

The profile process was alive with the table visible. The representative idle
sample after startup was:

| Metric | KiB | MiB |
| --- | ---: | ---: |
| Total PSS | 172,293 | 168.25 |
| Java Heap PSS | 11,088 | 10.83 |
| Native Heap PSS | 30,932 | 30.21 |
| Graphics PSS | 49,267 | 48.11 |

A later sample after the profile process had settled reported Total PSS 126,806
KiB (123.83 MiB), Java Heap 2,624 KiB, Native Heap 2,048 KiB, and Graphics 49,247
KiB. These values vary with Android accounting and process state; they are not a
Flutter heap measurement. A separate post animation memory sample could not be
isolated because the phone blocks shell input injection.

## Frame and jank evidence

Android `dumpsys gfxinfo` was reset and queried, but the Flutter Impeller Vulkan
surface reported zero Android View frames for this process. Its output therefore
cannot provide a useful jank percentage for this surface. The command did expose
the Vulkan pipeline and graphics buffer accounting, but those numbers are not
substitutes for Flutter frame timing.

Flutter's profile VM service emitted 295 `Flutter.Frame` events during the
capture window. The collected `elapsed` values were:

- median: 9,837 µs (9.837 ms)
- p90: 11,688 µs (11.688 ms)
- p99: 15,549 µs (15.549 ms)
- maximum: 29,725 µs (29.725 ms)
- over 11,111 µs: 39 / 295 (13.22%)
- over 16,667 µs: 2 / 295 (0.68%)

These events cover the profile session capture window and were not restricted to
exactly 20 animation cycles. They are useful exploratory evidence for this
device, not a release performance certification. No Flutter first-frame metric
was inferred from Android launch timings.

## Stability and runtime

The profile APK installed and launched successfully. Screenshots showed the REX
scene, four seats, 13 local cards, and the deal control. The prior manual device
check confirmed that the animation moves cards from the center to seats, repeats,
and re-enables the button. The process remained alive and filtered log checks
found no fatal exception or RenderFlex overflow.

The requested 50-cycle automated loop was not completed: Android rejected ADB
shell touch injection with `SecurityException: INJECT_EVENTS`. No phone security
setting was changed. The result is **manual smoke pass; 50-cycle loop not
qualified**.

## Warnings and limitations

- Kotlin daemon connection warnings occurred during Gradle builds; Gradle's
  fallback compilation path still produced every requested APK successfully.
- Android licenses are not all accepted in `flutter doctor`; the build-required
  platform and NDK licenses were already sufficient. No license acceptance was
  fabricated.
- This single Xiaomi device is not an agreed REX low-end floor device.
- `gfxinfo` is not useful for this Flutter Vulkan surface in this run.
- Performance overlay capability was manually confirmed in debug mode and remains
  debug-only. Profile measurements were taken without the overlay.

## Verdict

**PASS WITH CONDITIONS** for this device-specific PBT08 rendering, build, launch,
memory, and exploratory profile-frame qualification.

**LOW-END FLOOR VALIDATION = PENDING.** The evidence applies only to Xiaomi
23030RAC7Y on Android 15/API 35 and does not select a minimum device, API level,
or production performance budget.
