import 'package:shared_preferences/shared_preferences.dart';

/// Checked by both main.dart's auto-registration and the settings toggle, so an explicit opt-out isn't silently undone by the next unrelated auth event. Defaults true (opt-out, not opt-in).
class PushPreferences {
  static const _key = 'push_notifications_enabled';

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? true;
  }

  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}
