import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:app_settings/app_settings.dart';
import 'package:camera/camera.dart';
import 'package:material_ui/material_ui.dart';

import '../i18n/copy.dart';
import '../models/scene.dart';
import '../services/delete_capture.dart';
import '../services/media.dart';
import '../state/simulation_settings.dart';
import '../theme/palette.dart';
import '../vision/filters.dart';
import '../vision/vision_copy.dart';
import '../widgets/app_icon.dart';
import '../widgets/image_frame.dart';
import '../widgets/mode_controls.dart';
import '../widgets/page_column.dart';
import '../widgets/vision_viewport.dart';
import 'comparison_screen.dart';

class Simulator extends StatefulWidget {
  const Simulator({
    super.key,
    required this.program,
    required this.openPhoto,
    required this.explore,
    this.photo,
    this.scene,
    this.filter,
    this.category,
  });

  final ui.FragmentProgram program;
  final ui.Image? photo;
  final Scene? scene;
  final VoidCallback openPhoto, explore;

  /// Filter chosen before the camera opened, if any.
  final VisionFilter? filter;

  /// Restricts the mode picker to one category, e.g. support-only entries.
  final FilterCategory? category;

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
  bool _torch = false;
  bool _hasFront = false;
  CameraLensDirection _lens = CameraLensDirection.back;
  String? _error;
  double _zoom = 1;
  double _baseZoom = 1;
  double _minZoom = 1;
  double _maxZoom = 1;
  Timer? _zoomLabelTimer;
  bool _showZoomLabel = false;
  bool get _isCamera => widget.photo == null && widget.scene == null;
  bool get _cameraWanted => !_disposed && _foreground && !_compare && !_blocked;

