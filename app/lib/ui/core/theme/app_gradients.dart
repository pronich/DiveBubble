import 'package:flutter/material.dart';

/// Gradients from the Figma "Colors" page (Gradient swatch group).
abstract final class AppGradients {
  /// Hero/splash gradient.
  static const brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF061F4A),
      Color(0xFF0B3D91),
      Color(0xFF1479D1),
    ],
    stops: [0.0, 0.6, 1.0],
  );

  /// Smaller CTA banners/cards.
  static const compact = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0B3D91),
      Color(0xFF1479D1),
    ],
  );

  /// Scrim over trip/photo imagery so overlaid text stays legible.
  static const imageScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x00061F4A), // rgba(6,31,74,0) at 20%
      Color(0xE1061F4A), // rgba(6,31,74,0.88) at 100%
    ],
    stops: [0.2, 1.0],
  );
}
