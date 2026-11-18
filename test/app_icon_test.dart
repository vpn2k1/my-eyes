import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_eyes/widgets/app_icon.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every UI icon is bundled and decodes as WebP', () async {
    for (final icon in AppIcons.values) {
      final data = await rootBundle.load('assets/icons/${icon.name}.webp');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      expect(frame.image.width, 144, reason: icon.name);
      expect(frame.image.height, 144, reason: icon.name);
      frame.image.dispose();
      codec.dispose();
    }
  });

  testWidgets('icons follow theme size, opacity and monochrome tint', (
    tester,
  ) async {
    const tint = Color(0xfff5f7fd);
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: IconTheme(
          data: IconThemeData(size: 32, color: tint, opacity: .5),
          child: Row(
            children: [AppIcon(AppIcons.back), AppIcon(AppIcons.camera)],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    expect(images.first.color, tint);
    expect(images.last.color, isNull);
    expect(
      images.every((image) => image.width == 32 && image.height == 32),
      isTrue,
    );
    expect(images.every((image) => image.excludeFromSemantics), isTrue);
    expect(
      tester
          .widgetList<Opacity>(find.byType(Opacity))
          .every((o) => o.opacity == .5),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
}
