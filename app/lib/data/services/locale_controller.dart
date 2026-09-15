import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The diver's manually-chosen app language, overriding the device's own locale — null means
/// "follow the device" (the default, and the only state before this ever existed). A
/// ValueNotifier so MyApp's MaterialApp can pick up a change immediately (see main.dart's
/// ListenableBuilder around it) without threading a rebuild callback through every layer
/// between it and LanguageSettingsPage, several screens down.
class LocaleController extends ValueNotifier<Locale?> {
  LocaleController() : super(null);

  static const _prefsKey = 'app_locale';

  /// Reads the saved choice, if any — call once at startup before the first frame that
  /// might care (see main.dart's initState). Leaves [value] at its default (null, meaning
  /// "follow the device") on first-ever launch or if nothing was ever explicitly chosen.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code != null) value = Locale(code);
  }

  Future<void> setLocale(Locale? locale) async {
    value = locale;
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, locale.languageCode);
    }
  }
}
