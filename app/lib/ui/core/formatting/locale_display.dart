import 'package:flutter/widgets.dart';

import '../../../l10n/app_localizations.dart';

/// Deliberately never translated — a diver needs to recognize their own language's name even when the current UI language isn't it.
const nativeLocaleNames = <String, String>{
  'en': 'English',
  'ru': 'Русский',
  'es': 'Español',
  'de': 'Deutsch',
  'da': 'Dansk',
  'sv': 'Svenska',
  'fr': 'Français',
};

String nativeNameFor(Locale locale) => nativeLocaleNames[locale.languageCode] ?? locale.languageCode;

/// Exposed here so "System default" can name what it actually resolves to instead of showing no indication of which language that means.
Locale resolvedSystemLocale() {
  final deviceCode = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  for (final locale in AppLocalizations.supportedLocales) {
    if (locale.languageCode == deviceCode) return locale;
  }
  return const Locale('en');
}
