import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../models/plate.dart';

// ---------------------------------------------------------------------------
// Dot plate rendering
// ---------------------------------------------------------------------------

/// 5x7 bitmap glyphs, so a digit can be drawn without a font path or an
/// offscreen image — a dot just looks up the cell its center lands in.
const glyphs = <int, List<String>>{
  0: ['01110', '10001', '10011', '10101', '11001', '10001', '01110'],
  1: ['00100', '01100', '00100', '00100', '00100', '00100', '01110'],
  2: ['01110', '10001', '00001', '00010', '00100', '01000', '11111'],
  3: ['01110', '10001', '00001', '00110', '00001', '10001', '01110'],
  4: ['00010', '00110', '01010', '10010', '11111', '00010', '00010'],
  5: ['11111', '10000', '11110', '00001', '00001', '10001', '01110'],
  6: ['00110', '01000', '10000', '11110', '10001', '10001', '01110'],
  7: ['11111', '00001', '00010', '00100', '01000', '01000', '01000'],
  8: ['01110', '10001', '10001', '01110', '10001', '10001', '01110'],
  9: ['01110', '10001', '10001', '01111', '00001', '00010', '01100'],
};

/// True when ([x], [y]) in unit plate coordinates falls on the digit stroke.
bool onGlyph(int digit, double x, double y) {
  final glyph = glyphs[digit];
  if (glyph == null) return false;
  // Glyph box centered in the plate, 5:7 aspect, ~0.45 of the diameter wide.
  const w = .45, h = w * 7 / 5;
  final gx = (x - (1 - w) / 2) / w;
  final gy = (y - (1 - h) / 2) / h;
  if (gx < 0 || gx >= 1 || gy < 0 || gy >= 1) return false;
  return glyph[(gy * 7).floor()][(gx * 5).floor()] == '1';
}

class PlatePainter extends CustomPainter {
  const PlatePainter(this.plate, this.seed);
  final Plate plate;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final edge = math.min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = edge / 2;
    final random = math.Random(seed);
    final paint = Paint();
    // Jittered grid: one dot per cell keeps dots apart without a packing pass.
    const cells = 26;
    final step = edge / cells;
    for (var row = 0; row < cells; row++) {
      for (var column = 0; column < cells; column++) {
        final dx = (column + .15 + random.nextDouble() * .7) * step;
        final dy = (row + .15 + random.nextDouble() * .7) * step;
        final point = Offset(center.dx - radius + dx, center.dy - radius + dy);
        if ((point - center).distance > radius - step * .6) continue;
        final figure = onGlyph(plate.digit, dx / edge, dy / edge);
        paint.color = figure ? plate.figure : plate.ground;
        canvas.drawCircle(
          point,
          step * (.26 + random.nextDouble() * .17),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(PlatePainter old) =>
      old.plate != plate || old.seed != seed;
}
