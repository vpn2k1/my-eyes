import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../i18n/copy.dart';
import '../state/app_settings.dart';

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
