import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'bubble_logo_painter.dart';
import 'logo_bubbles.dart';

/// Square box the logo bubbles are laid out inside, centered in the upper-middle of the screen.
Rect fitLogoBox(Size screenSize) {
  final side = math.min(screenSize.width * 0.55, 220.0);
  final center = Offset(screenSize.width / 2, screenSize.height * 0.30);
  return Rect.fromCenter(center: center, width: side, height: side);
}

/// The logo bubbles fully assembled and opaque — the "at rest" state, used by the static splash
/// and as the animated intro's final frame.
List<RenderedBubble> restingBubbles(Rect box) {
  return kLogoBubbles
      .map(
        (b) => RenderedBubble(
          center: Offset(box.left + b.cx * box.width, box.top + b.cy * box.height),
          radius: b.r * box.width,
          opacity: 1,
        ),
      )
      .toList();
}
