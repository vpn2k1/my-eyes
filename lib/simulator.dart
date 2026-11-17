import 'dart:async';
import 'dart:ui' as ui;

import 'package:app_settings/app_settings.dart';
import 'package:camera/camera.dart';
import 'package:material_ui/material_ui.dart';

import 'content.dart';
import 'delete_capture.dart';
import 'media.dart';
import 'page_column.dart';
import 'palette.dart';
import 'viewport.dart';
import 'vision.dart';

class SimulationSettings extends ChangeNotifier {
  VisionMode mode = VisionMode.deutan;
  double severity = 1;

  void select(VisionMode value) {
    mode = value;
    notifyListeners();
  }

  void setSeverity(double value) {
    severity = value;
    notifyListeners();
  }
}

class Simulator extends StatefulWidget {
  const Simulator({
    super.key,
    required this.program,
    required this.openPhoto,
    required this.explore,
    this.photo,
    this.scene,
    this.mode,
  });

  final ui.FragmentProgram program;
  final ui.Image? photo;
  final Scene? scene;
  final VoidCallback openPhoto, explore;

  /// Deficiency chosen before the camera opened, if any.
  final VisionMode? mode;

  @override
  State<Simulator> createState() => _SimulatorState();
}

class _SimulatorState extends State<Simulator> with WidgetsBindingObserver {
  final settings = SimulationSettings();
  CameraController? _controller;
  ui.Image? _sceneImage;
  Future<void> _cameraWork = Future<void>.value();
  bool _foreground = true;
  bool _compare = false;
  bool _capturing = false;
  bool _disposed = false;
  bool _loading = true;
  bool _blocked = false;
  String? _error;
  bool get _isCamera => widget.photo == null && widget.scene == null;
  bool get _cameraWanted => !_disposed && _foreground && !_compare && !_blocked;

  @override
  void initState() {
    super.initState();
    if (widget.mode case final mode?) settings.mode = mode;
    if (_isCamera) {
      WidgetsBinding.instance.addObserver(this);
      unawaited(_syncCamera());
    } else if (widget.scene case final scene?) {
      unawaited(_loadScene(scene));
    } else {
      _loading = false;
    }
  }

  Future<void> _loadScene(Scene scene) async {
    try {
      final image = await loadScene(scene.asset);
      if (!mounted) {
        image.dispose();
        return;
      }
      setState(() => _sceneImage = image);
    } catch (_) {
      if (mounted) setState(() => _error = 'scene');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A permission sheet can briefly make the app inactive during initialization.
    if (state == AppLifecycleState.inactive && _controller == null) return;
    _foreground = state == AppLifecycleState.resumed;
    unawaited(_syncCamera());
  }

  Future<void> _syncCamera() {
    _cameraWork = _cameraWork.then((_) => _reconcileCamera());
    return _cameraWork;
  }

  Future<void> _disposeCamera(CameraController controller) async {
    try {
      await controller.dispose();
    } catch (_) {
      // The platform may already have closed the camera on interruption.
    }
  }

  Future<void> _reconcileCamera() async {
    if (!_cameraWanted) {
      final controller = _controller;
      _controller = null;
      if (controller != null) {
        if (mounted && !_disposed) setState(() {});
        await _disposeCamera(controller);
      }
      return;
    }
    if (_controller != null) return;
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    CameraController? opening;
    try {
      if (!ui.ImageFilter.isShaderFilterSupported) {
        throw CameraException(
          'ShaderUnavailable',
          'Live preview needs Impeller.',
        );
      }
      final devices = await availableCameras();
      if (!_cameraWanted) return;
      final rear = devices
          .where((camera) => camera.lensDirection == CameraLensDirection.back)
          .firstOrNull;
      if (rear == null) {
        throw CameraException('NoCamera', 'No rear camera available.');
      }
      opening = CameraController(
        rear,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await opening.initialize();
      if (!_cameraWanted) return;
      final controller = opening;
      controller.addListener(() {
        if (_controller == controller && controller.value.hasError && mounted) {
          setState(() {
            _error = 'camera';
            _blocked = true;
          });
          unawaited(_syncCamera());
        }
      });
      _controller = controller;
      opening = null;
    } on CameraException catch (error) {
      if (_cameraWanted) {
        _error = switch (error.code) {
          'CameraAccessDenied' ||
          'CameraAccessDeniedWithoutPrompt' ||
          'CameraAccessRestricted' => 'permission',
          'ShaderUnavailable' => 'renderer',
          _ => 'camera',
        };
        _blocked = true;
      }
    } catch (_) {
      if (_cameraWanted) {
        _error = 'camera';
        _blocked = true;
      }
    } finally {
      if (opening != null) await _disposeCamera(opening);
      if (mounted && !_disposed) setState(() => _loading = false);
    }
  }

  Future<void> _openCompare() async {
    if (_compare || _capturing) return;
    final still = widget.photo ?? _sceneImage;
    if (still != null) {
      await _showComparison(still);
      return;
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    setState(() => _capturing = true);
    XFile? capture;
    ui.Image? frame;
    // Serialize capture with initialization and disposal.
    _cameraWork = _cameraWork.then((_) async {
      if (_cameraWanted && controller == _controller) {
        try {
          capture = await controller.takePicture();
        } catch (_) {
          if (mounted && !_disposed) _captureError();
        }
      }
    });
    try {
      await _cameraWork;
      final file = capture;
      if (file != null && mounted && !_disposed && _foreground) {
        frame = await loadPhoto(file);
        await deleteTempCapture(file);
        capture = null;
        if (mounted && !_disposed && _foreground) await _showComparison(frame);
      }
    } catch (_) {
      if (mounted && !_disposed) _captureError();
    } finally {
      frame?.dispose();
      if (capture case final file?) await deleteTempCapture(file);
      if (mounted && !_disposed) setState(() => _capturing = false);
    }
  }

  void _captureError() => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        context.t(
          'Could not freeze the frame. Try again.',
          'Không thể chụp khung hình. Hãy thử lại.',
        ),
      ),
    ),
  );

