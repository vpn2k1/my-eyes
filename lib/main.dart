import 'dart:async';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'content.dart';
import 'media.dart';
import 'simulator.dart';
import 'page_column.dart';
import 'vision.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyEyes());
}

class MyEyes extends StatelessWidget {
  const MyEyes({super.key, this.prefs});
  final SharedPreferencesAsync? prefs;

  ThemeData _theme(Brightness brightness) => ThemeData(
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xff2563eb),
      brightness: brightness,
    ),
    useMaterial3: true,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
  );

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'My Eyes',
    debugShowCheckedModeBanner: false,
    theme: _theme(Brightness.light),
    darkTheme: _theme(Brightness.dark),
    supportedLocales: const [Locale('en'), Locale('vi')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: Home(prefs: prefs ?? SharedPreferencesAsync()),
  );
}

class Home extends StatefulWidget {
  const Home({super.key, required this.prefs});
  final SharedPreferencesAsync prefs;

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

  void _message(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

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

  Future<void> _openSimulator({ui.Image? image, Scene? scene}) async {
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
        openPhoto: () => unawaited(_openPhoto()),
        explore: _explore,
      ),
    );
    await Navigator.of(context).push(route);
    // Keep caller-owned images usable through the route exit animation.
    await route.completed;
  }

  void _explore() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => Explore(
        openScene: (scene) {
          unawaited(_openSimulator(scene: scene));
        },
      ),
    ),
  );

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
        leading: const Icon(Icons.visibility_outlined),
        title: const Text('My Eyes'),
        actions: [
          IconButton(
            tooltip: context.t('About My Eyes', 'Giới thiệu My Eyes'),
            onPressed: _guidance,
            icon: const Icon(Icons.info_outline),
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
            icon: Icons.videocam_outlined,
            title: context.t('Open camera', 'Mở camera'),
            description: context.t(
              'See the colors around you',
              'Quan sát màu sắc xung quanh',
            ),
            onTap: _busy ? null : _openSimulator,
          ),
          _Entry(
            icon: Icons.photo_outlined,
            title: context.t('Choose photo', 'Chọn ảnh'),
            description: context.t(
              'Use a JPEG or PNG on this device',
              'Dùng ảnh JPEG hoặc PNG trên thiết bị',
            ),
            onTap: _busy ? null : () => unawaited(_openPhoto()),
          ),
          _Entry(
            icon: Icons.auto_stories_outlined,
            title: context.t('Explore and learn', 'Khám phá và tìm hiểu'),
            description: context.t(
              'Try six illustrated scenes offline',
              'Thử sáu tình huống minh họa ngoại tuyến',
            ),
            onTap: _busy ? null : _explore,
          ),
          if (_busy) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}

class HeroCard extends StatelessWidget {
  const HeroCard({super.key, required this.title, required this.body});
  final String title, body;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xfff5f7fd);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff141e35), Color(0xff253c62)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.visibility_outlined,
              color: Color(0xffabc8ff),
              size: 32,
            ),
            const SizedBox(height: 22),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: ink,
                fontWeight: FontWeight.w700,
                height: 1.12,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              body,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: ink),
            ),
          ],
        ),
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
  });
  final IconData icon;
  final String title, description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        child: Icon(icon),
      ),
      title: Text(title),
      subtitle: Text(description),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      enabled: onTap != null,
    ),
  );
}

class Guidance extends StatelessWidget {
  const Guidance({super.key, required this.program, this.finish});
  final Future<ui.FragmentProgram> program;
  final VoidCallback? finish;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('My Eyes'),
      actions: [
        if (finish != null)
          TextButton(
            onPressed: finish,
            child: Text(context.t('Skip', 'Bỏ qua')),
          ),
      ],
    ),
    body: PageColumn(
      children: [
        HeroCard(
          title: context.t(
            'See through\nmy eyes.',
            'Nhìn qua\nđôi mắt của tôi.',
          ),
          body: context.t(
            'Explore different ways people perceive color.',
            'Khám phá những cách khác nhau mà con người cảm nhận màu sắc.',
          ),
        ),
        const SizedBox(height: 20),
        FutureBuilder<ui.FragmentProgram>(
          future: program,
          builder: (context, snapshot) => snapshot.hasData
              ? OnboardingExample(program: snapshot.requireData)
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),
        Text(context.copy(simulationNotice)),
        const SizedBox(height: 16),
        if (finish != null)
          FilledButton(
            onPressed: finish,
            child: Text(context.t('Start exploring', 'Bắt đầu trải nghiệm')),
          ),
      ],
    ),
  );
}

class Explore extends StatelessWidget {
  const Explore({super.key, required this.openScene});
  final ValueChanged<Scene> openScene;

  Future<void> _openReference(BuildContext context, String url) async {
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      // Show a readable and copyable URL below if the device cannot open it.
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.t('Could not open the link.', 'Không mở được liên kết.'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: Text(context.t('Explore and learn', 'Khám phá và tìm hiểu')),
        bottom: TabBar(
          tabs: [
            Tab(text: context.t('Scenes', 'Tình huống')),
            Tab(text: context.t('Learn', 'Kiến thức')),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          PageColumn(children: [_SceneLibrary(openScene: openScene)]),
          PageColumn(
            children: [
              Text(context.copy(simulationNotice)),
              const SizedBox(height: 12),
              for (final mode in VisionMode.values)
                Card(
                  child: ListTile(
                    title: Text(modeName(context, mode)),
                    subtitle: Text(context.copy(modeNote(mode))),
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                context.t('References', 'Nguồn tham khảo'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              for (final ref in const [
                (
                  'National Eye Institute',
                  'https://www.nei.nih.gov/learn-about-eye-health/eye-conditions-and-diseases/color-blindness',
                ),
                (
                  'Machado, Oliveira & Fernandes (2009)',
                  'https://doi.org/10.1109/TVCG.2009.113',
                ),
                ('W3C — WCAG 2.2', 'https://www.w3.org/TR/WCAG22/'),
              ])
                ListTile(
                  title: Text(ref.$1),
                  subtitle: SelectableText(ref.$2),
                  trailing: IconButton(
                    tooltip: context.t('Open source', 'Mở nguồn tham khảo'),
                    onPressed: () => _openReference(context, ref.$2),
                    icon: const Icon(Icons.open_in_new),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _SceneLibrary extends StatelessWidget {
  const _SceneLibrary({required this.openScene});
  final ValueChanged<Scene> openScene;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final cardWidth = width >= 560 ? (width - 12) / 2 : width;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final scene in scenes)
            SizedBox(
              width: cardWidth,
              child: Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => openScene(scene),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AspectRatio(
                        aspectRatio: 900 / 560,
                        child: Image.asset(
                          scene.asset,
                          fit: BoxFit.cover,
                          semanticLabel: context.copy(scene.alt),
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                      ListTile(
                        title: Text(context.copy(scene.title)),
                        subtitle: Text(context.copy(scene.barrier)),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}
