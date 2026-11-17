import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'content.dart';
import 'page_column.dart';
import 'palette.dart';
import 'vision.dart';

/// A pseudoisochromatic color pair: [figure] and [ground] collapse into nearly
/// the same color for someone with [axis] vision, but stay clearly different
/// for everyone else — including the other two axes, which is what lets the
/// test tell the types apart.
///
/// The pair also matches in lightness, so the answer cannot be found by
/// brightness alone. `test/eye_test_test.dart` asserts all four properties.
class Plate {
  const Plate(this.axis, this.figure, this.ground, this.digit);
  final VisionMode axis;
  final Color figure, ground;

  /// Digit hidden in the dot plate, and the answer for the swatch question.
  final int digit;
}

/// Found by brute-force search over the RGB grid against the severity 1.0
/// Machado matrices; every pair is re-verified by the unit test.
const plates = <Plate>[
  Plate(VisionMode.protan, Color(0xff2266bb), Color(0xff8855bb), 6),
  Plate(VisionMode.protan, Color(0xff2266dd), Color(0xffbb22dd), 3),
  Plate(VisionMode.deutan, Color(0xff229966), Color(0xffee3377), 5),
  Plate(VisionMode.deutan, Color(0xff22cc22), Color(0xffee9944), 8),
  Plate(VisionMode.tritan, Color(0xff22dd22), Color(0xff55ccbb), 2),
  Plate(VisionMode.tritan, Color(0xff55bb22), Color(0xff66aaaa), 7),
];

/// The 12 questions: every plate asked once as a dot plate and once as a
/// swatch grid, so each axis gets four questions.
final questionCount = plates.length * 2;

/// Misses (wrong answers and "not sure") per axis.
typedef Score = Map<VisionMode, int>;

enum Verdict { typical, redGreen, blueYellow, broad }

/// Axis a [Verdict] should preselect on the picker, if any.
VisionMode? suggestedMode(Verdict verdict, Score score) => switch (verdict) {
  Verdict.typical => null,
  Verdict.blueYellow => VisionMode.tritan,
  // The protan/deutan margin is thin, so lean only on a clear difference.
  Verdict.redGreen || Verdict.broad =>
    (score[VisionMode.protan]! - score[VisionMode.deutan]!).abs() >= 2
        ? (score[VisionMode.protan]! > score[VisionMode.deutan]!
              ? VisionMode.protan
              : VisionMode.deutan)
        : VisionMode.deutan,
};

Verdict verdictOf(Score score) {
  final redGreen = score[VisionMode.protan]! + score[VisionMode.deutan]!;
  final blueYellow = score[VisionMode.tritan]!;
  if (redGreen >= 3 && blueYellow >= 3) return Verdict.broad;
  if (redGreen >= 2) return Verdict.redGreen;
  if (blueYellow >= 2) return Verdict.blueYellow;
  return Verdict.typical;
}

LocalText verdictText(Verdict verdict) => switch (verdict) {
  Verdict.typical => words(
    'No sign of color vision deficiency in this screening.',
    'Không thấy dấu hiệu rối loạn sắc giác trong bài sàng lọc này.',
  ),
  Verdict.redGreen => words(
    'Signs of difficulty telling red and green apart — the most common form.',
    'Có dấu hiệu khó phân biệt đỏ – xanh lá, dạng phổ biến nhất.',
  ),
  Verdict.blueYellow => words(
    'Signs of difficulty telling blue and yellow apart — this form is rare.',
    'Có dấu hiệu khó phân biệt xanh dương – vàng, dạng này hiếm gặp.',
  ),
  Verdict.broad => words(
    'Several answers were missed across both groups. Worth seeing an eye care professional.',
    'Nhiều câu sai ở cả hai nhóm màu. Bạn nên đi khám mắt để kiểm tra.',
  ),
};

// ---------------------------------------------------------------------------
// Dot plate rendering
// ---------------------------------------------------------------------------

/// 5x7 bitmap glyphs, so a digit can be drawn without a font path or an
/// offscreen image — a dot just looks up the cell its center lands in.
const _glyphs = <int, List<String>>{
  0: ['01110', '10001', '10011', '10101', '11001', '10001', '01110'],
  1: ['00100', '01100', '00100', '00100', '00100', '00100', '01110'],
  2: ['01110', '10001', '00001', '00010', '00100', '01000', '11111'],
  3: ['01110', '10001', '00001', '00110', '00001', '10001', '01110'],
  4: ['00010', '00110', '01010', '10010', '11111', '00010', '00010'],
  5: ['11111', '10000', '11110', '00001', '00001', '10001', '01110'],
  6: ['00110', '01000', '10000', '11110', '10001', '10001', '01110'],
  7: ['11111', '00001', '00010', '00100', '01000', '01000', '01000'],
  8: ['01110', '10001', '10001', '01110', '10001', '10001', '01110'],
  9: ['01110', '10001', '10001', '01111', '00001', '00010', '01100'],
};

