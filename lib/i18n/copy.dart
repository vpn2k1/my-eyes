import 'package:flutter/widgets.dart';

typedef LocalText = ({String en, String vi});
LocalText words(String en, String vi) => (en: en, vi: vi);

extension Copy on BuildContext {
  String t(String en, String vi) =>
      Localizations.localeOf(this).languageCode == 'vi' ? vi : en;
  String copy(LocalText value) => t(value.en, value.vi);
}
