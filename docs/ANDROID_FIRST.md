# Android-first delivery

Source: the master onboarding baseline supplied by Ammar on 2026-10-04.

Android is the only immediate client delivery target. Flutter/Dart is the
registered client direction. Do not intentionally prevent later iOS support,
but do not implement or configure iOS-specific product features now.

## Requirements for later client work

- Prioritize performance on real low/mid-range Android hardware; emulator
  results alone are insufficient.
- Treat Arabic/RTL and mixed-language names as first-class requirements.
- Support responsive Android screen sizes and preserve gameplay clarity.
- Handle lifecycle and background/foreground transitions.
- Handle network loss, reconnect, recovery, and safe retries.
- Measure app size, resource use, battery, thermal behavior, and network usage.
- Consider adaptive quality, reduced animations/effects, caching, resource
  bundles, and on-demand assets where justified. Rules and fairness stay equal.
- Keep localized user-facing strings outside scattered UI literals.

## Current implementation boundary

The first official Android development build is authorized through the scoped
REX Codex Execution Order 002. Flutter/Dart application code and debug APK
builds are allowed within that task. This does not authorize Go backend work,
multiplayer, billing, ads, voice, production signing, or Google Play release
configuration. Android hardening/integrity mechanisms remain later scoped work.

## Engineering selections still pending

Flutter/Dart versions, Go version, Android SDK/JDK versions, minSdk/targetSdk,
minimum supported devices, device test matrix, performance budgets, build
tooling, application/package identifier, signing/release strategy, and asset
delivery implementation are **UNKNOWN / TO BE DECIDED**.

The current local preflight records Flutter 3.47.3, Dart 3.13.3, Android SDK
36.0.0/build-tools 36.0.0, platform android-37.0, and Android Studio's bundled
OpenJDK 25.0.3. The debug application uses the Flutter-managed compile/target
values and has not been certified as a Google Play release. Android SDK
licenses still require human acceptance on this machine.
