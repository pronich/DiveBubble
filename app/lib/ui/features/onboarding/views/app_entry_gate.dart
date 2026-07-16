import 'package:flutter/material.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/services/onboarding_state_service.dart';
import '../../../core/theme/app_gradients.dart';
import 'intro_view.dart';
import 'static_splash_view.dart';

enum _Phase { loading, intro, staticSplash, app }

/// Root gate: first-ever launch gets the animated bubble intro; returning users (already past
/// intro) get a quick static "B" splash instead, then either way land on [rootShellBuilder].
class AppEntryGate extends StatefulWidget {
  const AppEntryGate({
    super.key,
    required this.authRepository,
    required this.profileRepository,
    required this.rootShellBuilder,
  });

  final AuthRepository authRepository;
  final ProfileRepository profileRepository;

  /// currentUserId is the real signed-in user's id if logged in, or '' for an anonymous/browsing
  /// session — resolved fresh right before entering the app, not fixed at app startup, since
  /// sign-in can happen during the intro flow itself.
  final Widget Function(BuildContext, String currentUserId) rootShellBuilder;

  @override
  State<AppEntryGate> createState() => _AppEntryGateState();
}

class _AppEntryGateState extends State<AppEntryGate> {
  final _service = OnboardingStateService();
  _Phase _phase = _Phase.loading;
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _service.hasCompletedIntro().then((completed) {
      if (!mounted) return;
      setState(() => _phase = completed ? _Phase.staticSplash : _Phase.intro);
    });
    // A login-gated action (ensureSignedIn) can sign the user in — or a session refresh can
    // fail and sign them out — long after _enterApp() already ran once. Without this,
    // _currentUserId stayed frozen at whatever it was resolved to on that first transition
    // (e.g. '' for a browsing-then-later-signed-in session), and every isMine/currentUserId
    // comparison downstream (chat bubbles, unread counts) would compare against the wrong id
    // for the rest of the app's process lifetime.
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
    _enterApp();
  }

  void _completeStaticSplash() {
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
          onDone: _completeIntro,
        );
      case _Phase.staticSplash:
        return StaticSplashView(onDone: _completeStaticSplash);
      case _Phase.app:
        return widget.rootShellBuilder(context, _currentUserId);
    }
  }
}
