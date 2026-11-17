import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'content.dart';

class PageColumn extends StatelessWidget {
  const PageColumn({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    ),
  );
}

/// Centered "Question 3 of 20" pill above the question itself.
/// Keeps the prompt and the figure on the same center line instead of a
/// left-aligned prompt above a centered plate.
class QuestionHeader extends StatelessWidget {
  const QuestionHeader({
    super.key,
    required this.step,
    required this.total,
    required this.prompt,
  });
  final int step, total;
  final String prompt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Text(
              context.t('Question $step of $total', 'Câu $step / $total'),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          prompt,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
      ],
    );
  }
}

/// Tappable squares, one of which is the odd one out. Sizes itself to the
/// width it is given, so it stays centered and never overflows on a narrow
/// phone.
class SwatchGrid extends StatelessWidget {
  const SwatchGrid({super.key, required this.colors, required this.onPick});
  final List<Color> colors;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final edge = (math.min(constraints.maxWidth, 320) - 12) / 2;
      return Center(
        child: SizedBox(
          width: edge * 2 + 12,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              for (var i = 0; i < colors.length; i++)
                Semantics(
                  label: context.t('Square ${i + 1}', 'Ô ${i + 1}'),
                  button: true,
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: () => onPick(i),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: edge,
                      height: edge,
                      decoration: BoxDecoration(
                        color: colors[i],
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
