import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_eyes/main.dart';
import 'package:my_eyes/simulator.dart';
import 'package:my_eyes/vision.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryPreferences implements SharedPreferencesAsync {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  final _values = <String, bool>{};
  bool get completed => _values['onboarding_completed'] ?? false;
  @override
  Future<bool?> getBool(String key) async => completed;
  @override
  Future<void> setBool(String key, bool value) async {
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
    await tester.tap(find.text('Protan'));
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
              of: find.text('Protan'),
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
    await tester.tap(find.text('Grayscale'));
    await tester.pump();
    expect(find.byType(Slider), findsNothing);
    await tester.tap(find.text('Protan'));
    await tester.pump();
    expect(settings.mode, VisionMode.protan);
    expect(tester.widget<Slider>(find.byType(Slider)).value, .55);
  });
}
