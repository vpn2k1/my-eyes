import 'dart:async';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../i18n/copy.dart';
import '../models/plate.dart';
import '../models/scene.dart';
import '../services/media.dart';
import '../state/app_settings.dart';
import '../theme/palette.dart';
import '../vision/filters.dart';
import '../vision/vision.dart';
import '../widgets/app_icon.dart';
import '../widgets/hero_card.dart';
import '../widgets/page_column.dart';
import '../widgets/settings_sheet.dart';
import 'eye_test_screen.dart';
import 'explore_screen.dart';
import 'guidance_screen.dart';
import 'simulator_screen.dart';
import 'vision_picker_screen.dart';

class Home extends StatefulWidget {
  const Home({super.key, required this.prefs, required this.settings});
  final SharedPreferencesAsync prefs;
  final AppSettings settings;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final Future<ui.FragmentProgram> _program;
  final _picker = ImagePicker();
  bool? _onboarded;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _program = ui.FragmentProgram.fromAsset('shaders/vision.frag');
    // Attach an error listener immediately, even if the simulator has not opened.
    unawaited(
      _program.then<void>((_) {}, onError: (Object _, StackTrace _) {}),
    );
    unawaited(_restore());
  }

  Future<void> _restore() async {
    var completed = false;
    try {
      completed = await widget.prefs.getBool('onboarding_completed') ?? false;
    } catch (_) {
      // The educational experience is available if preferences are unavailable.
    }
    if (!mounted) return;
    setState(() => _onboarded = completed);
    if (!completed ||
        defaultTargetPlatform != TargetPlatform.android ||
        kIsWeb) {
      return;
    }
    try {
      final recovered = await _picker.retrieveLostData();
      if (!mounted || _busy || recovered.isEmpty) return;
      final file = recovered.files?.firstOrNull;
      if (file != null) {
        await _openPhoto(file);
      } else if (recovered.exception != null) {
        _photoError();
      }
    } catch (_) {
      // Opening a new photo is still available when recovery is unavailable.
    }
  }

  Future<void> _finishOnboarding() async {
    setState(() => _onboarded = true);
    try {
      await widget.prefs.setBool('onboarding_completed', true);
    } catch (_) {
      // The current session can continue.
    }
  }

  void _photoError() => _message(
    context.t(
      'Could not open that image. Choose a JPEG or PNG up to 24 MB and 32 megapixels.',
      'Không mở được ảnh. Hãy chọn JPEG hoặc PNG tối đa 24 MB và 32 megapixel.',
    ),
  );

  void _message(String message) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Image.asset(
            'assets/illustrations/recovery.webp',
            width: 48,
            height: 48,
            excludeFromSemantics: true,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );

  Future<void> _openPhoto([XFile? recovered]) async {
    if (_busy) return;
    setState(() => _busy = true);
    ui.Image? image;
    try {
      final file =
          recovered ??
          await _picker.pickImage(
            source: ImageSource.gallery,
            requestFullMetadata: false,
          );
      if (file == null || !mounted) return;
      image = await loadPhoto(file);
      if (!mounted) return;
      await _openSimulator(image: image);
    } catch (_) {
      if (mounted) _photoError();
    } finally {
      image?.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openSimulator({
    ui.Image? image,
    Scene? scene,
    VisionFilter? filter,
    FilterCategory? category,
  }) async {
    final ui.FragmentProgram program;
    try {
      program = await _program;
    } catch (_) {
      if (mounted) {
        _message(
          context.t(
            'The color renderer could not load. Restart the app and try again.',
            'Không tải được bộ mô phỏng màu. Hãy mở lại ứng dụng rồi thử lại.',
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    final route = MaterialPageRoute<void>(
      builder: (_) => Simulator(
        program: program,
        photo: image,
        scene: scene,
        filter: filter,
        category: category,
        openPhoto: () => unawaited(_openPhoto()),
        explore: _explore,
      ),
    );
    await Navigator.of(context).push(route);
    // Keep caller-owned images usable through the route exit animation.
    await route.completed;
  }

  void _chooseType() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => VisionPicker(
        openCamera: (filter) => unawaited(_openSimulator(filter: filter)),
      ),
    ),
  );

  /// Opens the camera straight into the single color-support preset, with no
  /// picker in between: this entry offers help, not a diagnosis to choose.
  void _openCorrection() => unawaited(
    _openSimulator(
      filter: defaultCorrectionFor(VisionMode.protan),
      category: FilterCategory.correction,
    ),
  );

  void _explore() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => Explore(
        openScene: (scene) {
          unawaited(_openSimulator(scene: scene));
        },
      ),
    ),
  );

  Future<void> _runEyeTest() async {
    final suggested = await Navigator.of(
      context,
    ).push<VisionFilter?>(MaterialPageRoute(builder: (_) => const EyeTest()));
    if (!mounted || suggested == null) return;
    await _openSimulator(filter: suggested);
  }

  void _guidance() => Navigator.of(
    context,
  ).push<void>(MaterialPageRoute(builder: (_) => Guidance(program: _program)));

  @override
  Widget build(BuildContext context) {
    final onboarded = _onboarded;
    if (onboarded == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!onboarded) {
      return Guidance(program: _program, finish: _finishOnboarding);
    }

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xff141e35),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Image.asset(
                'assets/branding/logo.png',
                excludeFromSemantics: true,
              ),
            ),
          ),
        ),
        title: const Text('My Eyes'),
        actions: [
          IconButton(
            tooltip: context.t('Settings', 'Cài đặt'),
            onPressed: () =>
                unawaited(showSettingsSheet(context, widget.settings)),
            icon: const AppIcon(AppIcons.settings),
          ),
          IconButton(
            tooltip: context.t('About My Eyes', 'Giới thiệu My Eyes'),
            onPressed: _guidance,
            icon: const AppIcon(AppIcons.info),
          ),
        ],
      ),
      body: PageColumn(
        children: [
          HeroCard(
            title: context.t(
              'One world.\nMany ways to see.',
              'Một thế giới.\nNhiều cách nhìn.',
            ),
            body: context.t(
              'See how color distinctions change, then compare with the original.',
              'Quan sát sự khác biệt trong cảm nhận màu sắc, rồi so sánh với ảnh gốc.',
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.t('Choose a starting point', 'Chọn cách bắt đầu'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          _Entry(
            accent: AppAccents.of(context).experience,
            icon: AppIcons.video,
            title: context.t('Experience a condition', 'Trải nghiệm bệnh lý'),
            description: context.t(
              'Choose color blindness or another eye condition, then see through it',
              'Chọn mù màu hoặc một bệnh lý mắt khác, rồi quan sát qua góc nhìn đó',
            ),
            onTap: _busy ? null : _chooseType,
          ),
          _Entry(
            accent: AppAccents.of(context).correction,
            icon: AppIcons.adjust,
            title: context.t('See true colors', 'Hỗ trợ nhìn đúng màu'),
            description: context.t(
              'Shifts confusable colors apart so they are easier to tell apart',
              'Dịch các màu dễ lẫn ra xa nhau để dễ phân biệt hơn',
            ),
            onTap: _busy ? null : _openCorrection,
          ),
          _Entry(
            accent: AppAccents.of(context).photo,
            icon: AppIcons.photo,
            title: context.t('Choose photo', 'Chọn ảnh'),
            description: context.t(
              'Use a JPEG or PNG on this device',
              'Dùng ảnh JPEG hoặc PNG trên thiết bị',
            ),
            onTap: _busy ? null : () => unawaited(_openPhoto()),
          ),
          _Entry(
            accent: AppAccents.of(context).explore,
            icon: AppIcons.learn,
            title: context.t('Explore and learn', 'Khám phá và tìm hiểu'),
            description: context.t(
              'Explore six realistic scenes offline',
              'Khám phá sáu ảnh mẫu chân thực ngoại tuyến',
            ),
            onTap: _busy ? null : _explore,
          ),
          const SizedBox(height: 24),
          Text(
            context.t('Check your eyes', 'Kiểm tra mắt'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          _Entry(
            accent: AppAccents.of(context).screening,
            icon: AppIcons.search,
            title: context.t('Test your color vision', 'Kiểm tra sắc giác'),
            description: context.t(
              '$questionCount questions covering red–green and blue–yellow',
              '$questionCount câu, đủ nhóm đỏ – xanh lá và xanh dương – vàng',
            ),
            onTap: _busy ? null : () => unawaited(_runEyeTest()),
          ),
          if (_busy) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({
    required this.accent,
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
  });
  final AppIcons icon;
  final FeatureAccent accent;
  final String title, description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
    color: accent.accent,
    margin: const EdgeInsets.symmetric(vertical: 6),
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      minVerticalPadding: 12,
      leading: DecoratedBox(
        decoration: BoxDecoration(
          color: brandInk,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: AppIcon(icon, size: 36),
        ),
      ),
      title: Text(title),
      subtitle: Text(description),
      titleTextStyle: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(color: accent.onAccent),
      subtitleTextStyle: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: accent.onAccent),
      trailing: AppIcon(AppIcons.chevron, color: accent.onAccent),
      onTap: onTap,
      enabled: onTap != null,
    ),
  );
}