  Future<void> _showComparison(ui.Image image) async {
    setState(() => _compare = true);
    if (_isCamera) await _syncCamera();
    if (!mounted || _disposed) return;
    final route = MaterialPageRoute<void>(
      builder: (_) => Comparison(
        image: image,
        program: widget.program,
        settings: settings,
        description: widget.scene?.alt,
      ),
    );
    await Navigator.of(context).push(route);
    await route.completed;
    if (!mounted || _disposed) return;
    setState(() => _compare = false);
    if (_isCamera) await _syncCamera();
  }

  @override
  void dispose() {
    _disposed = true;
    if (_isCamera) {
      WidgetsBinding.instance.removeObserver(this);
      unawaited(_syncCamera());
    }
    _sceneImage?.dispose();
    settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scene = widget.scene;
    final image = widget.photo ?? _sceneImage;
    final controller = _controller;
    if (_isCamera) return _fullScreenCamera(controller);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          scene == null
              ? context.t('Vision simulator', 'Mô phỏng sắc giác')
              : context.copy(scene.title),
        ),
      ),
      body: PageColumn(
        children: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(36),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error case final error?)
            _errorPanel(context, error)
          else ...[
            ListenableBuilder(
              listenable: settings,
              builder: (context, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (image != null)
                    ImageFrame(
                      image: image,
                      program: widget.program,
                      mode: settings.mode,
                      severity: settings.severity,
                      label: scene == null
                          ? context.t('Simulation preview', 'Ảnh mô phỏng')
                          : context.copy(scene.alt),
                    )
                  else if (controller != null)
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 400,
                          maxHeight: 500,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: VisionCameraFilter(
                            program: widget.program,
                            mode: settings.mode,
                            severity: settings.severity,
                            child: CameraPreview(controller),
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 120),
                  const SizedBox(height: 16),
                  ModeControls(settings: settings),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed:
                  (image == null && controller == null) ||
                      _capturing ||
                      _compare
                  ? null
                  : _openCompare,
              icon: const Icon(Icons.compare_outlined),
              label: Text(
                _capturing
                    ? context.t('Freezing frame…', 'Đang chụp khung hình…')
                    : _isCamera
                    ? context.t(
                        'Freeze and compare',
                        'Chụp khung hình và so sánh',
                      )
                    : context.t('Compare with original', 'So sánh với ảnh gốc'),
              ),
            ),
            if (scene != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.lightbulb_outline),
                    title: Text(context.copy(scene.barrier)),
                    subtitle: Text(context.copy(scene.tip)),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// Camera fills the screen: the point is seeing the colors around you, so
  /// the controls sit on top of the preview instead of below a small box.
  Widget _fullScreenCamera(CameraController? controller) => Scaffold(
    backgroundColor: brandNavy,
    body: ListenableBuilder(
      listenable: settings,
      builder: (context, _) => Stack(
        fit: StackFit.expand,
        children: [
          if (controller != null)
            VisionCameraFilter(
              program: widget.program,
              mode: settings.mode,
              severity: settings.severity,
              child: _coveringPreview(controller),
            ),
          if (_loading)
            const Center(child: CircularProgressIndicator(color: brandInk))
          else if (_error case final error?)
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 96, 20, 96),
                child: _errorPanel(context, error),
              ),
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _scrim(
              begin: Alignment.topCenter,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 12, 12),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: context.t('Back', 'Quay lại'),
                        color: brandInk,
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 4),
                      if (controller != null)
                        Expanded(child: _simulatingBadge()),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (controller != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _scrim(
                begin: Alignment.bottomCenter,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: brandInk,
                            side: const BorderSide(color: brandInk),
                          ),
                          onPressed: () => unawaited(_openModeSheet()),
                          icon: const Icon(Icons.tune),
                          label: Text(context.t('Adjust', 'Điều chỉnh')),
                        ),
                        FilledButton.icon(
                          onPressed: _capturing || _compare
                              ? null
                              : _openCompare,
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: Text(
                            _capturing
                                ? context.t('Freezing…', 'Đang chụp…')
                                : context.t(
                                    'Capture & compare',
                                    'Chụp & so sánh',
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );

  /// Fill the screen without distorting the preview's aspect ratio.
  Widget _coveringPreview(CameraController controller) => LayoutBuilder(
    builder: (context, constraints) => FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: constraints.maxWidth,
        height: constraints.maxWidth / controller.value.aspectRatio,
        child: CameraPreview(controller),
      ),
    ),
  );

  Widget _scrim({required Alignment begin, required Widget child}) =>
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: begin,
            end: begin == Alignment.topCenter
                ? Alignment.bottomCenter
                : Alignment.topCenter,
            colors: [brandNavy, brandNavy.withValues(alpha: 0)],
          ),
        ),
        child: child,
      );

  /// Always on screen so a filtered preview is never mistaken for real color.
  Widget _simulatingBadge() => DecoratedBox(
    decoration: BoxDecoration(
      color: brandNavy.withValues(alpha: .72),
      border: Border.all(color: brandAmber),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.visibility_outlined, color: brandAmber, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.t(
                'Simulating: ${modeName(context, settings.mode)}',
                'Đang mô phỏng: ${modeName(context, settings.mode)}',
              ),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: brandInk, fontSize: 13),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _openModeSheet() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        // Reuse the controls the photo and scene paths already use.
        child: ListenableBuilder(
          listenable: settings,
          builder: (context, _) => ModeControls(settings: settings),
        ),
      ),
    ),
  );

  Widget _errorPanel(BuildContext context, String error) {
    final message = switch (error) {
      'permission' => context.t(
        'Camera access is unavailable. You can enable it in system settings or choose another source.',
        'Ứng dụng chưa có quyền camera. Bạn có thể cấp quyền trong cài đặt hệ thống hoặc chọn nguồn khác.',
      ),
      'renderer' => context.t(
        'Live simulation is unavailable on this renderer. Photos and scenes are available.',
        'Bộ dựng hình này chưa hỗ trợ mô phỏng trực tiếp. Bạn vẫn có thể dùng ảnh và tình huống mẫu.',
      ),
      'scene' => context.t(
        'This scene could not load.',
        'Không tải được tình huống này.',
      ),
      _ => context.t(
        'The rear camera could not start.',
        'Không thể mở camera sau.',
      ),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (error == 'permission')
                  OutlinedButton(
                    onPressed: () async {
                      try {
                        await AppSettings.openAppSettings();
                      } catch (_) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.t(
                                'Open system settings to manage camera access.',
                                'Mở cài đặt hệ thống để cấp quyền camera.',
                              ),
                            ),
                          ),
                        );
                      }
                    },
                    child: Text(context.t('Open settings', 'Mở cài đặt')),
                  ),
                if (_isCamera && error != 'renderer')
                  OutlinedButton(
                    onPressed: () {
                      setState(() => _blocked = false);
                      unawaited(_syncCamera());
                    },
                    child: Text(context.t('Retry camera', 'Thử lại camera')),
                  ),
                OutlinedButton(
                  onPressed: widget.openPhoto,
                  child: Text(context.t('Choose photo', 'Chọn ảnh')),
                ),
                FilledButton(
                  onPressed: widget.explore,
                  child: Text(context.t('Use a sample', 'Dùng ảnh mẫu')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ModeControls extends StatelessWidget {
  const ModeControls({super.key, required this.settings});
  final SimulationSettings settings;

  @override
  Widget build(BuildContext context) {
    final severity = (settings.severity * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.t('Vision mode', 'Chế độ sắc giác'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final mode in VisionMode.values)
              ChoiceChip(
                materialTapTargetSize: MaterialTapTargetSize.padded,
                label: Text(modeName(context, mode)),
                selected: mode == settings.mode,
                onSelected: (_) => settings.select(mode),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(context.copy(modeNote(settings.mode))),
        const SizedBox(height: 12),
        if (settings.mode.hasSeverity) ...[
          Text(
            context.t(
              'Simulation strength · $severity%',
              'Mức độ mô phỏng · $severity%',
            ),
          ),
          Semantics(
            label: context.t('Simulation strength', 'Mức độ mô phỏng'),
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

class ImageFrame extends StatelessWidget {
  const ImageFrame({
    super.key,
    required this.image,
    required this.program,
    required this.mode,
    required this.severity,
    required this.label,
    this.split,
  });

  final ui.Image image;
  final ui.FragmentProgram program;
  final VisionMode mode;
  final double severity;
  final String label;
  final double? split;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 430),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: VisionImage(
          image: image,
          program: program,
          mode: mode,
          severity: severity,
          label: label,
          split: split,
        ),
      ),
    ),
  );
}

class Comparison extends StatefulWidget {
  const Comparison({
    super.key,
    required this.image,
    required this.program,
    required this.settings,
    this.description,
  });
  final ui.Image image;
  final ui.FragmentProgram program;
  final SimulationSettings settings;
  final LocalText? description;

  @override
  State<Comparison> createState() => _ComparisonState();
}

class _ComparisonState extends State<Comparison> {
  bool _sideBySide = false;
  double _split = .5;

  ImageFrame frame(String label, VisionMode mode, [double? split]) =>
      ImageFrame(
        image: widget.image,
        program: widget.program,
        mode: mode,
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
                ChoiceChip(
                  label: Text(context.t('Split slider', 'Thanh chia ảnh')),
                  selected: !_sideBySide,
                  onSelected: (_) => setState(() => _sideBySide = false),
                ),
                ChoiceChip(
                  label: Text(context.t('Side by side', 'Đặt cạnh nhau')),
                  selected: _sideBySide,
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
            if (_sideBySide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: frame(original, VisionMode.normal)),
                  const SizedBox(width: 8),
                  Expanded(child: frame(simulated, widget.settings.mode)),
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
                          widget.settings.mode,
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
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _split = .5),
                icon: const Icon(Icons.restart_alt),
                label: Text(context.t('Reset divider', 'Đặt lại thanh chia')),
              ),
            ),
            const Divider(),
            ModeControls(settings: widget.settings),
          ],
        ),
      ),
    );
  }
}

class OnboardingExample extends StatefulWidget {
  const OnboardingExample({super.key, required this.program});
  final ui.FragmentProgram program;

  @override
  State<OnboardingExample> createState() => _OnboardingExampleState();
}

class _OnboardingExampleState extends State<OnboardingExample> {
  ui.Image? image;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final loaded = await loadScene(scenes.first.asset);
      if (!mounted) {
        loaded.dispose();
        return;
      }
      setState(() => image = loaded);
    } catch (_) {
      // Onboarding text is still available if the bundled example is unreadable.
    }
  }

  @override
  void dispose() {
    image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = image;
    if (current == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(context.t('Original', 'Ảnh gốc')),
            Text(context.t('Deutan simulation', 'Mô phỏng Deutan')),
          ],
        ),
        const SizedBox(height: 8),
        ImageFrame(
          image: current,
          program: widget.program,
          mode: VisionMode.deutan,
          severity: 1,
          split: .5,
          label: context.copy(scenes.first.alt),
        ),
      ],
    );
  }
}
