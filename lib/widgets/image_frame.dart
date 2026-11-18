import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../vision/filters.dart';
import 'vision_viewport.dart';

class ImageFrame extends StatelessWidget {
  const ImageFrame({
    super.key,
    required this.image,
    required this.program,
    required this.filter,
    required this.severity,
    required this.label,
    this.split,
  });

  final ui.Image image;
  final ui.FragmentProgram program;
  final VisionFilter filter;
  final double severity;
  final String label;
  final double? split;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 430),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: VisionEffectOverlay(
          effect: filter.effect,
          child: VisionImage(
            image: image,
            program: program,
            filter: filter,
            severity: severity,
            label: label,
            split: split,
          ),
        ),
      ),
    ),
  );
}
