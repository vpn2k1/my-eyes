# Verification and handoff

[PLAN.md](PLAN.md) contains the original English Spec, Plan, acceptance IDs, and T01–T35 test matrix. The review below traces each P0 feature to the code and records which checks ran. The Flutter SDK used was 3.50.0 with Dart 3.14.0.

| Feature | Spec / Plan | Code reviewed | Test evidence and remaining checks |
| --- | --- | --- | --- |
| F-01 | AC-01–03, T01–03 | `lib/main.dart` presents first-run guidance and records completion. Home can reopen it. | Widget test covers the notice, skip, relaunch, and reopen. The start button shares the tested handler. App preference persistence on a phone remains a device check. |
| F-02 | AC-01–05, T04–08 | `lib/simulator.dart` serializes camera setup, lifecycle and still capture. `lib/viewport.dart` filters only the camera texture. Permission and unsupported-renderer states provide alternate sources. | Physical rear-camera behavior, permission states, live frame rate, freeze orientation, and resume remain device checks. |
| F-03 | AC-01–04, T09–12 | `lib/main.dart` invokes the native picker and treats cancellation as a return. `lib/media.dart` validates the actual file, bakes EXIF orientation, and bounds image size. | Unit tests pass for both formats, invalid input, EXIF orientation, bounded preview, and unchanged input. Native picker cancel/recovery and wide-gamut inputs remain device checks. |
| F-04 | AC-01–04, T13–16 | `lib/machado.dart`, `lib/vision.dart`, `shaders/vision.frag`, and `lib/viewport.dart` separate coefficient tables, CPU reference, and rendering from the original source. | CPU tests pass for identity and endpoint fixtures across all modeled families and grayscale. Flutter test render showed the scene recolored on just the simulated side. Comprehensive GPU numerical parity remains open. |
| F-05 | AC-01–04, T17–20 | `lib/simulator.dart` and `lib/viewport.dart` reuse a single source, label both views, and provide image drag and a native semantic slider. | Mobile-width widget flow opens a bundled scene, reaches Compare, moves through 50%, 0%, and 100%, and verifies layout switching preserves mode and strength. Screen reader and keyboard validation on target devices remains open. |
| F-06 | AC-01–04, T21–24 | `lib/vision.dart` selects adjacent severity matrices, validates input, and clamps finite values. `lib/simulator.dart` preserves strength across modes and explains fixed-strength modes. | Unit tests pass for endpoints, 55% interpolation, finite bounds, and non-finite input. Widget test verifies the slider hides for grayscale and retains the prior value. |
| F-07 | AC-01–03, T25–27 | `lib/content.dart`, `lib/main.dart`, `lib/media.dart`, and `assets/scenes/` bundle the six sources, descriptions, tips, and asset-error states. | Widget tests opened the traffic image and laid out the Vietnamese library at desktop width. All six PNGs were verified in the bundle. Airplane-mode phone testing remains open. |
| F-08 | AC-01–03, T28–30 | `lib/content.dart` and `lib/main.dart` provide local mode explanations, educational framing, and copyable reference URLs. | Vietnamese widget test reached the Learn tab and found the references. External link opening, a full copy review, and screen reader testing remain open. |

## Commands and results

| Command | Result |
| --- | --- |
| `flutter analyze --no-pub` | Passed |
| `flutter test --no-pub --reporter expanded` | 10 passed |
| `flutter build web --no-pub --no-web-resources-cdn` | Passed |
| Chromium smoke test | Browser process could not launch because the hosted shell denied its process socket. Flutter widget rendering supplied the interactive UI checks recorded above. |
| `flutter build apk --debug --no-pub` | No APK produced. Gradle timed out while resolving Android build dependencies after retry. |
| `flutter build ios` | Pending. Requires Xcode on macOS. |

A clean extraction resolved the locked dependencies offline with the populated package cache and passed `dart analyze`.

## Re-verification — 2026-11-17

Re-ran on local machine with Flutter 3.44.8 / Dart 3.12.2 (older than the 3.50.0/3.14.0 originally used; pubspec constraint `sdk: ^3.10.0` still holds).

| Command | Result |
| --- | --- |
| `flutter pub get` | Resolved cleanly (22 dependency versions shifted down to match the older SDK; no conflicts) |
| `flutter analyze --no-pub` | No issues found |
| `flutter test --no-pub --reporter expanded` | 10 passed (vision_test.dart x3, media_test.dart x3, widget_test.dart x4) |
| `flutter build web --no-pub` | Passed |
| `flutter build ios --no-pub --simulator` | Passed (first successful run of this check; requires Xcode, available on this machine) |
| `flutter build apk --debug --no-pub` | Not completed — build host's disk was full ("No space left on device"); Android build was skipped per user request after freeing disk space for other purposes. Still an open item. |

All previously logged open physical-device checks (camera permission flows on hardware, true FPS, screen-reader validation, GPU/CPU shader parity on real GPUs, wide-gamut photo import, airplane-mode phone pass) remain open — this session had no physical device or emulator attached, only static analysis, unit/widget tests, and build attempts.

## Physical-device checks

1. On Android and iOS, grant, deny, and restrict camera permission. Verify Settings and the alternatives. Background and resume the live preview, leave and re-enter it, and check the camera indicator releases after leaving.
2. Freeze the live feed in portrait and landscape. Compare both sides at each split endpoint, return to live preview, and reopen Compare with a new frame.
3. Import a labeled JPEG with EXIF rotation, a transparent PNG, a corrupt JPEG, an oversized file, and a wide-gamut photo. Cancel the picker. Check source geometry and file retention.
4. In airplane mode, open all six illustrations, switch modes, and navigate the educational text. Check touch, large text, and VoiceOver or TalkBack. Use a keyboard to adjust sliders.
5. Use independent color fixtures to compare GPU output with the CPU reference on each backend. Measure FPS and mode-switch latency using the reference devices from the plan before release.