  @override
  void initState() {
    super.initState();
    if (widget.filter case final filter?) settings.select(filter);
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
      debugPrint(
        'MYEYES open lens=$_lens devices=${devices.map((c) => c.lensDirection).toList()}',
      );
      _hasFront = devices.any(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );
      final lens =
          devices
              .where((camera) => camera.lensDirection == _lens)
              .firstOrNull ??
          devices.firstOrNull;
      if (lens == null) {
        throw CameraException('NoCamera', 'No camera available.');
      }
      opening = CameraController(
        lens,
        // The front sensor is slower to capture at veryHigh on most devices.
        _lens == CameraLensDirection.front
            ? ResolutionPreset.high
            : ResolutionPreset.veryHigh,
        enableAudio: false,
      );
      await opening.initialize();
      if (!_cameraWanted) return;
      final controller = opening;
      _minZoom = await controller.getMinZoomLevel();
      _maxZoom = await controller.getMaxZoomLevel();
      _zoom = _minZoom;
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
      _torch = false;
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

  /// A new lens means a new controller, so dispose through the same queue
  /// open and close use, or the two races and leaves the camera stuck.
  Future<void> _flipLens() {
    if (!_hasFront || _loading || _capturing) return _cameraWork;
    setState(() {
      _lens = _lens == CameraLensDirection.back
          ? CameraLensDirection.front
          : CameraLensDirection.back;
    });
    debugPrint('MYEYES flip -> $_lens');
    _cameraWork = _cameraWork.then((_) async {
      final controller = _controller;
      _controller = null;
      if (controller != null) await _disposeCamera(controller);
    });
    return _syncCamera();
  }

  Future<void> _toggleTorch() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final wanted = !_torch;
    try {
      await controller.setFlashMode(wanted ? FlashMode.torch : FlashMode.off);
      if (mounted && !_disposed) setState(() => _torch = wanted);
    } on CameraException {
      if (mounted && !_disposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.t(
                'This camera has no flash.',
                'Camera này không có đèn flash.',
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _onZoom(double scale) async {
    final controller = _controller;
    if (controller == null || _minZoom >= _maxZoom) return;
    final next = (_baseZoom * scale).clamp(_minZoom, _maxZoom);
    if (next == _zoom) return;
    _zoom = next;
    await controller.setZoomLevel(_zoom);
    if (!mounted || _disposed) return;
    _zoomLabelTimer?.cancel();
    _zoomLabelTimer = Timer(const Duration(seconds: 1), () {
      if (mounted && !_disposed) setState(() => _showZoomLabel = false);
    });
    setState(() => _showZoomLabel = true);
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
        // The saved photo is already right-reading; only the live preview
        // below gets mirrored so it behaves like a mirror while framing.
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
        category: widget.category,
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
    _zoomLabelTimer?.cancel();
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
                      filter: settings.filter,
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
                            filter: settings.filter,
                            severity: settings.severity,
                            child: CameraPreview(controller),
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 120),
                  const SizedBox(height: 16),
                  ModeControls(settings: settings, category: widget.category),
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
              icon: const AppIcon(AppIcons.compare),
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
                    leading: const AppIcon(AppIcons.bulb),
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
            GestureDetector(
              onScaleStart: (_) => _baseZoom = _zoom,
              onScaleUpdate: (details) => unawaited(_onZoom(details.scale)),
              child: VisionCameraFilter(
                program: widget.program,
                filter: settings.filter,
                severity: settings.severity,
                child: _coveringPreview(controller),
              ),
            ),
          if (controller != null && _showZoomLabel)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 140),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: brandNavy.withValues(alpha: .72),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    child: Text(
                      '${_zoom.toStringAsFixed(1)}x',
                      style: const TextStyle(color: brandInk, fontSize: 13),
                    ),
                  ),
                ),
              ),
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
                        icon: const AppIcon(AppIcons.back),
                      ),
                      const SizedBox(width: 4),
                      if (controller != null) ...[
                        Expanded(child: _simulatingBadge()),
                        if (_lens == CameraLensDirection.back)
                          IconButton(
                            tooltip: context.t('Flash', 'Đèn flash'),
                            color: _torch ? brandAmber : brandInk,
                            onPressed: () => unawaited(_toggleTorch()),
                            icon: AppIcon(
                              _torch ? AppIcons.flashOn : AppIcons.flashOff,
                            ),
                          ),
                        if (_hasFront)
                          IconButton(
                            tooltip: context.t('Switch camera', 'Đổi camera'),
                            color: brandInk,
                            onPressed: () => unawaited(_flipLens()),
                            icon: const AppIcon(AppIcons.switchCamera),
                          ),
                      ],
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
                          icon: const AppIcon(AppIcons.adjust),
                          label: Text(context.t('Adjust', 'Điều chỉnh')),
                        ),
                        FilledButton.icon(
                          onPressed: _capturing || _compare
                              ? null
                              : _openCompare,
                          icon: const AppIcon(AppIcons.camera),
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
    builder: (context, constraints) {
      // value.aspectRatio is sensor-side (landscape); CameraPreview flips its
      // own AspectRatio in portrait, so the box has to flip too -- a tight
      // SizedBox with the wrong ratio stretches the texture instead.
      final sensor = controller.value.aspectRatio;
      final ratio = constraints.maxWidth >= constraints.maxHeight
          ? sensor
          : 1 / sensor;
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxWidth / ratio,
          // Mirror the front lens so the preview acts like a mirror, matching
          // the mirrored capture produced for that lens in services/media.dart.
          child: _lens == CameraLensDirection.front
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(math.pi),
                  child: CameraPreview(controller),
                )
              : CameraPreview(controller),
        ),
      );
    },
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppIcon(AppIcons.eye, color: brandAmber, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.t(
                'Simulating: ${filterName(context, settings.filter)}',
                'Đang mô phỏng: ${filterName(context, settings.filter)}',
              ),
              maxLines: 2,
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
          builder: (context, _) => ModeControls(
            settings: settings,
            category: widget.category,
            onSelect: () => Navigator.of(context).pop(),
          ),
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
            Image.asset(
              'assets/illustrations/recovery.webp',
              width: 112,
              height: 80,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
            const SizedBox(height: 12),
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
