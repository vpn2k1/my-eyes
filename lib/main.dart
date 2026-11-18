import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  ThemeData _theme(Brightness brightness) => ThemeData(
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: brandSeed,
      brightness: brightness,
    ),
    useMaterial3: true,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
  );

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
      home: Home(prefs: _prefs, settings: _settings),
    ),
  );
}
