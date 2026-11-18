import 'dart:ui' show Color, FragmentShader;

import 'glasses_matrices.dart';
import 'vision.dart';

/// Loss a 3x3 color matrix cannot express: blur, a haze over everything, or a
/// part of the visual field that is simply missing.
class VisionEffect {
  const VisionEffect({
    this.blur = 0,
    this.vignette = 0,
    this.scotoma = 0,
    this.scrim,
  });

  /// Gaussian sigma, in logical pixels.
  final double blur;

  /// Peripheral field loss, 0 (none) to 1 (only a small center remains).
  final double vignette;

  /// Central blind spot, as a fraction of the frame's inscribed radius.
  final double scotoma;

  /// Translucent film laid over the frame.
  final Color? scrim;
}

/// One entry in the picker: a [VisionMode] plus the preset strength, direction
/// and extra loss that give it a clinical name of its own.
///
/// shortcut: every instance in the app is a `const` from [filterCatalog], so
/// selection compares by identity and this class needs no `==`. Give it one if
/// filters ever start being built at runtime.
class VisionFilter {
  const VisionFilter(
    this.id,
    this.mode, {
    this.severity = 1,
    this.correct = false,
    this.effect,
    this.matrix,
  });

  /// Stable key for copy lookup; never shown to the user.
  final String id;
  final VisionMode mode;

  /// Starting point for the strength slider.
  final double severity;

  /// Shifts colors apart to help someone with [mode] rather than simulating it.
  final bool correct;
  final VisionEffect? effect;

  /// Overrides the [mode]/[correct] simulation table with a literal matrix -
  /// used for presets modeling a real glasses product rather than a vision
  /// deficiency. [mode] is kept only so this filter still has a severity
  /// slider and a copy fallback.
  final List<double>? matrix;

  /// Whether the strength slider applies: either the usual per-mode table,
  /// or a literal [matrix] blended against identity.
  bool get hasSeverity => mode.hasSeverity || matrix != null;
}

/// The [filter]'s matrix at [severity]: its literal [VisionFilter.matrix],
/// blended with identity by severity, or the usual deficiency simulation.
List<double> visionMatrixFor(VisionFilter filter, double severity) {
  if (filter.matrix case final glasses?) {
    final mix = severity.clamp(0.0, 1.0);
    return List.generate(9, (i) => identity[i] * (1 - mix) + glasses[i] * mix);
  }
  return visionMatrix(filter.mode, severity, correct: filter.correct);
}

void setColorMatrixFor(
  FragmentShader shader,
  VisionFilter filter,
  double severity,
) {
  final matrix = visionMatrixFor(filter, severity);
  for (var i = 0; i < matrix.length; i++) {
    shader.setFloat(i + 2, matrix[i]);
  }
}

enum FilterGroup {
  redGreen,
  blueYellow,
  noColor,
  correction,
  realGlasses,
  condition,
}

/// The app's two offerings: simulate a vision difference to experience it,
/// or shift colors apart to help tell them apart.
enum FilterCategory { experience, correction }

FilterCategory categoryOf(FilterGroup group) =>
    group == FilterGroup.correction || group == FilterGroup.realGlasses
    ? FilterCategory.correction
    : FilterCategory.experience;

/// Shown unfiltered beside the simulation in the compare view.
const normalFilter = VisionFilter('normal', VisionMode.normal);

const filterCatalog = <FilterGroup, List<VisionFilter>>{
  FilterGroup.redGreen: [
    VisionFilter('deuteranopia', VisionMode.deutan),
    VisionFilter('deuteranomaly', VisionMode.deutan, severity: .5),
    VisionFilter('protanopia', VisionMode.protan),
    VisionFilter('protanomaly', VisionMode.protan, severity: .5),
  ],
  FilterGroup.blueYellow: [
    VisionFilter('tritanopia', VisionMode.tritan),
    VisionFilter('tritanomaly', VisionMode.tritan, severity: .5),
  ],
  FilterGroup.noColor: [
    VisionFilter('achromatopsia', VisionMode.grayscale),
    VisionFilter('achromatomaly', VisionMode.grayscale, severity: .6),
    VisionFilter('blueConeMonochromacy', VisionMode.blueCone),
  ],
  FilterGroup.correction: [
    VisionFilter('correctDeutan', VisionMode.deutan, correct: true),
    VisionFilter('correctProtan', VisionMode.protan, correct: true),
    VisionFilter('correctTritan', VisionMode.tritan, correct: true),
  ],
  FilterGroup.realGlasses: [
    VisionFilter(
      'notchRedGreen',
      VisionMode.deutan,
      correct: true,
      matrix: notchRedGreenMatrix,
    ),
    VisionFilter(
      'broadTintRedGreen',
      VisionMode.deutan,
      correct: true,
      matrix: broadTintRedGreenMatrix,
    ),
    VisionFilter(
      'monocularRedTint',
      VisionMode.protan,
      correct: true,
      matrix: monocularRedTintMatrix,
    ),
    VisionFilter(
      'tritanTint',
      VisionMode.tritan,
      correct: true,
      matrix: tritanTintMatrix,
    ),
  ],
  FilterGroup.condition: [
    VisionFilter(
      'cataract',
      VisionMode.normal,
      effect: VisionEffect(blur: 3, scrim: Color(0x3affd27f)),
    ),
    VisionFilter(
      'glaucoma',
      VisionMode.normal,
      effect: VisionEffect(vignette: .8),
    ),
    VisionFilter(
      'macularDegeneration',
      VisionMode.normal,
      effect: VisionEffect(scotoma: .3),
    ),
    VisionFilter(
      'nightBlindness',
      VisionMode.normal,
      effect: VisionEffect(blur: 1, scrim: Color(0xaa000814)),
    ),
    // shortcut: myopia/hyperopia/astigmatism all reduce to the same isotropic
    // blur since VisionEffect has no distance- or direction-dependent blur;
    // upgrade VisionEffect if a directional/focal-distance model is needed.
    VisionFilter('myopia', VisionMode.normal, effect: VisionEffect(blur: 2.5)),
    VisionFilter(
      'hyperopia',
      VisionMode.normal,
      effect: VisionEffect(blur: 1.5),
    ),
    VisionFilter(
      'astigmatism',
      VisionMode.normal,
      effect: VisionEffect(blur: 2),
    ),
  ],
};

final allFilters = [for (final group in filterCatalog.values) ...group];

/// The complete simulation for [mode], used to turn an eye-test result into a
/// picker selection. Falls back to [normalFilter] for a typical result.
VisionFilter defaultFilterFor(VisionMode mode) => allFilters.firstWhere(
  (filter) => filter.mode == mode && !filter.correct && filter.severity == 1,
  orElse: () => normalFilter,
);

/// The correction preset for [mode], so an eye-test result can offer help
/// telling colors apart instead of only simulating the loss.
VisionFilter defaultCorrectionFor(VisionMode mode) => allFilters.firstWhere(
  (filter) => filter.mode == mode && filter.correct,
  orElse: () => normalFilter,
);
