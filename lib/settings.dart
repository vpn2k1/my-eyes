import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'content.dart';

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

Future<void> showSettingsSheet(BuildContext context, AppSettings settings) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListenableBuilder(
        listenable: settings,
        builder: (context, _) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 12),
            children: [
              _heading(context, context.t('Appearance', 'Giao diện')),
              RadioGroup<ThemeMode>(
                groupValue: settings.themeMode,
                onChanged: (mode) =>
                    unawaited(settings.setThemeMode(mode ?? ThemeMode.system)),
                child: Column(
                  children: [
                    for (final option in <(ThemeMode, String)>[
                      (
                        ThemeMode.system,
                        context.t('System default', 'Theo thiết bị'),
                      ),
                      (ThemeMode.light, context.t('Light', 'Sáng')),
                      (ThemeMode.dark, context.t('Dark', 'Tối')),
                    ])
                      RadioListTile<ThemeMode>(
                        value: option.$1,
                        title: Text(option.$2),
                      ),
                  ],
                ),
              ),
              _heading(context, context.t('Language', 'Ngôn ngữ')),
              RadioGroup<String>(
                groupValue: settings.locale?.languageCode ?? 'system',
                onChanged: (code) => unawaited(settings.setLanguage(code)),
                child: Column(
                  children: [
                    for (final option in <(String, String)>[
                      ('system', context.t('System default', 'Theo thiết bị')),
                      ('en', 'English'),
                      ('vi', 'Tiếng Việt'),
                    ])
                      RadioListTile<String>(
                        value: option.$1,
                        title: Text(option.$2),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

Widget _heading(BuildContext context, String title) => Padding(
  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
  child: Text(title, style: Theme.of(context).textTheme.titleMedium),
);
