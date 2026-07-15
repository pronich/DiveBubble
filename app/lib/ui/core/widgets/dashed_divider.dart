import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Oceanic-style section separator — a horizontal dashed rule in the brand color,
/// used to break Profile into Overview/Certifications/Gear sections without tabs.
class DashedDivider extends StatelessWidget {
  const DashedDivider({super.key, this.color = AppColors.buttonPrimary, this.thickness = 1});

  final Color color;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: thickness,
      child: CustomPaint(painter: _DashedLinePainter(color: color, thickness: thickness), size: Size.infinite),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color, required this.thickness});

  final Color color;
  final double thickness;

  static const _dashWidth = 5.0;
  static const _dashGap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness;

    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, size.height / 2), Offset(x + _dashWidth, size.height / 2), paint);
      x += _dashWidth + _dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.thickness != thickness;
}
