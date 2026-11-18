import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../i18n/copy.dart';
import '../vision/vision_copy.dart';
import '../widgets/hero_card.dart';
import '../widgets/onboarding_example.dart';
import '../widgets/page_column.dart';

class Guidance extends StatelessWidget {
  const Guidance({super.key, required this.program, this.finish});
  final Future<ui.FragmentProgram> program;
  final VoidCallback? finish;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('My Eyes'),
      actions: [
        if (finish != null)
          TextButton(
            onPressed: finish,
            child: Text(context.t('Skip', 'Bỏ qua')),
          ),
      ],
    ),
    body: PageColumn(
      children: [
        HeroCard(
          title: context.t(
            'See through\nmy eyes.',
            'Nhìn qua\nđôi mắt của tôi.',
          ),
          body: context.t(
            'Explore different ways people perceive color.',
            'Khám phá những cách khác nhau mà con người cảm nhận màu sắc.',
          ),
        ),
        const SizedBox(height: 20),
        FutureBuilder<ui.FragmentProgram>(
          future: program,
          builder: (context, snapshot) => snapshot.hasData
              ? OnboardingExample(program: snapshot.requireData)
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),
        Text(context.copy(simulationNotice)),
        const SizedBox(height: 16),
        if (finish != null)
          FilledButton(
            onPressed: finish,
            child: Text(context.t('Start exploring', 'Bắt đầu trải nghiệm')),
          ),
      ],
    ),
  );
}
