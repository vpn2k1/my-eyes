# Screen design

| Screen | Feature IDs | Primary action and states |
| --- | --- | --- |
| Onboarding | F-01 | See an original/Deutan example and read about the model. Start or skip and access guidance again through Home. |
| Home | F-02, F-03, F-07 | Open the camera, choose a JPEG/PNG, or explore six scenes. Show file loading and a recoverable error. |
| Simulator | F-02, F-03, F-04, F-06 | Display the source with mode chips and a strength slider. Compare the image or freeze the camera. For a camera failure, show photo and sample actions. |
| Compare | F-04, F-05, F-06 | Use a horizontal image divider with an accessible slider or place the same two images side by side. Switch layouts with mode and strength preserved. |
| Explore and Learn | F-07, F-08 | Open a scene with alt text, a barrier description and a design tip. Switch tabs to find model notes and references. |

Material 3 uses blue seed #3366FF, system light/dark, and a dark navy onboarding/home hero. Content uses a scrollable 680 px maximum width, 20 px side gutters, and vertically wrapping choice chips. Buttons are at least 48 px tall. The selected chip uses labels and a check mark. Compare labels and the light/dark separator identify each side without color. The scene library uses two columns when at least 560 px is available, crops thumbnails to a 900:560 ratio, and shows the full image in the simulator. Only the photo, sample image or camera preview receives the transform. Six AI-generated photorealistic scenes are labeled in both languages and included offline; these are synthetic images, not documentary photographs. Prompts and provenance are recorded in `scene-sources.md`. The logo, launcher icon and splash use a flat 2D eye with a blue/amber iris; Android themed icons retain a monochrome silhouette for legibility.

## 2D visual refresh (2026-11-18)

Material 3 now derives its light/dark ColorSchemes from **#3366FF**. The
ColorScheme generation remains unchanged. Brand navy **#141E35**, lifted navy
**#253C62**, ink **#F5F7FD** and amber **#E0A32E** retain their original values.
Camera/comparison overlays still use these brand colors. No theme color is
applied to source photographs, camera frames, shader output or Ishihara plates.

`AppAccents` is the sole new ThemeExtension. Home keeps its ListTile navigation
and pairs each full-color card with an existing illustrated icon, title,
subtitle and directional chevron. Icon artwork sits on a brandInk light
chip; text and chevrons use the matching `onAccent`. Color never identifies an
action or state by itself. The five accent values deliberately differ in
relative luminance as well as hue:

| Feature | Light accent | Dark accent | onAccent | Light/dark text contrast |
| --- | --- | --- | --- | --- |
| Experience a condition | #1D43AB | #173992 | #F5F7FD | 8.02 / 9.63 |
| See true colors | #267767 | #206C5D | #F5F7FD | 5.01 / 5.83 |
| Choose photo | #D18B70 | #C98065 | #141E35 | 6.03 / 5.34 |
| Explore and learn | #E3D6FF | #D9C8F5 | #141E35 | 12.10 / 10.68 |
| Test your color vision | #E0A32E | #E0A32E | #141E35 | 7.46 / 7.46 |

These measured pairs exceed 4.5:1 for ordinary text and 3:1 for large text and
navigation glyphs. Palette tests also apply the app's Machado simulation at full
protan/deutan/tritan severity and assert that adjacent luminances remain more
than .045 apart. This is a regression guard, not a universal perceptual threshold;
visual checks still matter. Seed generation alone does not guarantee the contrast
of custom artwork, overlays or arbitrary color combinations.

Typography keeps the system font and existing theme sizes/line metrics. Only
headline weights (700/800) and title weights (700) change. Cards and buttons use
20 px corners and flat fills with no card elevation. Existing 48 px button
minimums and system text scaling remain in force.

Seven AI-generated, transparent 2D WebP illustrations extend the original logo:
`hero`, `compare`, `typical`, `redGreen`, `blueYellow`, `broad`, and `recovery` in
`assets/illustrations/`. They use clean navy contours, peach/blue/amber accents
and restrained cel shading, without photographic texture, 3D or drop shadows.
The complete built-in imagegen prompts are in `assets/illustrations/prompts.md`.
Existing icons and scene images are retained. The illustrations total about
200 KiB and require no new runtime dependency.

Home and Guidance share the illustrated navy hero. Guidance adds three numbered
steps while preserving the actual original/simulated image demonstration; its
comparison labels now wrap at large text sizes. Each result has a verdict-specific
illustration and a subtle surface tint while retaining the amber border, amber
icon backing, written verdict, group miss rates and screening disclaimer. The
art does not claim a diagnosis. Explore scene captions use the violet accent
without altering thumbnail pixels. Photo/renderer errors and camera fallback
panels add the recovery illustration alongside the existing message and actions.

### Reproduce the visual/accessibility review

```sh
flutter analyze
flutter test
FLUTTER_ROOT="$(dirname "$(dirname "$(command -v flutter)")")" \
  flutter test test/redesign_test.dart \
  --dart-define=DESIGN_PREVIEW_DIR=/tmp/my-eyes-design-previews
```

The optional preview export uses the SDK's default Roboto and Material Icons
fonts. It renders Home and all four results in light/dark, then reimports their
PNG screenshots using `loadPhoto` and renders them with the production
`VisionImage` shader at full protan/deutan/tritan severity. This exercises the
same decoding and shader rendering used after choosing a photo; the native
photo-picker dialog is not automated. Normal test runs write no screenshot
files and skip only this optional export step. Layout tests also exercise Home,
Guidance and all result variants at 320 px with 200% system text scaling.

Automated widget previews do not replace physical-device camera, permission,
GPU/backend and screen calibration checks. Those remain necessary before a
release. Existing end-to-end widget tests cover scene selection, comparison,
settings, filter picking and the complete screening flow.

Verified on 2026-11-18: `flutter analyze --no-pub` reported no issues;
`flutter test --no-pub` passed 98 tests, skipping the opt-in screenshot export;
the preview-enabled run passed all 13 review tests (including the real shader
reimport). `flutter build web --no-pub --no-web-resources-cdn` succeeded and
included all seven WebP assets. Light/dark Home screenshot sets were visually
reviewed at original, protan, deutan and tritan settings; the five fills remain
separated in lightness. All four light/dark result variants were also reviewed.
The same review suite walked through Vision Picker, camera fallback, Explore,
Learn, scene simulation and comparison in both themes.
