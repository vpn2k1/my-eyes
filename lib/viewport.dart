import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import 'vision.dart';

/// Images remain unchanged. The shader reads the same source for every render.
class VisionImage extends StatefulWidget {
  const VisionImage({
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
            widget.mode,
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
    this.mode,
    this.severity,
    this.split,
  );
  final ui.Image image;
  final ui.FragmentShader shader;
  final VisionMode mode;
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
    if (isIdentity(mode, severity) || split == 1) {
      original();
      return;
    }
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setImageSampler(0, image);
    setColorMatrix(shader, mode, severity);
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
      oldDelegate.mode != mode ||
      oldDelegate.severity != severity ||
      oldDelegate.split != split;
}

class VisionCameraFilter extends StatefulWidget {
  const VisionCameraFilter({
    super.key,
    required this.program,
    required this.mode,
    required this.severity,
    required this.child,
  });

  final ui.FragmentProgram program;
  final VisionMode mode;
  final double severity;
  final Widget child;

  @override
  State<VisionCameraFilter> createState() => _VisionCameraFilterState();
}

class _VisionCameraFilterState extends State<VisionCameraFilter> {
  late ui.FragmentShader shader = _createShader();

  ui.FragmentShader _createShader() {
    final result = widget.program.fragmentShader();
    setColorMatrix(result, widget.mode, widget.severity);
    return result;
  }

  @override
  void didUpdateWidget(covariant VisionCameraFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode ||
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
  Widget build(BuildContext context) => ImageFiltered(
    enabled: !isIdentity(widget.mode, widget.severity),
    imageFilter: ui.ImageFilter.shader(shader),
    child: widget.child,
  );
}
