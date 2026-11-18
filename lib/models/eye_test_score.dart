import '../i18n/copy.dart';
import '../vision/vision.dart';
import 'plate.dart';

/// Misses per axis. A missed question counts for every axis its plate
/// collapses for, so a red–green combo counts for protan and deutan both.
typedef Score = Map<VisionMode, int>;

/// Misses an axis can collect: one per question whose plate collapses for it.
/// Derived from [plates] so the thresholds follow the plate list.
int creditsFor(VisionMode axis) =>
    plates.where((plate) => plate.axes.contains(axis)).length * 2;

enum Group { redGreen, blueYellow }

/// Share of a group's misses, 0 to 1. Red–green counts protan and deutan
/// credits together, matching how its combos score on both.
double missRate(Score score, Group group) => switch (group) {
  Group.redGreen =>
    (score[VisionMode.protan]! + score[VisionMode.deutan]!) /
        (creditsFor(VisionMode.protan) + creditsFor(VisionMode.deutan)),
  Group.blueYellow => score[VisionMode.tritan]! / creditsFor(VisionMode.tritan),
};

enum Verdict { typical, redGreen, blueYellow, broad }

/// Axis a [Verdict] should preselect on the picker, if any.
VisionMode? suggestedMode(Verdict verdict, Score score) => switch (verdict) {
  Verdict.typical => null,
  Verdict.blueYellow => VisionMode.tritan,
  // The protan/deutan margin only comes from the single-axis plates, so lean
  // on it only when it is clear.
  Verdict.redGreen || Verdict.broad =>
    (score[VisionMode.protan]! - score[VisionMode.deutan]!).abs() >= 2
        ? (score[VisionMode.protan]! > score[VisionMode.deutan]!
              ? VisionMode.protan
              : VisionMode.deutan)
        : VisionMode.deutan,
};

/// A third of a group missed is the line: stray slips stay under it, a real
/// deficiency misses most of the group.
const missLine = 1 / 3;

Verdict verdictOf(Score score) {
  final redGreen = missRate(score, Group.redGreen) >= missLine;
  final blueYellow = missRate(score, Group.blueYellow) >= missLine;
  if (redGreen && blueYellow) return Verdict.broad;
  if (redGreen) return Verdict.redGreen;
  if (blueYellow) return Verdict.blueYellow;
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
