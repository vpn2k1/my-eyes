import 'dart:ui' show Color;
import 'dart:math' as math;
import 'dart:typed_data' show ByteData;
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:my_eyes/eye_test.dart';
import 'package:my_eyes/vision.dart';

List<int> _rgba(Color color) => [
  (color.r * 255).round(),
  (color.g * 255).round(),
  (color.b * 255).round(),
  255,
];

int _maxDiff(List<int> a, List<int> b) {
  var worst = 0;
  for (var i = 0; i < 3; i++) {
    worst = math.max(worst, (a[i] - b[i]).abs());
  }
  return worst;
}

int _diffAs(Color a, Color b, VisionMode mode) => _maxDiff(
  simulatePixel(_rgba(a), mode, 1),
  simulatePixel(_rgba(b), mode, 1),
);

/// Perceived lightness as an sRGB gray, so a pair can be checked for the
/// brightness cue that would let anyone solve the plate without seeing color.
int _gray(Color color) =>
    simulatePixel(_rgba(color), VisionMode.grayscale, 1)[0];

void main() {
  group('plate colors', () {
    for (final plate in plates) {
      final label = '${plate.axes.map((a) => a.name).join('+')} ${plate.digit}';

      test('$label collapses for every axis it claims', () {
        for (final axis in plate.axes) {
          expect(
            _diffAs(plate.figure, plate.ground, axis),
            lessThan(13),
            reason: '$label must collapse for ${axis.name}',
          );
        }
      });

      test('$label is clearly different in typical vision', () {
        expect(
          _maxDiff(_rgba(plate.figure), _rgba(plate.ground)),
          greaterThanOrEqualTo(60),
        );
      });

      test('$label stays separable on the axes it does not claim', () {
        for (final other in [
          VisionMode.protan,
          VisionMode.deutan,
          VisionMode.tritan,
        ]) {
          if (plate.axes.contains(other)) continue;
          expect(
            _diffAs(plate.figure, plate.ground, other),
            greaterThanOrEqualTo(40),
            reason: '$label must not collapse for ${other.name} too',
          );
        }
      });

      // Without this the plate is solvable by brightness and measures nothing.
      test('$label carries no brightness cue', () {
        expect(
          (_gray(plate.figure) - _gray(plate.ground)).abs(),
          lessThanOrEqualTo(6),
        );
      });
    }

    test('every axis gets the same number of questions', () {
      for (final axis in [
        VisionMode.protan,
        VisionMode.deutan,
        VisionMode.tritan,
      ]) {
        expect(
          creditsFor(axis),
          8,
          reason: '${axis.name} should be asked eight times',
        );
      }
      expect(questionCount, 20);
    });

    test('both groups are covered by combos as well as single axes', () {
      // Combos are what make the red-green group readable as a group; without
      // them a red/green pair could only be scored as one axis.
      expect(
        plates.where((p) => p.axes.length > 1).length,
        greaterThanOrEqualTo(2),
      );
      for (final axis in [
        VisionMode.protan,
        VisionMode.deutan,
        VisionMode.tritan,
      ]) {
        expect(
          plates.where((p) => p.axes.length == 1 && p.axes.first == axis),
          isNotEmpty,
          reason: '${axis.name} needs a single-axis plate of its own',
        );
      }
    });

    test('no two plates hide the same digit', () {
      expect(plates.map((p) => p.digit).toSet().length, plates.length);
    });

    test('every digit draws a readable glyph', () {
      for (final plate in plates) {
        // Probe all 35 cell centers of the 5x7 box inside the plate.
        const w = .45, h = w * 7 / 5;
        var filled = 0, empty = 0;
        for (var row = 0; row < 7; row++) {
          for (var column = 0; column < 5; column++) {
            final x = (1 - w) / 2 + (column + .5) / 5 * w;
            final y = (1 - h) / 2 + (row + .5) / 7 * h;
            onGlyph(plate.digit, x, y) ? filled++ : empty++;
          }
        }
        expect(
          filled,
          greaterThanOrEqualTo(7),
          reason: 'digit ${plate.digit} has too little stroke to read',
        );
        expect(
          empty,
          greaterThanOrEqualTo(7),
          reason: 'digit ${plate.digit} is a solid block, not a digit',
        );
      }
    });

    test('nothing is drawn outside the glyph box', () {
      expect(onGlyph(plates.first.digit, .02, .02), isFalse);
      expect(onGlyph(plates.first.digit, .98, .98), isFalse);
    });
  });

  group('scoring', () {
    Score score(int protan, int deutan, int tritan) => {
      VisionMode.protan: protan,
      VisionMode.deutan: deutan,
      VisionMode.tritan: tritan,
    };

    test('a clean run reads as typical', () {
      expect(verdictOf(score(2, 1, 2)), Verdict.typical);
      expect(suggestedMode(Verdict.typical, score(2, 1, 2)), isNull);
    });

    test('red-green misses read as red-green', () {
      expect(verdictOf(score(4, 4, 0)), Verdict.redGreen);
      expect(verdictOf(score(2, 6, 1)), Verdict.redGreen);
    });

    test('blue-yellow misses read as blue-yellow', () {
      final result = score(0, 1, 3);
      expect(verdictOf(result), Verdict.blueYellow);
      expect(suggestedMode(Verdict.blueYellow, result), VisionMode.tritan);
    });

    test('misses in both groups read as broad', () {
      expect(verdictOf(score(4, 4, 3)), Verdict.broad);
    });

    test('a full miss is reported as every question missed', () {
      final all = score(
        creditsFor(VisionMode.protan),
        creditsFor(VisionMode.deutan),
        creditsFor(VisionMode.tritan),
      );
      expect(missRate(all, Group.redGreen), 1);
      expect(missRate(all, Group.blueYellow), 1);
      expect(verdictOf(all), Verdict.broad);
    });

    test('a single slip never flags a group', () {
      for (final result in [score(1, 0, 0), score(0, 1, 0), score(0, 0, 1)]) {
        expect(verdictOf(result), Verdict.typical);
      }
    });

    test('protan is only suggested on a clear margin', () {
      // Thin margin -> fall back to the common form rather than overclaiming.
      expect(
        suggestedMode(Verdict.redGreen, score(3, 2, 0)),
        VisionMode.deutan,
      );
      expect(
        suggestedMode(Verdict.redGreen, score(4, 0, 0)),
        VisionMode.protan,
      );
      expect(
        suggestedMode(Verdict.redGreen, score(0, 4, 0)),
        VisionMode.deutan,
      );
    });
  });

  group('dot plate rendering', () {
    /// Paints a plate and reports, for a column of the plate, whether any
    /// figure-colored pixel appears there.
    Future<bool> hasFigureNear(Plate plate, double x) async {
      const size = 240.0;
      final recorder = ui.PictureRecorder();
      PlatePainter(
        plate,
        1,
      ).paint(ui.Canvas(recorder), const ui.Size(size, size));
      final image = await recorder.endRecording().toImage(
        size.toInt(),
        size.toInt(),
      );
      addTearDown(image.dispose);
      final bytes = (await image.toByteData())!;
      final target = _rgba(plate.figure);
      for (var y = 0; y < size; y++) {
        final px = (x * size).round();
        final offset = (y * size.toInt() + px) * 4;
        final pixel = [
          bytes.getUint8(offset),
          bytes.getUint8(offset + 1),
          bytes.getUint8(offset + 2),
          bytes.getUint8(offset + 3),
        ];
        if (pixel[3] > 200 && _maxDiff(pixel, target) <= 4) return true;
      }
      return false;
    }

    test('the digit lands inside the glyph box, not the margin', () async {
      final plate = plates.first;
      // Center column crosses the digit; the outer margin never should.
      expect(await hasFigureNear(plate, .5), isTrue);
      expect(await hasFigureNear(plate, .06), isFalse);
      expect(await hasFigureNear(plate, .94), isFalse);
    });

    test('the same seed paints the same plate twice', () async {
      Future<ByteData> render() async {
        final recorder = ui.PictureRecorder();
        PlatePainter(
          plates.first,
          3,
        ).paint(ui.Canvas(recorder), const ui.Size(120, 120));
        final image = await recorder.endRecording().toImage(120, 120);
        addTearDown(image.dispose);
        return (await image.toByteData())!;
      }

      expect(
        (await render()).buffer.asUint8List(),
        (await render()).buffer.asUint8List(),
      );
    });
  });
}
