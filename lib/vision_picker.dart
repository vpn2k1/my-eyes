import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'content.dart';
import 'eye_test.dart';
import 'page_column.dart';
import 'palette.dart';
import 'vision.dart';

/// Picks which deficiency to simulate before the camera opens, grouped by
/// clinical category so "red–green" reads as the group name it actually is
/// rather than a third type of its own.
class VisionPicker extends StatefulWidget {
  const VisionPicker({super.key, required this.openCamera});

  /// Opens the full-screen camera simulating [mode].
  final void Function(VisionMode mode) openCamera;

  @override
  State<VisionPicker> createState() => _VisionPickerState();
}

class _VisionPickerState extends State<VisionPicker> {
  VisionMode? _selected;

  Future<void> _runTest() async {
    final suggested = await Navigator.of(
      context,
    ).push<VisionMode?>(MaterialPageRoute(builder: (_) => const EyeTest()));
    if (!mounted || suggested == null) return;
    setState(() => _selected = suggested);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.t(
            'Selected ${modeName(context, suggested)}. This is a screening, not a diagnosis.',
            'Đã chọn "${modeName(context, suggested)}". Đây là sàng lọc, không phải chẩn đoán.',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.t('Choose a type', 'Chọn loại sắc giác')),
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
        _Heading(
          title: context.t('RED – GREEN DEFICIENCY', 'RỐI LOẠN ĐỎ – XANH LÁ'),
          note: context.t(
            'The most common form, about 8% of men',
            'Phổ biến nhất, khoảng 8% nam giới',
          ),
        ),
        _ModeRow(
          mode: VisionMode.deutan,
          selected: _selected,
          onTap: widget.openCamera,
        ),
        _ModeRow(
          mode: VisionMode.protan,
          selected: _selected,
          onTap: widget.openCamera,
        ),
        _Heading(
          title: context.t(
            'BLUE – YELLOW DEFICIENCY',
            'RỐI LOẠN XANH DƯƠNG – VÀNG',
          ),
          note: context.t('Rare', 'Rất hiếm gặp'),
        ),
        _ModeRow(
          mode: VisionMode.tritan,
          selected: _selected,
          onTap: widget.openCamera,
        ),
        _Heading(title: context.t('NO COLOR VISION', 'KHÔNG THẤY MÀU')),
        _ModeRow(
          mode: VisionMode.grayscale,
          selected: _selected,
          onTap: widget.openCamera,
        ),
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
            leading: const Icon(Icons.search, color: brandAmber),
            title: Text(context.t('Check your eyes', 'Kiểm tra mắt bạn')),
            subtitle: Text(
              context.t(
                '$questionCount questions across red–green and blue–yellow',
                '$questionCount câu, đủ nhóm đỏ – xanh lá và xanh dương – vàng',
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
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

class _ModeRow extends StatelessWidget {
  const _ModeRow({
    required this.mode,
    required this.selected,
    required this.onTap,
  });
  final VisionMode mode;
  final VisionMode? selected;
  final void Function(VisionMode mode) onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = mode == selected;
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
          child: Icon(isSelected ? Icons.check : Icons.remove_red_eye_outlined),
        ),
        title: Text(modeName(context, mode)),
        subtitle: Text(
          [?modeClinical(context, mode), context.copy(modeNote(mode))].join(' · '),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => onTap(mode),
      ),
    );
  }
}
