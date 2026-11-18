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
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            leading: const AppIcon(AppIcons.search, color: brandAmber),
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
    padding: const EdgeInsets.only(top: 12, bottom: 6, left: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: .8,
          ),
        ),
        if (note case final text?)
          Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.filter,
    required this.selected,
    required this.onTap,
  });
  final VisionFilter filter;
  final VisionFilter? selected;
  final void Function(VisionFilter filter) onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = filter == selected;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        selected: isSelected,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: isSelected
              ? scheme.primary
              : scheme.primaryContainer,
          foregroundColor: isSelected
              ? scheme.onPrimary
              : scheme.onPrimaryContainer,
          // Pair the selected color with a check icon, never color alone.
          child: AppIcon(isSelected ? AppIcons.check : AppIcons.eye),
        ),
        title: Text(filterName(context, filter)),
        subtitle: Text(context.copy(filterNote(filter))),
        trailing: const AppIcon(AppIcons.chevron),
        onTap: () => onTap(filter),
      ),
    );
  }
}
