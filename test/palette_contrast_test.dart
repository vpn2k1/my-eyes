import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_eyes/theme/palette.dart';
import 'package:my_eyes/vision/vision.dart';

List<FeatureAccent> features(AppAccents accents) => [
  accents.experience,
  accents.correction,
  accents.photo,
  accents.screening,
  accents.explore,
];

double contrast(Color a, Color b) {
  final x = a.computeLuminance();
  final y = b.computeLuminance();
  return (math.max(x, y) + .05) / (math.min(x, y) + .05);
}

Color simulated(Color color, VisionMode mode) {
  final rgba = simulatePixel(
    [
      (color.r * 255).round(),
      (color.g * 255).round(),
      (color.b * 255).round(),
      255,
    ],
    mode,
    1,
  );
  return Color.fromARGB(255, rgba[0], rgba[1], rgba[2]);
}

void main() {
  for (final entry in {
    'light': AppAccents.light,
    'dark': AppAccents.dark,
  }.entries) {
    final accents = features(entry.value);
    test('${entry.key} feature labels and controls meet AA contrast', () {
      for (final pair in accents) {
        // 4.5 also exceeds the 3:1 bar for large text and control glyphs.
        expect(contrast(pair.accent, pair.onAccent), greaterThanOrEqualTo(4.5));
      }
      expect(entry.value.screening.accent, brandAmber);
    });

    for (final mode in [
      VisionMode.normal,
      VisionMode.protan,
      VisionMode.deutan,
      VisionMode.tritan,
    ]) {
      test(
        '${entry.key} accents retain luminance separation under ${mode.name}',
        () {
          final luminances = [
            for (final pair in accents)
              simulated(pair.accent, mode).computeLuminance(),
          ]..sort();
          for (var i = 1; i < luminances.length; i++) {
            // Regression guard, not a claim of a perceptual accessibility standard.
            expect(luminances[i] - luminances[i - 1], greaterThan(.045));
          }
        },
      );
    }
  }

  test('theme extension preserves endpoints and interpolates all pairs', () {
    final midpoint = AppAccents.light.lerp(AppAccents.dark, .5);
    final a = features(AppAccents.light);
    final b = features(AppAccents.dark);
    final m = features(midpoint);
    for (var i = 0; i < a.length; i++) {
      expect(m[i].accent, Color.lerp(a[i].accent, b[i].accent, .5));
      expect(m[i].onAccent, Color.lerp(a[i].onAccent, b[i].onAccent, .5));
    }
    expect(AppAccents.light.copyWith().experience, AppAccents.light.experience);
    expect(AppAccents.light.lerp(null, .5), same(AppAccents.light));
  });
}
