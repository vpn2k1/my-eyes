# My Eyes · Nhìn qua đôi mắt của tôi

An offline Flutter app for exploring and comparing modeled differences in color vision. Interface and educational text follow the device's English or Vietnamese locale.

## Run from source

Use Flutter 3.50.0 stable (Dart 3.14) with the Android SDK or with Xcode on macOS. The project is configured for Android API 24+ and iOS 15+. Connect a phone or start a simulator and run the app from the project root.

```sh
flutter pub get
flutter devices
flutter run -d DEVICE_ID
```

For Android live camera, use a physical device with a rear camera and Impeller shader-filter support. For iOS, select a physical device and configure signing in Xcode. Camera permission is requested when the camera screen opens. No audio recording is requested. For the photo and scene flows in Chrome, use `flutter run -d chrome`. On renderers without shader-filter support, the camera entry offers photo and scene alternatives.

Run these checks from the same directory.

```sh
flutter analyze
flutter test
flutter build web --no-web-resources-cdn
```

Use `flutter build apk --debug` to package an Android demo and `flutter build ios` from macOS for an iOS build. Configure release signing before distribution. See [verification](docs/verification.md) for checks actually run.

## Regenerate branding and splash screens

The 2D illustration in `assets/branding/logo_source.png` was created with imagegen
from the photographic eye reference. Its eyelids, blue/amber iris and dark pupil
are part of the generated PNG artwork, not shapes drawn by code or SVG. The full
prompt is in `assets/branding/logo.prompt.txt`. Prepared logo, icon and splash
PNGs are saved beside the source. After preparing replacement PNGs, regenerate
the platform resources from the project root:

```sh
dart run flutter_launcher_icons && dart run flutter_native_splash:create
```

Only `logo.png` is bundled for the app header and hero cards. Launcher/splash
sources are consumed by `flutter_launcher_icons` and `flutter_native_splash` at
build time. Splash backgrounds stay navy in light and dark mode; Android 12+
uses a separate padded image to fit the system's circular mask. Native splash
ends automatically when Flutter draws its first frame, with no artificial delay.

## Try the core flow

1. Start or skip onboarding and open **Explore and learn**.
2. Select **Traffic signals**. Change the vision mode and move the strength slider.
3. Open **Compare with original**. Drag the split or use its slider, then try **Side by side**.
4. Try a local JPEG or PNG. On a supported phone, open the rear camera and tap **Freeze and compare** to compare two renderings of one captured frame.
5. Reopen Explore and select the **Learn** tab to read mode descriptions and sources.

Photos are processed locally. Imports accept files up to 24 MiB and 32 MP, limit preview edges to 2048 px, and leave the source file intact. The camera comparison temporarily captures a still in the platform cache and deletes it after decoding. The app persists only the onboarding flag. Sample scenes are bundled AI-generated photorealistic images, not photographs of actual subjects. Their generation prompts are recorded in [scene sources](docs/scene-sources.md). See [scope and analysis](docs/scope.md), [design](docs/design.md), and the [English implementation plan](docs/PLAN.md).

For later extensions with editable data, run `$demo-crud` from the project root. Its bundled instructions are in [.agents/skills/demo-crud/SKILL.md](.agents/skills/demo-crud/SKILL.md).

## UI icon artwork

`assets/icons/` contains 22 original, transparent 144 × 144 WebP icons. The flat
blue/amber artwork is shared through `lib/app_icon.dart`; navigation symbols
inherit the current icon tint for dark surfaces, and button labels/tooltips
provide accessibility text. No additional runtime package is required.
Regenerate the artwork with `python3.11 tools/generate_icons.py` (requires Pillow).
