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

## Explicit exclusions in this phase

Do not initialize Flutter or Go or install dependencies. Do not add billing,
ads, voice, or Google Play release configuration without a later explicit task.
Android hardening/integrity mechanisms are later scoped work.

## Engineering selections still pending

Flutter/Dart versions, Go version, Android SDK/JDK versions, minSdk/targetSdk,
minimum supported devices, device test matrix, performance budgets, build
tooling, application/package identifier, signing/release strategy, and asset
delivery implementation are **UNKNOWN / TO BE DECIDED**.

Choose minimum Android/API targets only through engineering analysis and
approval during Android bootstrap. This document makes no arbitrary device or
SDK assumptions and does not certify that the local Android toolchain is ready.
