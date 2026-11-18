import 'dart:async';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../i18n/copy.dart';
import '../models/scene.dart';
import '../services/media.dart';
import '../vision/filters.dart';
import '../vision/vision_copy.dart';
import 'image_frame.dart';

class OnboardingExample extends StatefulWidget {
  const OnboardingExample({super.key, required this.program});
  final ui.FragmentProgram program;

  @override
  State<OnboardingExample> createState() => _OnboardingExampleState();
}

class _OnboardingExampleState extends State<OnboardingExample> {
  ui.Image? image;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final loaded = await loadScene(scenes.first.asset);
      if (!mounted) {
        loaded.dispose();
        return;
      }
      setState(() => image = loaded);
    } catch (_) {
      // Onboarding text is still available if the bundled example is unreadable.
    }
  }

  @override
  void dispose() {
    image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = image;
    if (current == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(context.t('Original', 'Ảnh gốc'))),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                filterName(context, allFilters.first),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ImageFrame(
          image: current,
          program: widget.program,
          filter: allFilters.first,
          severity: 1,
          split: .5,
          label: context.copy(scenes.first.alt),
        ),
      ],
    );
  }
}
