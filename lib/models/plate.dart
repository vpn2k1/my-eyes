import 'dart:ui' show Color;

import '../vision/vision.dart';

/// A pseudoisochromatic color pair: [figure] and [ground] collapse into nearly
/// the same color for someone whose vision matches [axes], but stay clearly
/// different for everyone else.
///
/// [axes] holds one axis for the pairs that tell protan from deutan, and both
/// of them for the classic red–green combos, which collapse for either type —
/// that is what makes them read as the red–green group rather than one axis.
///
/// The pair also matches in lightness, so the answer cannot be found by
/// brightness alone. `test/eye_test_test.dart` asserts all four properties.
class Plate {
  const Plate(this.axes, this.figure, this.ground, this.digit);
  final Set<VisionMode> axes;
  final Color figure, ground;

  /// Digit hidden in the dot plate, and the answer for the swatch question.
  final int digit;
}

/// Found by brute-force search over the RGB grid against the severity 1.0
/// Machado matrices; every pair is re-verified by the unit test.
///
/// A plain yellow–blue pair is deliberately absent: tritan vision confuses
/// blue with green and yellow with pink, so a yellow and a blue that collapse
/// for tritan only exist at different lightness — and a lightness difference
/// hands over the answer without any color vision at all.
const plates = <Plate>[
  // Single-axis pairs, the only ones that can tell protan from deutan apart.
  Plate({VisionMode.protan}, Color(0xff2266bb), Color(0xff8855bb), 6),
  Plate({VisionMode.protan}, Color(0xff2266dd), Color(0xffbb22dd), 3),
  Plate({VisionMode.deutan}, Color(0xff229966), Color(0xffee3377), 5),
  Plate({VisionMode.deutan}, Color(0xff22cc22), Color(0xffee9944), 8),
  // Red–green combos: red/green and orange/green, collapsing for both axes.
  Plate(
    {VisionMode.protan, VisionMode.deutan},
    Color(0xff9a634d),
    Color(0xff42794d),
    4,
  ),
  Plate(
    {VisionMode.protan, VisionMode.deutan},
    Color(0xfffdc637),
    Color(0xffa5dc37),
    9,
  ),
  // Blue–yellow combos: green/teal, blue/green and yellow/pink, the pairs
  // tritan vision actually collapses.
  Plate({VisionMode.tritan}, Color(0xff22dd22), Color(0xff55ccbb), 2),
  Plate({VisionMode.tritan}, Color(0xff55bb22), Color(0xff66aaaa), 7),
  Plate({VisionMode.tritan}, Color(0xff6ebbf2), Color(0xff00d19a), 1),
  Plate({VisionMode.tritan}, Color(0xff846300), Color(0xff8f4d79), 0),
];

/// Every plate asked once as a dot plate and once as a swatch grid.
final questionCount = plates.length * 2;
