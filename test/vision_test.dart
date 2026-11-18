import 'package:flutter_test/flutter_test.dart';
import 'package:my_eyes/vision/vision.dart';

void main() {
  test(
    'normal and zero-strength preserve encoded channels including alpha',
    () {
      for (final source in [
        [0, 0, 0, 0],
        [255, 255, 255, 255],
        [194, 67, 41, 92],
        [20, 43, 230, 255],
      ]) {
        expect(simulatePixel(source, VisionMode.normal, 1), source);
        for (final mode in VisionMode.values.where(
          (item) => item.hasSeverity,
        )) {
          expect(simulatePixel(source, mode, 0), source);
        }
      }
    },
  );

  test('published end-point red primary and linear-luminance fixtures', () {
    const source = [255, 0, 0, 211];
    expect(simulatePixel(source, VisionMode.protan, 1), [109, 95, 0, 211]);
    expect(simulatePixel(source, VisionMode.deutan, 1), [163, 144, 0, 211]);
    expect(simulatePixel(source, VisionMode.tritan, 1), [255, 0, 15, 211]);
    expect(simulatePixel(source, VisionMode.grayscale, 1), [
      127,
      127,
      127,
      211,
    ]);
  });

  test('severity uses adjacent rows and clamps out-of-range values', () {
    for (final mode in VisionMode.values.where((item) => item.hasSeverity)) {
      final low = visionMatrix(mode, .5);
      final high = visionMatrix(mode, .6);
      final middle = visionMatrix(mode, .55);
      for (var i = 0; i < 9; i++) {
        expect(middle[i], closeTo((low[i] + high[i]) / 2, 1e-9));
      }
      expect(visionMatrix(mode, -1), identity);
      expect(visionMatrix(mode, 2), visionMatrix(mode, 1));
      expect(() => visionMatrix(mode, double.nan), throwsArgumentError);
    }
  });

  test('daltonization leaves the original alone at zero strength', () {
    for (final mode in VisionMode.values.where((item) => item.hasSeverity)) {
      expect(visionMatrix(mode, 0, correct: true), identity);
    }
  });

  test('daltonization separates colors the simulation collapses', () {
    // A red and an olive green a protanope sees as nearly the same color.
    const a = [220, 70, 60, 255];
    const b = [140, 130, 40, 255];
    List<int> seen(List<int> color, {required bool corrected}) => simulatePixel(
      corrected
          ? simulatePixel(color, VisionMode.protan, 1, correct: true)
          : color,
      VisionMode.protan,
      1,
    );
    int gap(bool corrected) {
      final first = seen(a, corrected: corrected);
      final second = seen(b, corrected: corrected);
      return [
        for (var i = 0; i < 3; i++) (first[i] - second[i]).abs(),
      ].reduce((x, y) => x + y);
    }

    expect(gap(true), greaterThan(gap(false)));
  });
}
