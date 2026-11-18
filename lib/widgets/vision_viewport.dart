import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../vision/filters.dart';
import '../vision/vision.dart';

/// Images remain unchanged. The shader reads the same source for every render.
class VisionImage extends StatefulWidget {
  const VisionImage({
    super.key,
    required this.image,
    required this.program,
    required this.filter,
    required this.severity,
    required this.label,
    this.split,
  });

  final ui.Image image;
  final ui.FragmentProgram program;
  final VisionFilter filter;
  final double severity;

  /// Fraction of the frame shown in original color, anchored to the left.
  final double? split;
  final String label;

  @override
  State<VisionImage> createState() => _VisionImageState();
}

class _VisionImageState extends State<VisionImage> {
  late final ui.FragmentShader shader = widget.program.fragmentShader();

  @override
  void dispose() {
    shader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: widget.label,
      child: AspectRatio(
        aspectRatio: widget.image.width / widget.image.height,
        child: CustomPaint(
          painter: _ImagePainter(
            widget.image,
            shader,
            widget.filter,
            widget.severity,
            widget.split,
          ),
        ),
      ),
    );
  }
}

class _ImagePainter extends CustomPainter {
  const _ImagePainter(
    this.image,
    this.shader,
    this.filter,
    this.severity,
    this.split,
  );
  final ui.Image image;
  final ui.FragmentShader shader;
  final VisionFilter filter;
  final double severity;
  final double? split;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    void original() => canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      rect,
      Paint()..filterQuality = FilterQuality.medium,
    );
    if (isIdentity(filter.mode, severity) || split == 1) {
      original();
      return;
    }
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setImageSampler(0, image);
    setColorMatrix(shader, filter.mode, severity, correct: filter.correct);
    final divider = size.width * (split ?? 0);
    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(divider, 0, size.width, size.height),
      doAntiAlias: false,
    );
    canvas.drawRect(rect, Paint()..shader = shader);
    canvas.restore();
    if (divider <= 0) return;
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(0, 0, divider, size.height),
      doAntiAlias: false,
    );
    original();
    canvas.restore();
    final start = Offset(divider, 0);
    final end = Offset(divider, size.height);
    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = Colors.black
        ..strokeWidth = 4,
    );
    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _ImagePainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.filter != filter ||
      oldDelegate.severity != severity ||
      oldDelegate.split != split;
}

class VisionCameraFilter extends StatefulWidget {
  const VisionCameraFilter({
    super.key,
    required this.program,
    required this.filter,
    required this.severity,
    required this.child,
  });

  final ui.FragmentProgram program;
  final VisionFilter filter;
  final double severity;
  final Widget child;

  @override
  State<VisionCameraFilter> createState() => _VisionCameraFilterState();
}

class _VisionCameraFilterState extends State<VisionCameraFilter> {
  late ui.FragmentShader shader = _createShader();

  ui.FragmentShader _createShader() {
    final result = widget.program.fragmentShader();
    setColorMatrix(
      result,
      widget.filter.mode,
      widget.severity,
      correct: widget.filter.correct,
    );
    return result;
  }

  @override
  void didUpdateWidget(covariant VisionCameraFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter ||
        oldWidget.severity != widget.severity) {
      final oldShader = shader;
      shader = _createShader();
      WidgetsBinding.instance.addPostFrameCallback((_) => oldShader.dispose());
    }
  }

  @override
  void dispose() {
    shader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => VisionEffectOverlay(
    effect: widget.filter.effect,
    child: ImageFiltered(
      enabled: !isIdentity(widget.filter.mode, widget.severity),
      imageFilter: ui.ImageFilter.shader(shader),
      child: widget.child,
    ),
  );
}

/// Adds the losses a color matrix cannot express: softened focus, a film over
/// the frame, and parts of the field that are gone. Composited over [child]
/// rather than folded into the shader, so the shader stays color-only.
class VisionEffectOverlay extends StatelessWidget {
  const VisionEffectOverlay({super.key, this.effect, required this.child});

  final VisionEffect? effect;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final effect = this.effect;
    if (effect == null) return child;

    var result = child;
    if (effect.blur > 0) {
      result = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: effect.blur,
          sigmaY: effect.blur,
          tileMode: TileMode.decal,
        ),
        child: result,
      );
    }

    final overlays = <Widget>[
      if (effect.scrim case final color?) ColoredBox(color: color),
      if (effect.vignette > 0)
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: .9,
              colors: const [Colors.transparent, Colors.black],
              stops: [(1 - effect.vignette).clamp(0.0, .95), 1],
            ),
          ),
        ),
      if (effect.scotoma > 0)
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: effect.scotoma,
              colors: const [Color(0xdd5a5a5a), Color(0x005a5a5a)],
              stops: const [.5, 1],
            ),
          ),
        ),
    ];
    if (overlays.isEmpty) return result;
    return Stack(
      // Every child fills the frame, so keep the Stack non-directional and
      // usable without a Directionality ancestor.
      alignment: Alignment.topLeft,
      fit: StackFit.passthrough,
      children: [
        result,
        for (final overlay in overlays) Positioned.fill(child: overlay),
      ],
    );
  }
}
