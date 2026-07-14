import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../core/branding/bubble_logo_painter.dart';
import '../../../core/branding/logo_bubbles.dart';
import '../../../core/branding/logo_layout.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import 'login_sheet.dart';

/// Animated first-run intro: bubbles rise from the bottom of the screen and assemble into the
/// brand "B" mark, then the title/description/CTA fade in underneath. Tap anywhere to skip ahead.
class IntroView extends StatefulWidget {
  const IntroView({
    super.key,
    required this.authRepository,
    required this.profileRepository,
    required this.onDone,
  });

  final AuthRepository authRepository;
  final ProfileRepository profileRepository;

  /// Called once the user picks Dive in (after login) or Skip — either way, onboarding is over.
  final VoidCallback onDone;

  @override
  State<IntroView> createState() => _IntroViewState();
}

class _IntroViewState extends State<IntroView> with TickerProviderStateMixin {
  late final AnimationController _bubbleController;
  late final AnimationController _contentController;
  late final List<_TargetBubbleParams> _targets;
  late final List<_DecoBubbleParams> _decos;

  @override
  void initState() {
    super.initState();
    _bubbleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
    _contentController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _bubbleController.addStatusListener((status) {
      if (status == AnimationStatus.completed) _contentController.forward();
    });

    final rnd = math.Random();
    _targets = [for (final _ in kLogoBubbles) _TargetBubbleParams.random(rnd)];
    _decos = List.generate(22, (_) => _DecoBubbleParams.random(rnd));

    _bubbleController.forward();
  }

