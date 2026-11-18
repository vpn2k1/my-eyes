import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../i18n/copy.dart';
import '../models/eye_test_score.dart';
import '../models/plate.dart';
import '../theme/palette.dart';
import '../vision/filters.dart';
import '../vision/vision.dart';
import '../vision/vision_copy.dart';
import '../widgets/app_icon.dart';
import '../widgets/page_column.dart';
import '../widgets/plate_painter.dart';

/// Every plate asked once as a dot plate and once as a swatch grid.
/// Pops a [VisionMode] when the user wants to view the camera as that type,
/// or null to go back and choose manually.
class EyeTest extends StatefulWidget {
  const EyeTest({super.key});

  @override
  State<EyeTest> createState() => _EyeTestState();
}

class _EyeTestState extends State<EyeTest> {
  int _index = 0;
  final _score = <VisionMode, int>{
    VisionMode.protan: 0,
    VisionMode.deutan: 0,
    VisionMode.tritan: 0,
  };

  bool get _isDots => _index < plates.length;
  Plate get _plate => plates[_index % plates.length];

  /// Which of the four swatches is the odd one out, fixed per question.
  int get _oddSwatch => (_index * 7 + 2) % 4;

  /// Four digit choices including the answer, stable per question.
  List<int> get _choices {
    final answer = _plate.digit;
    final pool = glyphs.keys.where((d) => d != answer).toList()
      ..shuffle(math.Random(_index + 1));
    return [answer, ...pool.take(3)]..sort();
  }

  void _answer({required bool correct}) {
    if (!correct) {
      for (final axis in _plate.axes) {
        _score[axis] = _score[axis]! + 1;
      }
    }
    if (_index + 1 < questionCount) {
      setState(() => _index++);
      return;
    }
    final verdict = verdictOf(_score);
    setState(() => _index = questionCount);
    unawaited(_showResult(verdict));
  }

  Future<void> _showResult(Verdict verdict) async {
    final mode = suggestedMode(verdict, _score);
    final chosen = await Navigator.of(context).push<VisionFilter?>(
      MaterialPageRoute(
        builder: (_) => _Result(verdict: verdict, mode: mode, score: _score),
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(chosen);
  }

  @override
  Widget build(BuildContext context) {
    if (_index >= questionCount) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final plate = _plate;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('Check your eyes', 'Kiểm tra mắt bạn')),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: _index / questionCount),
        ),
      ),
      body: PageColumn(
        children: [
          _QuestionHeader(
            step: _index + 1,
            total: questionCount,
            prompt: _isDots
                ? context.t(
                    'Which number do you see?',
                    'Bạn thấy số nào trong hình?',
                  )
                : context.t(
                    'Which square is a different color?',
                    'Ô nào khác màu với ba ô còn lại?',
                  ),
          ),
          const SizedBox(height: 24),
          if (_isDots)
            _DotPlate(plate: plate, seed: _index)
          else
            _SwatchGrid(
              colors: [
                for (var i = 0; i < 4; i++)
                  i == _oddSwatch ? plate.figure : plate.ground,
              ],
              onPick: (index) => _answer(correct: index == _oddSwatch),
            ),
          const SizedBox(height: 24),
          if (_isDots)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final digit in _choices)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      fixedSize: const Size(72, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => _answer(correct: digit == plate.digit),
                    child: Text(
                      '$digit',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 8),
          // Always available: "not sure" counts as a miss, which is the point.
          Center(
            child: TextButton.icon(
              onPressed: () => _answer(correct: false),
              icon: const AppIcon(AppIcons.help),
              label: Text(context.t('Not sure / Skip', 'Không rõ / Bỏ qua')),
            ),
          ),
        ],
      ),
    );
  }
}

