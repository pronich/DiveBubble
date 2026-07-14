import 'package:flutter/material.dart';

import '../../../../data/services/onboarding_state_service.dart';
import '../../../core/theme/app_gradients.dart';
import 'intro_view.dart';
import 'static_splash_view.dart';

enum _Phase { loading, intro, staticSplash, app }

/// Root gate: first-ever launch gets the animated bubble intro; returning users (already past
/// intro) get a quick static "B" splash instead, then either way land on [rootShellBuilder].
class AppEntryGate extends StatefulWidget {
  const AppEntryGate({super.key, required this.rootShellBuilder});

  final WidgetBuilder rootShellBuilder;

  @override
  State<AppEntryGate> createState() => _AppEntryGateState();
}

class _AppEntryGateState extends State<AppEntryGate> {
  final _service = OnboardingStateService();
  _Phase _phase = _Phase.loading;

  @override
  void initState() {
    super.initState();
    _service.hasCompletedIntro().then((completed) {
      if (!mounted) return;
      setState(() => _phase = completed ? _Phase.staticSplash : _Phase.intro);
    });
  }

  void _completeIntro() {
    _service.markIntroCompleted();
    setState(() => _phase = _Phase.app);
  }

  void _completeStaticSplash() {
    setState(() => _phase = _Phase.app);
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _Phase.loading:
        return const Scaffold(body: DecoratedBox(decoration: BoxDecoration(gradient: AppGradients.brand)));
      case _Phase.intro:
        return IntroView(onDone: _completeIntro);
      case _Phase.staticSplash:
        return StaticSplashView(onDone: _completeStaticSplash);
      case _Phase.app:
        return widget.rootShellBuilder(context);
    }
  }
}