/// True when ([x], [y]) in unit plate coordinates falls on the digit stroke.
bool onGlyph(int digit, double x, double y) {
  final glyph = _glyphs[digit];
  if (glyph == null) return false;
  // Glyph box centered in the plate, 5:7 aspect, ~0.45 of the diameter wide.
  const w = .45, h = w * 7 / 5;
  final gx = (x - (1 - w) / 2) / w;
  final gy = (y - (1 - h) / 2) / h;
  if (gx < 0 || gx >= 1 || gy < 0 || gy >= 1) return false;
  return glyph[(gy * 7).floor()][(gx * 5).floor()] == '1';
}

class PlatePainter extends CustomPainter {
  const PlatePainter(this.plate, this.seed);
  final Plate plate;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final edge = math.min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = edge / 2;
    final random = math.Random(seed);
    final paint = Paint();
    // Jittered grid: one dot per cell keeps dots apart without a packing pass.
    const cells = 26;
    final step = edge / cells;
    for (var row = 0; row < cells; row++) {
      for (var column = 0; column < cells; column++) {
        final dx = (column + .15 + random.nextDouble() * .7) * step;
        final dy = (row + .15 + random.nextDouble() * .7) * step;
        final point = Offset(center.dx - radius + dx, center.dy - radius + dy);
        if ((point - center).distance > radius - step * .6) continue;
        final figure = onGlyph(plate.digit, dx / edge, dy / edge);
        paint.color = figure ? plate.figure : plate.ground;
        canvas.drawCircle(
          point,
          step * (.26 + random.nextDouble() * .17),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(PlatePainter old) =>
      old.plate != plate || old.seed != seed;
}

// ---------------------------------------------------------------------------
// The screening flow
// ---------------------------------------------------------------------------

/// Twelve questions: every plate once as a dot plate, once as a swatch grid.
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
    final pool = _glyphs.keys.where((d) => d != answer).toList()
      ..shuffle(math.Random(_index + 1));
    return [answer, ...pool.take(3)]..sort();
  }

  void _answer({required bool correct}) {
    if (!correct) _score[_plate.axis] = _score[_plate.axis]! + 1;
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
    final chosen = await Navigator.of(context).push<VisionMode?>(
      MaterialPageRoute(
        builder: (_) => _Result(verdict: verdict, mode: mode),
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
          Text(
            context.t(
              'Question ${_index + 1} of $questionCount',
              'Câu ${_index + 1} / $questionCount',
            ),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _isDots
                ? context.t(
                    'Which number do you see?',
                    'Bạn thấy số nào trong hình?',
                  )
                : context.t(
                    'Which square is a different color?',
                    'Ô nào khác màu với ba ô còn lại?',
                  ),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (_isDots)
            _DotPlate(plate: plate, seed: _index)
          else
            _SwatchGrid(
              plate: plate,
              odd: _oddSwatch,
              onPick: (index) => _answer(correct: index == _oddSwatch),
            ),
          const SizedBox(height: 16),
          if (_isDots)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final digit in _choices)
                  OutlinedButton(
                    onPressed: () => _answer(correct: digit == plate.digit),
                    child: Text('$digit', style: const TextStyle(fontSize: 20)),
                  ),
              ],
            ),
          const SizedBox(height: 8),
          // Always available: "not sure" counts as a miss, which is the point.
          TextButton(
            onPressed: () => _answer(correct: false),
            child: Text(context.t('Not sure / Skip', 'Không rõ / Bỏ qua')),
          ),
        ],
      ),
    );
  }
}

class _DotPlate extends StatelessWidget {
  const _DotPlate({required this.plate, required this.seed});
  final Plate plate;
  final int seed;

  @override
  Widget build(BuildContext context) => Center(
    child: Semantics(
      // Naming the digit here would hand over the answer, so describe the
      // task instead: this question can only be answered by seeing color.
      label: context.t(
        'Color dot plate. This question needs color vision to answer; choose Not sure to skip it.',
        'Đĩa chấm màu. Câu này cần nhìn màu mới trả lời được; chọn Không rõ để bỏ qua.',
      ),
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: 280,
        child: CustomPaint(painter: PlatePainter(plate, seed)),
      ),
    ),
  );
}

class _SwatchGrid extends StatelessWidget {
  const _SwatchGrid({
    required this.plate,
    required this.odd,
    required this.onPick,
  });
  final Plate plate;
  final int odd;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      width: 280,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (var i = 0; i < 4; i++)
            Semantics(
              label: context.t('Square ${i + 1}', 'Ô ${i + 1}'),
              button: true,
              excludeSemantics: true,
              child: InkWell(
                onTap: () => onPick(i),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 134,
                  height: 134,
                  decoration: BoxDecoration(
                    color: i == odd ? plate.figure : plate.ground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _Result extends StatelessWidget {
  const _Result({required this.verdict, required this.mode});
  final Verdict verdict;
  final VisionMode? mode;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.t('Result', 'Kết quả'))),
    body: PageColumn(
      children: [
        Card(
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: brandAmber, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: brandAmber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.t('Indicative result', 'Kết quả tham khảo'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  context.copy(verdictText(verdict)),
                  style: Theme.of(context).textTheme.bodyLarge,
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
        if (mode case final suggested?)
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(suggested),
            icon: const Icon(Icons.videocam_outlined),
            label: Text(
              context.t(
                'View camera as this type',
                'Dùng loại này để xem camera',
              ),
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.t('Choose another type', 'Chọn loại khác')),
        ),
      ],
    ),
  );
}
