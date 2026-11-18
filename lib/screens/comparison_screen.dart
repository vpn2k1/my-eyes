import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../i18n/copy.dart';
import '../state/simulation_settings.dart';
import '../vision/filters.dart';
import '../widgets/app_icon.dart';
import '../widgets/image_frame.dart';
import '../widgets/mode_controls.dart';
import '../widgets/page_column.dart';

class Comparison extends StatefulWidget {
  const Comparison({
    super.key,
    required this.image,
    required this.program,
    required this.settings,
    this.description,
    this.category,
  });
  final ui.Image image;
  final ui.FragmentProgram program;
  final SimulationSettings settings;
  final LocalText? description;

  /// Restricts the mode picker to one category, e.g. support-only entries.
  final FilterCategory? category;

  @override
  State<Comparison> createState() => _ComparisonState();
}

class _ComparisonState extends State<Comparison> {
  bool _sideBySide = false;
  double _split = .5;

  ImageFrame frame(String label, VisionFilter filter, [double? split]) =>
      ImageFrame(
        image: widget.image,
        program: widget.program,
        filter: filter,
        severity: widget.settings.severity,
        label: widget.description == null
            ? label
            : '$label. ${context.copy(widget.description!)}',
        split: split,
      );

  @override
  Widget build(BuildContext context) {
    final original = context.t('Original', 'Ảnh gốc');
    final simulated = context.t('Simulated', 'Mô phỏng');
    // Blur and field loss are composited over the whole frame, so a split
    // divider would dim the "original" half too. Only side by side is honest.
    final spatial = widget.settings.filter.effect != null;
    final sideBySide = _sideBySide || spatial;
    return Scaffold(
      appBar: AppBar(title: Text(context.t('Compare', 'So sánh'))),
      body: ListenableBuilder(
        listenable: widget.settings,
        builder: (context, _) => PageColumn(
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!spatial)
                  ChoiceChip(
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    label: Text(context.t('Split slider', 'Thanh chia ảnh')),
                    selected: !sideBySide,
                    onSelected: (_) => setState(() => _sideBySide = false),
                  ),
                ChoiceChip(
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  label: Text(context.t('Side by side', 'Đặt cạnh nhau')),
                  selected: sideBySide,
                  onSelected: (_) => setState(() => _sideBySide = true),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text(original)),
                Flexible(child: Text(simulated, textAlign: TextAlign.end)),
              ],
            ),
            const SizedBox(height: 6),
            if (sideBySide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: frame(original, normalFilter)),
                  const SizedBox(width: 8),
                  Expanded(child: frame(simulated, widget.settings.filter)),
                ],
              )
            else ...[
              LayoutBuilder(
                builder: (context, constraints) {
                  // Match ImageFrame's centered width, including portrait images.
                  final width = (430 * widget.image.width / widget.image.height)
                      .clamp(0.0, constraints.maxWidth);
                  void update(DragUpdateDetails details) => setState(() {
                    _split = (details.localPosition.dx / width).clamp(0.0, 1.0);
                  });
                  return Center(
                    child: SizedBox(
                      width: width,
                      child: GestureDetector(
                        onHorizontalDragUpdate: update,
                        excludeFromSemantics: true,
                        child: frame(
                          '$original / $simulated',
                          widget.settings.filter,
                          _split,
                        ),
                      ),
                    ),
                  );
                },
              ),
              Semantics(
                label: context.t(
                  'Original image shown',
                  'Phần ảnh gốc hiển thị',
                ),
                child: Slider(
                  value: _split,
                  divisions: 100,
                  label: '${(_split * 100).round()}%',
                  semanticFormatterCallback: (value) =>
                      '${(value * 100).round()}%',
                  onChanged: (value) => setState(() => _split = value),
                ),
              ),
            ],
            if (!sideBySide)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _split = .5),
                  icon: const AppIcon(AppIcons.restart),
                  label: Text(context.t('Reset divider', 'Đặt lại thanh chia')),
                ),
              ),
            const Divider(),
            ModeControls(settings: widget.settings, category: widget.category),
          ],
        ),
      ),
    );
  }
}
