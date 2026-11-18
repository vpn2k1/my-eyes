import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../widgets/app_icon.dart';
import '../i18n/copy.dart';
import '../vision/vision_copy.dart';
import '../models/plate.dart';
import 'eye_test_screen.dart';
import '../vision/filters.dart';
import '../widgets/page_column.dart';
import '../theme/palette.dart';

/// Picks which filter to view through before the camera opens, grouped by
/// clinical category so "red–green" reads as the group name it actually is
/// rather than a type of its own.
class VisionPicker extends StatefulWidget {
  const VisionPicker({super.key, required this.openCamera});

  /// Opens the full-screen camera applying [filter].
  final void Function(VisionFilter filter) openCamera;

  @override
  State<VisionPicker> createState() => _VisionPickerState();
}

class _VisionPickerState extends State<VisionPicker> {
  VisionFilter? _selected;

  Future<void> _runTest() async {
    final filter = await Navigator.of(
      context,
    ).push<VisionFilter?>(MaterialPageRoute(builder: (_) => const EyeTest()));
    if (!mounted || filter == null) return;
    setState(() => _selected = filter);
    final name = filterName(context, filter);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.t(
            'Selected $name. This is a screening, not a diagnosis.',
            'Đã chọn "$name". Đây là sàng lọc, không phải chẩn đoán.',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.t('Experience a condition', 'Trải nghiệm bệnh lý')),
    ),
    body: PageColumn(
      children: [
        Text(
          context.t(
            'Pick what you want to see through, then the camera opens.',
            'Chọn cách nhìn bạn muốn trải nghiệm, camera sẽ mở ngay sau đó.',
          ),
        ),
        const SizedBox(height: 20),
        for (final group in filterCatalog.entries.where(
          (group) => categoryOf(group.key) == FilterCategory.experience,
        )) ...[
          _Heading(
            title: context.copy(groupTitle(group.key)),
            note: switch (groupNote(group.key)) {
              final note? => context.copy(note),
              _ => null,
            },
          ),
          for (final filter in group.value)
            _FilterRow(
              filter: filter,
              group: group.key,
              selected: _selected,
              onTap: widget.openCamera,
            ),
        ],
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: brandAmber, width: 2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            leading: const DecoratedBox(
              decoration: BoxDecoration(
                color: brandInk,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: EdgeInsets.all(8),
                child: AppIcon(AppIcons.search, size: 32),
              ),
            ),
            title: Text(context.t('Check your eyes', 'Kiểm tra mắt bạn')),
            subtitle: Text(
              context.t(
                '$questionCount questions across red–green and blue–yellow',
                '$questionCount câu, đủ nhóm đỏ – xanh lá và xanh dương – vàng',
              ),
            ),
            trailing: const AppIcon(AppIcons.chevron),
            onTap: () => unawaited(_runTest()),
          ),
        ),
        const SizedBox(height: 16),
        Text(context.copy(simulationNotice)),
      ],
    ),
  );
}

class _Heading extends StatelessWidget {
  const _Heading({required this.title, this.note});
  final String title;
  final String? note;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 10, left: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: .5,
          ),
        ),
        if (note case final text?) ...[
          const SizedBox(height: 4),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    ),
  );
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.filter,
    required this.group,
    required this.selected,
    required this.onTap,
  });
  final VisionFilter filter;
  final FilterGroup group;
  final VisionFilter? selected;
  final void Function(VisionFilter filter) onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = filter == selected;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accents = AppAccents.of(context);
    final accent = switch (group) {
      FilterGroup.redGreen => accents.photo,
      FilterGroup.blueYellow => accents.experience,
      FilterGroup.noColor => accents.explore,
      FilterGroup.condition ||
      FilterGroup.correction ||
      FilterGroup.realGlasses => accents.correction,
    };
    final illustration = switch (group) {
      FilterGroup.redGreen => 'redGreen',
      FilterGroup.blueYellow => 'blueYellow',
      FilterGroup.noColor => 'broad',
      _ => 'hero',
    };
    final background = isSelected
        ? scheme.primaryContainer
        : Color.alphaBlend(
            accent.accent.withValues(alpha: .08),
            scheme.surface,
          );
    final foreground = isSelected
        ? scheme.onPrimaryContainer
        : scheme.onSurface;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? scheme.primary : scheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        selected: isSelected,
        selectedTileColor: background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: DecoratedBox(
          decoration: BoxDecoration(
            color: brandInk,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Image.asset(
              'assets/illustrations/$illustration.webp',
              width: 48,
              height: 48,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
          ),
        ),
        title: Text(filterName(context, filter)),
        titleTextStyle: theme.textTheme.titleMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(context.copy(filterNote(filter))),
        ),
        subtitleTextStyle: theme.textTheme.bodyMedium?.copyWith(
          color: foreground,
        ),
        // The check and semantic selected state also identify the test suggestion.
        trailing: DecoratedBox(
          decoration: BoxDecoration(
            color: isSelected ? scheme.primary : scheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: AppIcon(
              isSelected ? AppIcons.check : AppIcons.chevron,
              color: isSelected ? scheme.onPrimary : scheme.onSurface,
              size: 18,
            ),
          ),
        ),
        onTap: () => onTap(filter),
      ),
    );
  }
}
