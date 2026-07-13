import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Fraunces (warm, characterful serif) for display/headline moments —
/// splash, trip titles, empty states. Inter (clean, high x-height grotesk)
/// for everything else — dense lists, dates, chat — where legibility at
/// small sizes matters more than character.
abstract final class AppTextTheme {
  static TextTheme build(Color onSurface) {
    final base = GoogleFonts.interTextTheme();
    final display = GoogleFonts.frauncesTextTheme();

    return base.copyWith(
      displayLarge: display.displayLarge?.copyWith(color: onSurface, fontWeight: FontWeight.w600),
      displayMedium: display.displayMedium?.copyWith(color: onSurface, fontWeight: FontWeight.w600),
      displaySmall: display.displaySmall?.copyWith(color: onSurface, fontWeight: FontWeight.w600),
      headlineLarge: display.headlineLarge?.copyWith(color: onSurface, fontWeight: FontWeight.w600),
      headlineMedium: display.headlineMedium?.copyWith(color: onSurface, fontWeight: FontWeight.w600),
      headlineSmall: display.headlineSmall?.copyWith(color: onSurface, fontWeight: FontWeight.w600),
      titleLarge: base.titleLarge?.copyWith(color: onSurface, fontWeight: FontWeight.w600),
      titleMedium: base.titleMedium?.copyWith(color: onSurface, fontWeight: FontWeight.w600),
      titleSmall: base.titleSmall?.copyWith(color: onSurface, fontWeight: FontWeight.w600),
      bodyLarge: base.bodyLarge?.copyWith(color: onSurface),
      bodyMedium: base.bodyMedium?.copyWith(color: onSurface),
      bodySmall: base.bodySmall?.copyWith(color: onSurface),
      labelLarge: base.labelLarge?.copyWith(color: onSurface, fontWeight: FontWeight.w600),
      labelMedium: base.labelMedium?.copyWith(color: onSurface),
      labelSmall: base.labelSmall?.copyWith(color: onSurface),
    );
  }
}
