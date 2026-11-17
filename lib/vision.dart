import 'dart:math' as math;
import 'dart:ui' as ui;

import 'machado.dart';

enum VisionMode {
  normal,
  protan,
  deutan,
  tritan,
  grayscale;

  bool get hasSeverity => this != normal && this != grayscale;
}

const identity = <double>[1, 0, 0, 0, 1, 0, 0, 0, 1];
const _luminance = <double>[.2126, .7152, .0722];

List<double> visionMatrix(VisionMode mode, double severity) {
  if (!severity.isFinite) {
    throw ArgumentError.value(severity, 'severity', 'Must be finite');
  }
  if (mode == VisionMode.normal) return identity;
  if (mode == VisionMode.grayscale) {
    return [..._luminance, ..._luminance, ..._luminance];
  }

  final table = switch (mode) {
    VisionMode.protan => protanMatrices,
    VisionMode.deutan => deutanMatrices,
    VisionMode.tritan => tritanMatrices,
    _ => throw StateError('Unexpected mode'),
  };
  final level = severity.clamp(0.0, 1.0) * 10;
  final lower = level.floor();
  final upper = level.ceil();
  if (lower == upper) return table[lower];
  final mix = level - lower;
  return List.generate(
    9,
    (i) => table[lower][i] * (1 - mix) + table[upper][i] * mix,
  );
}

bool isIdentity(VisionMode mode, double severity) =>
    mode == VisionMode.normal || (mode.hasSeverity && severity == 0);

double _linear(int channel) {
  final c = channel / 255;
  return c <= .04045 ? c / 12.92 : math.pow((c + .055) / 1.055, 2.4).toDouble();
}

int _encoded(double value) {
  final v = value.clamp(0.0, 1.0);
  return (255 *
          (v <= .0031308 ? 12.92 * v : 1.055 * math.pow(v, 1 / 2.4) - .055))
      .round();
}

/// Straight-alpha CPU reference for controlled sRGB fixtures.
List<int> simulatePixel(List<int> rgba, VisionMode mode, double severity) {
  final matrix = visionMatrix(mode, severity);
  final r = _linear(rgba[0]);
  final g = _linear(rgba[1]);
  final b = _linear(rgba[2]);
  return [
    for (var i = 0; i < 9; i += 3)
      _encoded(matrix[i] * r + matrix[i + 1] * g + matrix[i + 2] * b),
    rgba[3],
  ];
}

void setColorMatrix(
  ui.FragmentShader shader,
  VisionMode mode,
  double severity,
) {
  final matrix = visionMatrix(mode, severity);
  for (var i = 0; i < matrix.length; i++) {
    shader.setFloat(i + 2, matrix[i]);
  }
}
