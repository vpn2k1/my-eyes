import 'package:flutter/widgets.dart';

enum AppIcons {
  camera,
  video,
  switchCamera,
  photo,
  brokenImage,
  learn,
  search,
  eye,
  compare,
  settings,
  info,
  help,
  bulb,
  flashOn,
  flashOff,
  adjust,
  palette,
  chevron,
  back,
  check,
  external,
  restart;

  bool get monochrome => switch (this) {
    chevron || back || check || external || restart => true,
    _ => false,
  };
}

/// Decorative artwork; the surrounding button or row supplies its label.
class AppIcon extends StatelessWidget {
  const AppIcon(this.icon, {super.key, this.size, this.color});

  final AppIcons icon;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final extent = size ?? theme.size ?? 24;
    return Opacity(
      opacity: theme.opacity ?? 1,
      child: Image.asset(
        'assets/icons/${icon.name}.webp',
        width: extent,
        height: extent,
        color: icon.monochrome ? color ?? theme.color : null,
        excludeFromSemantics: true,
        matchTextDirection: icon == AppIcons.back || icon == AppIcons.chevron,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}
