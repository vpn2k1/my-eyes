import 'package:material_ui/material_ui.dart';

import '../i18n/copy.dart';
import '../state/simulation_settings.dart';
import '../vision/filters.dart';
import '../vision/vision_copy.dart';

class ModeControls extends StatelessWidget {
  const ModeControls({
    super.key,
    required this.settings,
    this.category,
    this.onSelect,
  });
  final SimulationSettings settings;

  /// Restricts the picker to one category, e.g. support-only. Null shows both.
  final FilterCategory? category;

  /// Called right after a mode chip is picked, e.g. to close a host sheet.
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final severity = (settings.severity * 100).round();
    final categories = category == null ? FilterCategory.values : [category!];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.t('Vision mode', 'Chế độ sắc giác'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        for (final category in categories) ...[
          if (category != categories.first) ...[
            const SizedBox(height: 14),
            const Divider(),
          ],
          const SizedBox(height: 4),
          Text(
            context.copy(categoryTitle(category)),
            style: Theme.of(context).textTheme.labelMedium,
          ),
          if (categoryNote(category) case final note?)
            Text(
              context.copy(note),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          for (final group in filterCatalog.entries.where(
            (group) => categoryOf(group.key) == category,
          )) ...[
            const SizedBox(height: 10),
            Text(
              context.copy(groupTitle(group.key)),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: .8,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final filter in group.value)
                  ChoiceChip(
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    label: Text(filterName(context, filter)),
                    selected: filter == settings.filter,
                    onSelected: (_) {
                      settings.select(filter);
                      onSelect?.call();
                    },
                  ),
              ],
            ),
          ],
        ],
        const SizedBox(height: 12),
        Text(context.copy(filterNote(settings.filter))),
        const SizedBox(height: 12),
        if (settings.filter.hasSeverity) ...[
          Text(
            settings.filter.correct
                ? context.t(
                    'Correction strength · $severity%',
                    'Mức độ hỗ trợ · $severity%',
                  )
                : context.t(
                    'Simulation strength · $severity%',
                    'Mức độ mô phỏng · $severity%',
                  ),
          ),
          Semantics(
            label: settings.filter.correct
                ? context.t('Correction strength', 'Mức độ hỗ trợ')
                : context.t('Simulation strength', 'Mức độ mô phỏng'),
            child: Slider(
              value: settings.severity,
              divisions: 100,
              label: '$severity%',
              semanticFormatterCallback: (value) => '${(value * 100).round()}%',
              onChanged: settings.setSeverity,
            ),
          ),
        ] else
          Text(
            context.t(
              'This mode has a fixed strength.',
              'Chế độ này có mức độ cố định.',
            ),
          ),
      ],
    );
  }
}
