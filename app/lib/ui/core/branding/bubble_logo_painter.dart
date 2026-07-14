import 'package:flutter/material.dart';

import 'logo_bubbles.dart';

/// One bubble's resolved on-screen state for a single animation frame.
class RenderedBubble {
  const RenderedBubble({required this.center, required this.radius, required this.opacity});

  final Offset center;
  final double radius;
  final double opacity;
}

/// Draws a set of white circles plus the two brand highlight arcs, scaled/positioned into [box].
/// Used both for the animated intro (per-frame bubble positions) and the static "B" splash (bubbles at rest).
class BubbleLogoPainter extends CustomPainter {
  BubbleLogoPainter({
    required this.bubbles,
    required this.box,
    required this.highlightOpacity,
    required this.highlightColor,
  });

  final List<RenderedBubble> bubbles;
  final Rect box;
  final double highlightOpacity;
  final Color highlightColor;

  static final List<Path> _highlightPaths = kLogoHighlightPaths.map(_parseSimpleSvgPath).toList();

  @override
  void paint(Canvas canvas, Size size) {
    final bubblePaint = Paint()..style = PaintingStyle.fill;
    for (final b in bubbles) {
      if (b.opacity <= 0 || b.radius <= 0) continue;
      bubblePaint.color = Colors.white.withValues(alpha: b.opacity);
      canvas.drawCircle(b.center, b.radius, bubblePaint);
    }

    if (highlightOpacity > 0) {
      final scale = box.width / 1024;
      canvas.save();
      canvas.translate(box.left, box.top);
      canvas.scale(scale);
      final highlightPaint = Paint()
        ..color = highlightColor.withValues(alpha: highlightOpacity)
        ..style = PaintingStyle.fill;
      for (final path in _highlightPaths) {
        canvas.drawPath(path, highlightPaint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant BubbleLogoPainter oldDelegate) =>
      oldDelegate.bubbles != bubbles ||
      oldDelegate.box != box ||
      oldDelegate.highlightOpacity != highlightOpacity;
}

/// Minimal absolute-only SVG path parser — the brand highlight paths use just M/C/Z, so a full
/// SVG path grammar (relative commands, L/Q/A, shorthand) isn't needed.
Path _parseSimpleSvgPath(String d) {
  final path = Path();
  var i = 0;
  final tokens = <String>[
    for (final m in RegExp(r'[A-Za-z]|-?\d*\.?\d+').allMatches(d)) m.group(0)!,
  ];
  double nextNum() => double.parse(tokens[i++]);

  while (i < tokens.length) {
    final cmd = tokens[i++];
    switch (cmd) {
      case 'M':
        path.moveTo(nextNum(), nextNum());
        break;
      case 'C':
        path.cubicTo(nextNum(), nextNum(), nextNum(), nextNum(), nextNum(), nextNum());
        break;
      case 'Z':
        path.close();
        break;
      default:
        // Unexpected token for this restricted parser — stop rather than mis-render.
        return path;
    }
  }
  return path;
}
