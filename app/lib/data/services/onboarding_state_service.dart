import 'package:shared_preferences/shared_preferences.dart';

/// Whether the user has already seen the animated intro once — until real auth state
/// exists, this is the proxy for "new" vs "returning" that picks intro vs static splash.
class OnboardingStateService {
  static const _key = 'has_completed_intro';
  static const _languagePromptKey = 'has_seen_language_prompt';

  Future<bool> hasCompletedIntro() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> markIntroCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  /// Separate from [hasCompletedIntro] on purpose — a diver who installed before the
  /// language-selection step existed already has [hasCompletedIntro] true, but still needs
  /// this one-time screen surfaced once on their first launch after updating (see
  /// AppEntryGate's own returning-user branch).
  Future<bool> hasSeenLanguagePrompt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_languagePromptKey) ?? false;
  }

  Future<void> markLanguagePromptSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_languagePromptKey, true);
  }
}
