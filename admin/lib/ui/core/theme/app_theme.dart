import 'package:flutter/material.dart';

/// Deliberately minimal — a business back-office tool gets far less design investment
/// than the consumer app (see CLAUDE.md's Business/dive centers section: mobile app/ is
/// the polished consumer surface, admin/ is functional-first). Just enough brand
/// consistency (the same primary blue app/ uses) via Material 3's seed-color generation,
/// not a hand-built ColorScheme like app/'s AppTheme.
abstract final class AdminTheme {
  static final light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B3D91)),
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
  );
}
