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

## Try the core flow

1. Start or skip onboarding and open **Explore and learn**.
2. Select **Traffic signals**. Change the vision mode and move the strength slider.
3. Open **Compare with original**. Drag the split or use its slider, then try **Side by side**.
4. Try a local JPEG or PNG. On a supported phone, open the rear camera and tap **Freeze and compare** to compare two renderings of one captured frame.
5. Reopen Explore and select the **Learn** tab to read mode descriptions and sources.

Photos are processed locally. Imports accept files up to 24 MiB and 32 MP, limit preview edges to 2048 px, and leave the source file intact. The camera comparison temporarily captures a still in the platform cache and deletes it after decoding. The app persists only the onboarding flag. Sample scenes are bundled original illustrations. See [scope and analysis](docs/scope.md), [design](docs/design.md), and the [English implementation plan](docs/PLAN.md).

For later extensions with editable data, run `$demo-crud` from the project root. Its bundled instructions are in [.agents/skills/demo-crud/SKILL.md](.agents/skills/demo-crud/SKILL.md).
