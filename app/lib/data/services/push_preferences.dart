import 'package:shared_preferences/shared_preferences.dart';

/// Local-only "did the diver explicitly turn push off" flag — checked both by main.dart's
/// auto-registration (sign-in, token refresh, app resume) and NotificationsSettingsPage's
/// toggle, so an explicit opt-out isn't silently undone by the next unrelated auth event.
/// Default true: push is opt-out, not opt-in, once the OS permission itself is granted.
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
