import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Deliberately minimal (Material 3 seed-color generation, not a hand-built ColorScheme like app/'s AppTheme) since admin/ is functional-first — but fonts still match app/'s (Fraunces/Inter) since mismatched type next to the same brand mark looked visibly off.
abstract final class AdminTheme {
  static final light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B3D91)),
    textTheme: _textTheme,
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
  );

  static final TextTheme _textTheme = () {
    final base = GoogleFonts.interTextTheme();
    final display = GoogleFonts.frauncesTextTheme();
    return base.copyWith(
      displayLarge: display.displayLarge?.copyWith(fontWeight: FontWeight.w600),
      displayMedium: display.displayMedium?.copyWith(fontWeight: FontWeight.w600),
      displaySmall: display.displaySmall?.copyWith(fontWeight: FontWeight.w600),
      headlineLarge: display.headlineLarge?.copyWith(fontWeight: FontWeight.w600),
      headlineMedium: display.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
      headlineSmall: display.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
    );
  }();
}
