import 'package:flutter/material.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/services/onboarding_state_service.dart';
import '../../../core/theme/app_gradients.dart';
import 'intro_view.dart';
import 'static_splash_view.dart';

enum _Phase { loading, intro, staticSplash, app }

/// Root gate: first-ever launch gets the animated bubble intro; returning users (already past
/// intro) get a quick static "B" splash instead, then either way land on [rootShellBuilder].
class AppEntryGate extends StatefulWidget {
  const AppEntryGate({super.key, required this.authRepository, required this.rootShellBuilder});

  final AuthRepository authRepository;

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
  }

  Future<void> _enterApp() async {
    final userId = await widget.authRepository.currentUserId() ?? '';
    if (!mounted) return;
    setState(() {
      _currentUserId = userId;
      _phase = _Phase.app;
    });
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
        return IntroView(authRepository: widget.authRepository, onDone: _completeIntro);
      case _Phase.staticSplash:
        return StaticSplashView(onDone: _completeStaticSplash);
      case _Phase.app:
        return widget.rootShellBuilder(context, _currentUserId);
    }
  }
}
