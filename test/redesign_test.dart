import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:my_eyes/main.dart';
import 'package:my_eyes/widgets/mode_controls.dart';
import 'package:my_eyes/state/simulation_settings.dart';
import 'package:my_eyes/models/eye_test_score.dart';
import 'package:my_eyes/models/plate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_eyes/services/media.dart';
import 'package:my_eyes/vision/filters.dart';
import 'package:my_eyes/widgets/vision_viewport.dart';
import 'package:my_eyes/theme/palette.dart';
import 'package:my_eyes/vision/vision.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'widget_test.dart' show MemoryPreferences;

// Optional local review artifacts; normal test runs do not write files.
const previewDirectory = String.fromEnvironment('DESIGN_PREVIEW_DIR');
final previewKey = GlobalKey();

Future<void> capture(WidgetTester tester, String name) async {
  if (previewDirectory.isEmpty) return;
  final imageWidgets = tester.widgetList<Image>(find.byType(Image)).toList();
  await tester.runAsync(
    () => Future.wait([
      for (final image in imageWidgets)
        precacheImage(image.image, tester.element(find.byWidget(image))),
    ]),
  );
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final boundary =
        previewKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory(previewDirectory)..createSync(recursive: true);
    await File('${directory.path}/$name.png').writeAsBytes(
      png!.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes),
    );
    image.dispose();
  });
}

