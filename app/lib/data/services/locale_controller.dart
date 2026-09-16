import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Null means "follow the device"; a ValueNotifier so MyApp's MaterialApp can pick up a change immediately without threading a rebuild callback down to LanguageSettingsPage.
class LocaleController extends ValueNotifier<Locale?> {
  LocaleController() : super(null);

  static const _prefsKey = 'app_locale';

  /// Call once at startup before the first frame that might care (see main.dart's initState).
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
