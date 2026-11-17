import 'package:flutter_test/flutter_test.dart';
import 'package:my_eyes/vision.dart';

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
}
