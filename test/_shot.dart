import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_eyes/eye_test.dart';

const dir = '/private/tmp/claude-501/-Users-mn13-Projects-Flutter-Project-my-eyes/12b70d9d-3c81-4e39-8ed6-c59272eb4021/scratchpad/shots';

void main() {
  testWidgets('shots', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const RepaintBoundary(child: MaterialApp(home: EyeTest())),
    );
    await tester.pumpAndSettle();

    Future<void> shot(String name) async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byType(RepaintBoundary).first,
      );
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$dir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    }

    await shot('q1_dots_redgreen_pair');
    // Walk to the red-green combo plate (index 4) and a swatch question.
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Not sure / Skip'));
      await tester.pumpAndSettle();
    }
    await shot('q5_dots_red_green');
    for (var i = 0; i < 10; i++) {
      await tester.tap(find.text('Not sure / Skip'));
      await tester.pumpAndSettle();
    }
    await shot('q15_swatches');
  });
}
