import 'package:shared_preferences/shared_preferences.dart';

/// Whether the user has already seen the animated intro once — until real auth state
/// exists, this is the proxy for "new" vs "returning" that picks intro vs static splash.
class OnboardingStateService {
  static const _key = 'has_completed_intro';

  Future<bool> hasCompletedIntro() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> markIntroCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
