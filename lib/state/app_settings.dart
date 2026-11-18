import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeKey = 'theme_mode';
const _languageKey = 'language';

/// App theme and language chosen by the person using the app.
/// Both default to the device setting, and an unsupported device language
/// falls back to English through [MaterialApp.supportedLocales].
class AppSettings extends ChangeNotifier {
  AppSettings(this._prefs);
  final SharedPreferencesAsync _prefs;

  ThemeMode themeMode = ThemeMode.system;
  Locale? locale;

  static Locale? _localeOf(String? code) =>
      code == 'en' || code == 'vi' ? Locale(code!) : null;

  Future<void> restore() async {
    String? theme;
    String? language;
    try {
      theme = await _prefs.getString(_themeKey);
      language = await _prefs.getString(_languageKey);
    } catch (_) {
      // The device theme and language remain available.
    }
    themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == theme,
      orElse: () => ThemeMode.system,
    );
    locale = _localeOf(language);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == themeMode) return;
    themeMode = mode;
    notifyListeners();
    await _store(_themeKey, mode.name);
  }

  Future<void> setLanguage(String? code) async {
    final next = _localeOf(code);
    if (next == locale) return;
    locale = next;
    notifyListeners();
    await _store(_languageKey, next?.languageCode ?? 'system');
  }

  Future<void> _store(String key, String value) async {
    try {
      await _prefs.setString(key, value);
    } catch (_) {
      // The choice still applies to the current session.
    }
  }
}