/// Centered "Question 3 of 20" pill above the question itself.
/// Keeps the prompt and the figure on the same center line instead of a
/// left-aligned prompt above a centered plate.
class _QuestionHeader extends StatelessWidget {
  const _QuestionHeader({
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
class _SwatchGrid extends StatelessWidget {
  const _SwatchGrid({required this.colors, required this.onPick});
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

class _DotPlate extends StatelessWidget {
  const _DotPlate({required this.plate, required this.seed});
  final Plate plate;
  final int seed;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Center(
      child: Semantics(
        // Naming the digit here would hand over the answer, so describe the
        // task instead: this question can only be answered by seeing color.
        label: context.t(
          'Color dot plate. This question needs color vision to answer; choose Not sure to skip it.',
          'Đĩa chấm màu. Câu này cần nhìn màu mới trả lời được; chọn Không rõ để bỏ qua.',
        ),
        excludeSemantics: true,
        child: SizedBox.square(
          dimension: math.min(constraints.maxWidth, 320),
          child: CustomPaint(painter: PlatePainter(plate, seed)),
        ),
      ),
    ),
  );
}

class _Result extends StatelessWidget {
  const _Result({
    required this.verdict,
    required this.mode,
    required this.score,
  });
  final Verdict verdict;
  final VisionMode? mode;
  final Score score;

  String _share(BuildContext context, Group group) {
    final percent = (missRate(score, group) * 100).round();
    final label = switch (group) {
      Group.redGreen => context.t('Red – green', 'Đỏ – xanh lá'),
      Group.blueYellow => context.t('Blue – yellow', 'Xanh dương – vàng'),
    };
    return context.t('$label: $percent% missed', '$label: sai $percent%');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accents = AppAccents.of(context);
    final accent = switch (verdict) {
      Verdict.typical => accents.correction,
      Verdict.redGreen => accents.photo,
      Verdict.blueYellow => accents.experience,
      Verdict.broad => accents.explore,
    };
    final illustration = switch (verdict) {
      Verdict.typical => 'typical',
      Verdict.redGreen => 'redGreen',
      Verdict.blueYellow => 'blueYellow',
      Verdict.broad => 'broad',
    };
    return Scaffold(
      appBar: AppBar(title: Text(context.t('Result', 'Kết quả'))),
      body: PageColumn(
        children: [
          Card(
            color: Color.alphaBlend(
              accent.accent.withValues(alpha: .10),
              theme.colorScheme.surface,
            ),
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: brandAmber, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Image.asset(
                      'assets/illustrations/$illustration.webp',
                      width: 160,
                      height: 110,
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          color: brandAmber,
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: AppIcon(AppIcons.info, size: 20),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.t('Indicative result', 'Kết quả tham khảo'),
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.copy(verdictText(verdict)),
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  // Both groups every time, so a clean group is visible too.
                  for (final group in Group.values)
                    Text(
                      _share(context, group),
                      style: theme.textTheme.bodyMedium,
                    ),
                  if (mode case final suggested?) ...[
                    const SizedBox(height: 8),
                    Text(
                      context.t(
                        'Closest simulation: ${modeName(context, suggested)}.',
                        'Mô phỏng gần nhất: ${modeName(context, suggested)}.',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(context.copy(screeningNotice)),
          const SizedBox(height: 8),
          Text(context.copy(simulationNotice)),
          const SizedBox(height: 20),
          if (mode case final suggested?) ...[
            FilledButton.icon(
              onPressed: () =>
                  Navigator.of(context).pop(defaultFilterFor(suggested)),
              icon: const AppIcon(AppIcons.video),
              label: Text(
                context.t(
                  'View camera as this type',
                  'Dùng loại này để xem camera',
                ),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.of(context).pop(defaultCorrectionFor(suggested)),
              icon: const AppIcon(AppIcons.palette),
              label: Text(
                context.t(
                  'Use a correction filter instead',
                  'Dùng bộ lọc hỗ trợ phân biệt màu',
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.t('Choose another type', 'Chọn loại khác')),
          ),
        ],
      ),
    );
  }
}
