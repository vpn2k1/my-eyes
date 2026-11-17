import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_eyes/main.dart';
import 'package:my_eyes/simulator.dart';
import 'package:my_eyes/eye_test.dart';
import 'package:my_eyes/vision.dart';
import 'package:my_eyes/vision_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryPreferences implements SharedPreferencesAsync {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  final _values = <String, Object>{};
  bool get completed => _values['onboarding_completed'] == true;
  String? operator [](String key) => _values[key] as String?;
  @override
  Future<bool?> getBool(String key) async => completed;
  @override
  Future<void> setBool(String key, bool value) async {
    _values[key] = value;
  }

  @override
  Future<String?> getString(String key) async => _values[key] as String?;
  @override
  Future<void> setString(String key, String value) async {
    _values[key] = value;
  }
}

void main() {
  testWidgets('onboarding can be skipped, persists, and can be reopened', (
    tester,
  ) async {
    final prefs = MemoryPreferences();
    await tester.pumpWidget(MyEyes(prefs: prefs));
    await tester.pump();
    expect(find.textContaining('cannot diagnose'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(prefs.completed, isTrue);
    expect(find.text('Explore and learn'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(MyEyes(prefs: prefs));
    await tester.pumpAndSettle();
    expect(find.text('Open camera'), findsOneWidget);
    await tester.tap(find.byTooltip('About My Eyes'));
    await tester.pumpAndSettle();
    expect(find.textContaining('cannot diagnose'), findsOneWidget);
  });

  testWidgets('scene opens the simulator and compare preserves settings', (
    tester,
  ) async {
    final prefs = MemoryPreferences();
    await prefs.setBool('onboarding_completed', true);
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MyEyes(prefs: prefs));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore and learn'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('Traffic signals'));
      await Future<void>.delayed(const Duration(milliseconds: 120));
      await tester.pump(const Duration(milliseconds: 350));
      await Future<void>.delayed(const Duration(milliseconds: 120));
    });
    await tester.pumpAndSettle();
    expect(find.text('Vision mode'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Three stacked lights above a street'),
      findsOneWidget,
    );
    tester.widget<Slider>(find.byType(Slider)).onChanged!(.55);
    await tester.tap(find.text('Red color blindness'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Compare with original'));
    await tester.tap(find.text('Compare with original'));
    await tester.pumpAndSettle();
    expect(find.text('Original'), findsOneWidget);
    expect(find.text('Simulated'), findsOneWidget);
    final sliders = find.byType(Slider);
    expect(tester.widget<Slider>(sliders.first).value, .5);
    tester.widget<Slider>(sliders.first).onChanged!(0);
    await tester.pump();
    expect(tester.widget<Slider>(sliders.first).value, 0);
    tester.widget<Slider>(sliders.first).onChanged!(1);
    await tester.pump();
    expect(tester.widget<Slider>(sliders.first).value, 1);
    await tester.tap(find.text('Side by side'));
    await tester.pumpAndSettle();
    expect(tester.widget<Slider>(sliders).value, .55);
    expect(
      tester
          .widget<ChoiceChip>(
            find.ancestor(
              of: find.text('Red color blindness'),
              matching: find.byType(ChoiceChip),
            ),
          )
          .selected,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Vietnamese scene library and education render at desktop width',
    (tester) async {
      final prefs = MemoryPreferences();
      await prefs.setBool('onboarding_completed', true);
      tester.binding.platformDispatcher.localesTestValue = const [
        Locale('vi', 'VN'),
      ];
      addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MyEyes(prefs: prefs));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Khám phá và tìm hiểu'));
      await tester.pumpAndSettle();
      expect(find.text('Đèn giao thông'), findsOneWidget);
      expect(find.text('Đồ dùng học tập'), findsOneWidget);
      await tester.tap(find.text('Kiến thức'));
      await tester.pumpAndSettle();
      expect(find.text('Nguồn tham khảo'), findsOneWidget);
      expect(find.text('National Eye Institute'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('settings choose language and theme, and persist', (
    tester,
  ) async {
    final prefs = MemoryPreferences();
    await prefs.setBool('onboarding_completed', true);
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MyEyes(prefs: prefs));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếng Việt'));
    await tester.pumpAndSettle();
    expect(prefs['language'], 'vi');
    await tester.tap(find.text('Tối'));
    await tester.pumpAndSettle();
    expect(prefs['theme_mode'], 'dark');
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    await tester.tapAt(const Offset(195, 20));
    await tester.pumpAndSettle();
    expect(find.text('Mở camera'), findsOneWidget);

    // The stored choices apply again on the next launch.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(MyEyes(prefs: prefs));
    await tester.pumpAndSettle();
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(app.locale, const Locale('vi'));
    expect(find.text('Mở camera'), findsOneWidget);
  });

  testWidgets('fixed modes hide severity and recolor modes retain it', (
    tester,
  ) async {
    final settings = SimulationSettings();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListenableBuilder(
            listenable: settings,
            builder: (context, _) => ModeControls(settings: settings),
          ),
        ),
      ),
    );
    tester.widget<Slider>(find.byType(Slider)).onChanged!(.55);
    await tester.pump();
    await tester.tap(find.text('Total color blindness'));
    await tester.pump();
    expect(find.byType(Slider), findsNothing);
    await tester.tap(find.text('Red color blindness'));
    await tester.pump();
    expect(settings.mode, VisionMode.protan);
    expect(tester.widget<Slider>(find.byType(Slider)).value, .55);
  });

  testWidgets('camera entry picks a type by group before opening', (
    tester,
  ) async {
    final prefs = MemoryPreferences();
    await prefs.setBool('onboarding_completed', true);
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MyEyes(prefs: prefs));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open camera'));
    await tester.pumpAndSettle();

    // Red-green is a group heading, not a selectable fourth type.
    expect(find.byType(VisionPicker), findsOneWidget);
    expect(find.text('RED – GREEN DEFICIENCY'), findsOneWidget);
    expect(find.text('Green color blindness'), findsOneWidget);
    expect(find.text('Red color blindness'), findsOneWidget);
    expect(find.text('Check your eyes'), findsOneWidget);
    expect(find.textContaining('Deuteranopia · deuteranomaly'), findsOneWidget);
  });

  testWidgets('answering every question right reads as typical', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const MaterialApp(home: EyeTest()));
    await tester.pumpAndSettle();

    for (var i = 0; i < questionCount; i++) {
      if (i < plates.length) {
        // Tap the digit actually hidden in the plate.
        await tester.tap(
          find.widgetWithText(OutlinedButton, '${plates[i].digit}'),
        );
      } else {
        // The odd swatch is fixed per question, same formula as the screen.
        final odd = (i * 7 + 2) % 4;
        await tester.tap(find.bySemanticsLabel('Square ${odd + 1}'));
      }
      await tester.pumpAndSettle();
    }

    semantics.dispose();
    expect(
      find.textContaining('No sign of color vision deficiency'),
      findsOneWidget,
    );
    expect(find.textContaining('Red – green: 0% missed'), findsOneWidget);
    expect(find.textContaining('Blue – yellow: 0% missed'), findsOneWidget);
    // Typical suggests nothing, so there is no camera shortcut to offer.
    expect(find.text('View camera as this type'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the screening runs end to end and suggests a type', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    VisionMode? popped;
    var popCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              popped = await Navigator.of(context).push<VisionMode?>(
                MaterialPageRoute(builder: (_) => const EyeTest()),
              );
              popCount++;
            },
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    // Skip every question: "not sure" counts as a miss on all three axes.
    for (var i = 0; i < questionCount; i++) {
      // One answer must advance exactly one question, never jump to the end.
      expect(
        find.textContaining('${i + 1} of $questionCount'),
        findsOneWidget,
        reason: 'should be on question ${i + 1}',
      );
      expect(find.text('Result'), findsNothing, reason: 'early result');
      await tester.tap(find.text('Not sure / Skip'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Result'), findsOneWidget);
    expect(find.textContaining('not a medical diagnosis'), findsOneWidget);
    expect(find.textContaining('both groups'), findsOneWidget);

    await tester.tap(find.text('View camera as this type'));
    await tester.pumpAndSettle();
    expect(popCount, 1);
    expect(popped, isNotNull);
    expect(tester.takeException(), isNull);
  });
}
