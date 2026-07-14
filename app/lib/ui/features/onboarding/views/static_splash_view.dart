import 'package:flutter/material.dart';

import '../../../core/branding/bubble_logo_painter.dart';
import '../../../core/branding/logo_layout.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';

/// Fast, static "B" splash for returning users who've already seen the animated intro —
/// just a branded loading beat before entering the app, no bubbles rising.
class StaticSplashView extends StatefulWidget {
  const StaticSplashView({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<StaticSplashView> createState() => _StaticSplashViewState();
}

class _StaticSplashViewState extends State<StaticSplashView> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.brand),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final box = fitLogoBox(constraints.biggest);
            return CustomPaint(
              size: constraints.biggest,
              painter: BubbleLogoPainter(
                bubbles: restingBubbles(box),
                box: box,
                highlightOpacity: 1,
                highlightColor: AppColors.info,
              ),
            );
          },
        ),
      ),
    );
  }
}