Future<MemoryPreferences> preferences(Brightness brightness) async {
  final prefs = MemoryPreferences();
  await prefs.setBool('onboarding_completed', true);
  await prefs.setString('theme_mode', brightness.name);
  return prefs;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  // The preview mode loads the SDK's system-default Android typeface, avoiding
  // Ahem's block glyphs. Fonts are only used in exported review screenshots.
  setUpAll(() async {
    if (previewDirectory.isEmpty) return;
    final sdk = Platform.environment['FLUTTER_ROOT'];
    if (sdk == null) {
      throw StateError('Set FLUTTER_ROOT when exporting previews');
    }
    final fonts = FontLoader('Roboto');
    for (final file in [
      'Roboto-Regular.ttf',
      'Roboto-Bold.ttf',
      'Roboto-Black.ttf',
    ]) {
      fonts.addFont(
        File(
          '$sdk/bin/cache/artifacts/material_fonts/$file',
        ).readAsBytes().then(ByteData.sublistView),
      );
    }
    await fonts.load();
    await (FontLoader('MaterialIcons')..addFont(
          File(
            '$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
          ).readAsBytes().then(ByteData.sublistView),
        ))
        .load();
  });

  for (final brightness in Brightness.values) {
    testWidgets('Home and guidance fit large text in ${brightness.name}', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final prefs = await preferences(brightness);
      await tester.pumpWidget(
        RepaintBoundary(
          key: previewKey,
          child: MyEyes(prefs: prefs),
        ),
      );
      await tester.pumpAndSettle();
      final homeContext = tester.element(find.text('My Eyes').first);
      expect(Theme.of(homeContext).brightness, brightness);
      expect(Theme.of(homeContext).extension<AppAccents>(), isNotNull);
      final entries = tester.widgetList<ListTile>(find.byType(ListTile));
      expect(entries.length, 5);
      for (final entry in entries) {
        expect(entry.leading, isNotNull);
        expect(entry.trailing, isNotNull);
        expect(entry.onTap, isNotNull);
        expect(
          tester.getSize(find.byWidget(entry)).height,
          greaterThanOrEqualTo(48),
        );
      }
      await capture(tester, 'home-${brightness.name}');
      expect(tester.takeException(), isNull);

      await tester.binding.setSurfaceSize(const Size(320, 900));
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('About My Eyes'));
      await tester.pumpAndSettle();
      await capture(tester, 'guidance-large-${brightness.name}');
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -1500),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'picker, camera fallback, explore and comparison in ${brightness.name}',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 1100));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          RepaintBoundary(
            key: previewKey,
            child: MyEyes(prefs: await preferences(brightness)),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Experience a condition'));
        await tester.pumpAndSettle();
        await capture(tester, 'picker-${brightness.name}');
        await tester.tap(find.text('Deuteranopia'));
        await tester.pumpAndSettle();
        expect(find.text('Use a sample'), findsOneWidget);
        await capture(tester, 'camera-fallback-${brightness.name}');
        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Explore and learn'));
        await tester.tap(find.text('Explore and learn'));
        await tester.pumpAndSettle();
        await capture(tester, 'explore-${brightness.name}');
        await tester.tap(find.text('Learn'));
        await tester.pumpAndSettle();
        await capture(tester, 'learn-${brightness.name}');
        await tester.tap(find.text('Scenes'));
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          await tester.tap(find.text('Traffic signals'));
          await Future<void>.delayed(const Duration(milliseconds: 250));
          await tester.pump(const Duration(milliseconds: 350));
          await Future<void>.delayed(const Duration(milliseconds: 250));
        });
        await tester.pumpAndSettle();
        expect(find.text('Vision mode'), findsOneWidget);
        await capture(tester, 'simulator-${brightness.name}');
        await tester.ensureVisible(find.text('Compare with original'));
        await tester.tap(find.text('Compare with original'));
        await tester.pumpAndSettle();
        expect(find.text('Original'), findsOneWidget);
        expect(find.text('Simulated'), findsOneWidget);
        await capture(tester, 'comparison-${brightness.name}');
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'mode chips wrap Vietnamese labels and preserve selection in ${brightness.name}',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 1100));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(MyEyes(prefs: await preferences(brightness)));
        await tester.pumpAndSettle();
        final theme = Theme.of(tester.element(find.text('My Eyes').first));
        final settings = SimulationSettings();
        addTearDown(settings.dispose);
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(
          RepaintBoundary(
            key: previewKey,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: theme,
              locale: const Locale('vi'),
              supportedLocales: const [Locale('vi')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              home: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ListenableBuilder(
                    listenable: settings,
                    builder: (context, _) => ModeControls(settings: settings),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(theme.chipTheme.shape, isA<RoundedRectangleBorder>());
        expect(theme.chipTheme.showCheckmark, isTrue);
        for (final element in find.byType(ChoiceChip).evaluate()) {
          final rect = tester.getRect(
            find.byElementPredicate((e) => e == element),
          );
          expect(rect.height, greaterThanOrEqualTo(48));
          expect(rect.left, greaterThanOrEqualTo(20));
          expect(rect.right, lessThanOrEqualTo(300));
        }
        for (final element
            in find
                .descendant(
                  of: find.byType(ChoiceChip),
                  matching: find.byType(RichText),
                )
                .evaluate()) {
          final paragraph = element.renderObject! as RenderParagraph;
          expect(paragraph.didExceedMaxLines, isFalse);
        }
        final target = find.ancestor(
          of: find.text('Deuteranomaly – giảm sắc xanh lá'),
          matching: find.byType(ChoiceChip),
        );
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(settings.filter.id, 'deuteranomaly');
        expect(tester.widget<ChoiceChip>(target).selected, isTrue);
        expect(
          tester
              .widgetList<ChoiceChip>(find.byType(ChoiceChip))
              .where((chip) => chip.selected),
          hasLength(1),
        );
        await capture(tester, 'chips-vi-large-${brightness.name}');
        expect(tester.takeException(), isNull);
      },
    );

    for (final verdict in Verdict.values) {
      testWidgets('${verdict.name} result illustration in ${brightness.name}', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(390, 1100));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          RepaintBoundary(
            key: previewKey,
            child: MyEyes(prefs: await preferences(brightness)),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Test your color vision'));
        await tester.tap(find.text('Test your color vision'));
        await tester.pumpAndSettle();
        final semantics = tester.ensureSemantics();

        for (var i = 0; i < questionCount; i++) {
          final plate = plates[i % plates.length];
          final skip = switch (verdict) {
            Verdict.typical => false,
            Verdict.redGreen => plate.axes.any(
              (axis) => axis != VisionMode.tritan,
            ),
            Verdict.blueYellow => plate.axes.contains(VisionMode.tritan),
            Verdict.broad => true,
          };
          if (skip) {
            await tester.tap(find.text('Not sure / Skip'));
          } else if (i < plates.length) {
            await tester.tap(
              find.widgetWithText(OutlinedButton, '${plate.digit}'),
            );
          } else {
            await tester.tap(
              find.bySemanticsLabel('Square ${(i * 7 + 2) % 4 + 1}'),
            );
          }
          await tester.pumpAndSettle();
        }
        semantics.dispose();
        expect(find.text('Result'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Image &&
                widget.image is AssetImage &&
                (widget.image as AssetImage).assetName ==
                    'assets/illustrations/${verdict.name}.webp',
          ),
          findsOneWidget,
        );
        await capture(tester, 'result-${verdict.name}-${brightness.name}');
        await tester.binding.setSurfaceSize(const Size(320, 900));
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpAndSettle();
        await tester.drag(
          find.byType(SingleChildScrollView).last,
          const Offset(0, -500),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets(
    'review exported screenshots through photo import and the production shader',
    (tester) async {
      final program = await ui.FragmentProgram.fromAsset('shaders/vision.frag');
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final brightness in Brightness.values) {
        for (final name in [
          'home-${brightness.name}',
          for (final verdict in Verdict.values)
            'result-${verdict.name}-${brightness.name}',
        ]) {
          final image = await tester.runAsync(
            () => loadPhoto(XFile('$previewDirectory/$name.png')),
          );
          expect(image, isNotNull);
          await tester.binding.setSurfaceSize(
            Size(image!.width.toDouble(), image.height.toDouble()),
          );
          for (final mode in [
            VisionMode.protan,
            VisionMode.deutan,
            VisionMode.tritan,
          ]) {
            await tester.pumpWidget(
              RepaintBoundary(
                key: previewKey,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: VisionImage(
                    image: image,
                    program: program,
                    filter: defaultFilterFor(mode),
                    severity: 1,
                    label: name,
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            await capture(tester, '$name-${mode.name}');
            expect(tester.takeException(), isNull);
          }
          await tester.pumpWidget(const SizedBox());
          image.dispose();
        }
      }
    },
    skip: previewDirectory.isEmpty,
  );
}
