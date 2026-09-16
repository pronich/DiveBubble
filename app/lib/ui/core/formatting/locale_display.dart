import 'package:flutter/widgets.dart';

import '../../../l10n/app_localizations.dart';

/// Native names, deliberately never translated — a diver needs to recognize their own
/// language's name even when the current UI language isn't it. Shared by the app-language
/// settings page and the onboarding language-selection step, so both list the same options
/// the same way.
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

/// Best-effort match of the device's own locale against our supported list, falling back to
/// the template locale (English) — same basic language-code match Flutter's own default
/// resolution uses, exposed here so "System default" can name what it actually resolves to
/// instead of just saying "System default" with no indication of which language that means.
Locale resolvedSystemLocale() {
  final deviceCode = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  for (final locale in AppLocalizations.supportedLocales) {
    if (locale.languageCode == deviceCode) return locale;
  }
  return const Locale('en');
}
