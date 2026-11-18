import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';

import 'screens/home_screen.dart';
import 'state/app_settings.dart';
import 'theme/palette.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyEyes());
}

class MyEyes extends StatefulWidget {
  const MyEyes({super.key, this.prefs});
  final SharedPreferencesAsync? prefs;

  @override
  State<MyEyes> createState() => _MyEyesState();
}

class _MyEyesState extends State<MyEyes> {
  late final SharedPreferencesAsync _prefs;
  late final AppSettings _settings;

  @override
  void initState() {
    super.initState();
    _prefs = widget.prefs ?? SharedPreferencesAsync();
    _settings = AppSettings(_prefs);
    unawaited(_settings.restore());
  }

  @override
  void dispose() {
    _settings.dispose();
    super.dispose();
  }

  ThemeData _theme(Brightness brightness) {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandSeed,
        brightness: brightness,
      ),
      useMaterial3: true,
    );
    final text = base.textTheme;
    final scheme = base.colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    );
    return base.copyWith(
      extensions: [
        brightness == Brightness.dark ? AppAccents.dark : AppAccents.light,
      ],
      textTheme: text.copyWith(
        headlineLarge: text.headlineLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
        headlineMedium: text.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
        ),
        headlineSmall: text.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        pressElevation: 0,
        backgroundColor: scheme.surfaceContainerLow,
        secondarySelectedColor: scheme.primary,
        checkmarkColor: scheme.onPrimary,
        showCheckmark: true,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        labelStyle: text.labelLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: text.labelLarge?.copyWith(
          color: scheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
        side: WidgetStateBorderSide.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.outlineVariant,
          ),
        ),
      ),
      cardTheme: CardThemeData(elevation: 0, shape: shape),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: shape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: shape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: shape,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _settings,
    builder: (context, _) => MaterialApp(
      title: 'My Eyes',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: _settings.themeMode,
      locale: _settings.locale,
      supportedLocales: const [Locale('en'), Locale('vi')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: UpgradeAlert(
        // Soft reminder: no minAppVersion set, Ignore/Later shown by default.
        child: Home(prefs: _prefs, settings: _settings),
      ),
    ),
  );
}
