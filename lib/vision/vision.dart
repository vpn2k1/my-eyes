import 'dart:math' as math;

import 'machado.dart';

enum VisionMode {
  normal,
  protan,
  deutan,
  tritan,
  blueCone,
  grayscale;

  bool get hasSeverity => this != normal;
}

const identity = <double>[1, 0, 0, 0, 1, 0, 0, 0, 1];
const _luminance = <double>[.2126, .7152, .0722];
const _grayscaleMatrix = <double>[
  ..._luminance,
  ..._luminance,
  ..._luminance,
];

/// Redistributes the signal a deficient eye loses into the channels it can
/// still tell apart. From Fidaner, Lin and Ozguven's daltonization; derived
/// for protanopia, so it is an approximation on the other axes.
const _shift = <double>[0, 0, 0, .7, 1, 0, .7, 0, 1];

List<double> _multiply(List<double> a, List<double> b) => [
  for (var row = 0; row < 9; row += 3)
    for (var col = 0; col < 3; col++)
      a[row] * b[col] + a[row + 1] * b[col + 3] + a[row + 2] * b[col + 6],
];

List<double> _lerp(List<double> a, List<double> b, double mix) =>
    List.generate(9, (i) => a[i] * (1 - mix) + b[i] * mix);

/// Reads [table] at [severity], interpolating between its 11 published steps.
List<double> _step(List<List<double>> table, double severity) {
  final level = severity.clamp(0.0, 1.0) * 10;
  final lower = level.floor();
  final upper = level.ceil();
  if (lower == upper) return table[lower];
  return _lerp(table[lower], table[upper], level - lower);
}

List<double> _simulated(VisionMode mode, double severity) => switch (mode) {
  VisionMode.normal => identity,
  VisionMode.grayscale => _lerp(
    identity,
    _grayscaleMatrix,
    severity.clamp(0.0, 1.0),
  ),
  VisionMode.protan => _step(protanMatrices, severity),
  VisionMode.deutan => _step(deutanMatrices, severity),
  VisionMode.tritan => _step(tritanMatrices, severity),
  VisionMode.blueCone => _lerp(
    identity,
    _blueConeMatrix,
    severity.clamp(0.0, 1.0),
  ),
};

/// Blue cone monochromacy loses both the L and the M cone, so it is modelled
/// by composing the two complete single-cone simulations. No published matrix
/// of its own; treat it as the roughest entry in the set.
final _blueConeMatrix = _multiply(protanMatrices.last, deutanMatrices.last);

/// The 3x3 matrix for [mode] at [severity]. With [correct] it returns the
/// daltonization that helps such an eye instead of the simulation of it.
List<double> visionMatrix(
  VisionMode mode,
  double severity, {
  bool correct = false,
}) {
  if (!severity.isFinite) {
    throw ArgumentError.value(severity, 'severity', 'Must be finite');
  }
  final simulated = _simulated(mode, severity);
  if (!correct) return simulated;
  final lost = List.generate(9, (i) => identity[i] - simulated[i]);
  final shifted = _multiply(_shift, lost);
  return List.generate(9, (i) => identity[i] + shifted[i]);
}

/// At severity 0 the simulation and its correction are both the original.
bool isIdentity(VisionMode mode, double severity) =>
    mode == VisionMode.normal || severity == 0;

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
List<int> simulatePixel(
  List<int> rgba,
  VisionMode mode,
  double severity, {
  bool correct = false,
}) {
  final matrix = visionMatrix(mode, severity, correct: correct);
  final r = _linear(rgba[0]);
  final g = _linear(rgba[1]);
  final b = _linear(rgba[2]);
  return [
    for (var i = 0; i < 9; i += 3)
      _encoded(matrix[i] * r + matrix[i + 1] * g + matrix[i + 2] * b),
    rgba[3],
  ];
}
