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
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (final step in [
                  (
                    'hero',
                    context.t(
                      '1. Explore a perspective',
                      '1. Khám phá góc nhìn',
                    ),
                    context.t(
                      'Choose a photo, a scene or the camera.',
                      'Chọn ảnh, tình huống mẫu hoặc camera.',
                    ),
                  ),
                  (
                    'compare',
                    context.t(
                      '2. Compare side by side',
                      '2. So sánh hai cách nhìn',
                    ),
                    context.t(
                      'Use the divider to compare with the original.',
                      'Kéo đường chia để so sánh với ảnh gốc.',
                    ),
                  ),
                  (
                    'typical',
                    context.t(
                      '3. Learn about your vision',
                      '3. Tìm hiểu sắc giác',
                    ),
                    context.t(
                      'Try a screening to learn more, then seek professional advice.',
                      'Thử bài sàng lọc. Bài test không thay thế chẩn đoán.',
                    ),
                  ),
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/illustrations/${step.$1}.webp',
                          width: 64,
                          height: 64,
                          fit: BoxFit.contain,
                          excludeFromSemantics: true,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                step.$2,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(step.$3),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
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
