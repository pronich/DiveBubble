import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Deliberately minimal — a business back-office tool gets far less design investment
/// than the consumer app (see CLAUDE.md's Business/dive centers section: mobile app/ is
/// the polished consumer surface, admin/ is functional-first). Just enough brand
/// consistency (the same primary blue app/ uses) via Material 3's seed-color generation,
/// not a hand-built ColorScheme like app/'s AppTheme — but the *fonts* should still match
/// app/'s (Fraunces for headline/display, Inter for the rest — see app/'s own
/// AppTextTheme), since page headers sitting right next to the same brand mark looked
/// visibly off otherwise.
abstract final class AdminTheme {
  static final light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B3D91)),
    textTheme: _textTheme,
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
  );

  // TEMP DIAGNOSTIC: skip google_fonts' dynamic font loading entirely, to test whether
  // Flutter's first frame is stuck waiting on it in production.
  static final TextTheme _textTheme = const TextTheme();
  // static final TextTheme _textTheme = () {
  //   final base = GoogleFonts.interTextTheme();
  //   final display = GoogleFonts.frauncesTextTheme();
  //   return base.copyWith(
  //     displayLarge: display.displayLarge?.copyWith(fontWeight: FontWeight.w600),
  //     displayMedium: display.displayMedium?.copyWith(fontWeight: FontWeight.w600),
  //     displaySmall: display.displaySmall?.copyWith(fontWeight: FontWeight.w600),
  //     headlineLarge: display.headlineLarge?.copyWith(fontWeight: FontWeight.w600),
  //     headlineMedium: display.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
  //     headlineSmall: display.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
  //   );
  // }();
}