  @override
  void dispose() {
    _bubbleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _skipToEnd() {
    if (_bubbleController.isCompleted) return;
    _bubbleController.animateTo(1, duration: const Duration(milliseconds: 150));
  }

  Future<void> _diveIn(BuildContext context) async {
    final signedIn = await LoginSheet.show(
      context,
      authRepository: widget.authRepository,
      profileRepository: widget.profileRepository,
    );
    if (signedIn) widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _skipToEnd,
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppGradients.brand),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              final box = fitLogoBox(size);

              return Stack(
                children: [
                  AnimatedBuilder(
                    animation: _bubbleController,
                    builder: (context, _) {
                      final t = _bubbleController.value;
                      final bubbles = <RenderedBubble>[
                        for (final target in _targets.asMap().entries)
                          target.value.resolve(t, box, kLogoBubbles[target.key]),
                        for (final deco in _decos) deco.resolve(t, size),
                      ];
                      final highlightOpacity = ((t - 0.85) / 0.15).clamp(0.0, 1.0);
                      return CustomPaint(
                        size: size,
                        painter: BubbleLogoPainter(
                          bubbles: bubbles,
                          box: box,
                          highlightOpacity: highlightOpacity,
                          highlightColor: AppColors.info,
                        ),
                      );
                    },
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    top: box.bottom + 28,
                    child: FadeTransition(
                      opacity: _contentController,
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
                          CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
                        ),
                        child: _IntroContent(
                          onDiveIn: () => _diveIn(context),
                          onSkip: widget.onDone,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _IntroContent extends StatelessWidget {
  const _IntroContent({required this.onDiveIn, required this.onSkip});

  final VoidCallback onDiveIn;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // White/inverted styling — this content sits on the dark AppGradients.brand backdrop,
    // not the usual light bgBase, so the app-wide dark-on-light text/button theme reads illegibly here.
    return Column(
      children: [
        Text(
          'DiveBubble',
          style: theme.textTheme.headlineLarge?.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Find dive trips, meet your buddies, and plan the logistics together.',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.85),
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onDiveIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.buttonPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            child: const Text('Dive in'),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onSkip,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            textStyle: theme.textTheme.bodyLarge,
          ),
          child: const Text('Skip for now'),
        ),
      ],
    );
  }
}

/// Random per-bubble motion parameters for one of the 24 bubbles that form the logo mark.
/// Resolved into a screen position each frame via [resolve].
class _TargetBubbleParams {
  _TargetBubbleParams({
    required this.tStart,
    required this.assembleDuration,
    required this.swayAmp,
    required this.swayPhase,
    required this.startXJitter,
    required this.startYOffset,
    required this.startRadiusFactor,
  });

  factory _TargetBubbleParams.random(math.Random rnd) => _TargetBubbleParams(
    // Stay part of the rising wall for a while before peeling off — long enough that
    // assembly doesn't read as an abrupt "collapse" into the letter.
    tStart: 0.30 + rnd.nextDouble() * 0.25,
    assembleDuration: 0.35,
    swayAmp: 8 + rnd.nextDouble() * 16,
    swayPhase: rnd.nextDouble() * 2 * math.pi,
    startXJitter: (rnd.nextDouble() - 0.5) * 90,
    startYOffset: 60 + rnd.nextDouble() * 140,
    startRadiusFactor: 0.5 + rnd.nextDouble() * 0.3,
  );

  final double tStart;
  final double assembleDuration;
  final double swayAmp;
  final double swayPhase;
  final double startXJitter;
  final double startYOffset;
  final double startRadiusFactor;

  RenderedBubble resolve(double t, Rect box, LogoBubble target) {
    final targetX = box.left + target.cx * box.width;
    final targetY = box.top + target.cy * box.height;
    final targetR = target.r * box.width;
    final startX = targetX + startXJitter;
    final startY = targetY + box.height + startYOffset;
    final startR = targetR * startRadiusFactor;

    final tEnd = math.min(1.0, tStart + assembleDuration);
    final riseLocal = (t / tStart).clamp(0.0, 1.0);
    final riseEase = Curves.easeOut.transform(riseLocal);
    final y = _lerp(startY, targetY, riseEase);
    final x = startX + math.sin(riseLocal * 2 * math.pi + swayPhase) * swayAmp * riseLocal;
    final opacity = riseLocal < 0.15 ? riseLocal / 0.15 : 1.0;

    if (t <= tStart) {
      return RenderedBubble(center: Offset(x, y), radius: startR, opacity: opacity);
    }

    final assembleLocal = ((t - tStart) / (tEnd - tStart)).clamp(0.0, 1.0);
    final assembleEase = Curves.easeInOutCubic.transform(assembleLocal);
    final assembledX = _lerp(x, targetX, assembleEase);
    final assembledR = _lerp(startR, targetR, assembleEase);
    return RenderedBubble(center: Offset(assembledX, targetY), radius: assembledR, opacity: 1);
  }
}

/// Random per-bubble motion parameters for the extra decorative bubbles that just rise and fade —
/// atmosphere only, they never form part of the logo.
class _DecoBubbleParams {
  _DecoBubbleParams({
    required this.startXFraction,
    required this.startYOffset,
    required this.extraAboveTop,
    required this.swayAmp,
    required this.swayPhase,
    required this.radius,
  });

  factory _DecoBubbleParams.random(math.Random rnd) => _DecoBubbleParams(
    startXFraction: rnd.nextDouble(),
    startYOffset: 20 + rnd.nextDouble() * 200,
    // How far above the screen's top edge this bubble ends up at t=1 — independent of
    // screen height so it scales correctly across device sizes (see resolve()).
    extraAboveTop: 150 + rnd.nextDouble() * 250,
    swayAmp: 6 + rnd.nextDouble() * 14,
    swayPhase: rnd.nextDouble() * 2 * math.pi,
    radius: 3 + rnd.nextDouble() * 7,
  );

  final double startXFraction;
  final double startYOffset;
  final double extraAboveTop;
  final double swayAmp;
  final double swayPhase;
  final double radius;

  RenderedBubble resolve(double t, Size size) {
    final startX = startXFraction * size.width;
    final startY = size.height + startYOffset;
    final riseDistance = startY + extraAboveTop;
    final y = _lerp(startY, startY - riseDistance, t);
    final x = startX + math.sin(t * 2 * math.pi + swayPhase) * swayAmp * t;
    double opacity;
    if (t < 0.12) {
      opacity = t / 0.12;
    } else if (t > 0.72) {
      opacity = (1 - (t - 0.72) / 0.28).clamp(0.0, 1.0);
    } else {
      opacity = 1;
    }
    return RenderedBubble(center: Offset(x, y), radius: radius, opacity: opacity);
  }
}

double _lerp(double a, double b, double t) => a + (b - a) * t;
