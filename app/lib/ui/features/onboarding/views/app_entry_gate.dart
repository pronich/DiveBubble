import 'package:flutter/material.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/push_repository.dart';
import '../../../../data/services/locale_controller.dart';
import '../../../../data/services/onboarding_state_service.dart';
import '../../../core/theme/app_gradients.dart';
import 'intro_view.dart';
import 'language_onboarding_page.dart';
import 'static_splash_view.dart';

enum _Phase { loading, intro, languageSelect, staticSplash, app }

/// The language-selection step is shown exactly once per device regardless of which path a diver is on; both converge on the same [OnboardingStateService.markLanguagePromptSeen] flag.
class AppEntryGate extends StatefulWidget {
  const AppEntryGate({
    super.key,
    required this.authRepository,
    required this.profileRepository,
    required this.pushRepository,
    required this.localeController,
    required this.rootShellBuilder,
  });

  final AuthRepository authRepository;
  final ProfileRepository profileRepository;
  final PushRepository pushRepository;
  final LocaleController localeController;

  /// Resolved fresh right before entering the app, not fixed at app startup, since sign-in can happen during the intro flow itself.
  final Widget Function(BuildContext, String currentUserId) rootShellBuilder;

  @override
  State<AppEntryGate> createState() => _AppEntryGateState();
}

class _AppEntryGateState extends State<AppEntryGate> {
  final _service = OnboardingStateService();
  _Phase _phase = _Phase.loading;
  String _currentUserId = '';

  // Only meaningful on the returning-user path — a brand-new diver always sees the language step right after intro regardless of this flag.
  bool _needsLanguagePromptAfterSplash = false;

  @override
  void initState() {
    super.initState();
    _service.hasCompletedIntro().then((completed) async {
      if (!mounted) return;
      if (!completed) {
        setState(() => _phase = _Phase.intro);
        return;
      }
      final seenLanguagePrompt = await _service.hasSeenLanguagePrompt();
      if (!mounted) return;
      _needsLanguagePromptAfterSplash = !seenLanguagePrompt;
      setState(() => _phase = _Phase.staticSplash);
    });
    // Without this, _currentUserId stayed frozen at its first-resolved value, and every isMine/currentUserId comparison downstream would compare against the wrong id for the app's process lifetime.
    widget.authRepository.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    if (_phase != _Phase.app) return;
    widget.authRepository.currentUserId().then((userId) {
      if (!mounted) return;
      setState(() => _currentUserId = userId ?? '');
    });
  }

  Future<void> _enterApp() async {
    final userId = await widget.authRepository.currentUserId() ?? '';
    if (!mounted) return;
    setState(() {
      _currentUserId = userId;
      _phase = _Phase.app;
    });
  }

  @override
  void dispose() {
    widget.authRepository.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _completeIntro() {
    _service.markIntroCompleted();
    setState(() => _phase = _Phase.languageSelect);
  }

  void _completeStaticSplash() {
    if (_needsLanguagePromptAfterSplash) {
      setState(() => _phase = _Phase.languageSelect);
      return;
    }
    _enterApp();
  }

  void _completeLanguageSelect() {
    _service.markLanguagePromptSeen();
    _enterApp();
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _Phase.loading:
        return const Scaffold(body: DecoratedBox(decoration: BoxDecoration(gradient: AppGradients.brand)));
      case _Phase.intro:
        return IntroView(
          authRepository: widget.authRepository,
          profileRepository: widget.profileRepository,
          pushRepository: widget.pushRepository,
          onDone: _completeIntro,
        );
      case _Phase.languageSelect:
        return LanguageOnboardingPage(
          localeController: widget.localeController,
          onDone: _completeLanguageSelect,
        );
      case _Phase.staticSplash:
        return StaticSplashView(onDone: _completeStaticSplash);
      case _Phase.app:
        return widget.rootShellBuilder(context, _currentUserId);
    }
  }
}
