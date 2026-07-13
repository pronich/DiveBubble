import 'package:flutter/material.dart';

/// Design tokens from Figma (jgNXK7udS3SrZJkqjcmwss, node 1:191) — source of truth for app_theme.dart's ColorScheme.
abstract final class AppColors {
  // Backgrounds / surfaces
  static const bgBase = Color(0xFFF4F7FC);
  static const surfacePrimary = Color(0xFFFFFFFF);
  static const surfaceSecondary = Color(0xFFE8EFF8);
  static const surfaceSelected = Color(0xFFD8E5F7);
  static const surfaceElevated = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF061F4A);
  static const surfaceOverlay = Color(0x8F061F4A); // rgba(6,31,74,0.56)
  static const divider = Color(0xFFDCE4EF);
  static const borderDefault = Color(0xFFCCD8E8);
  static const borderFocused = Color(0xFF1479D1);

  // Buttons
  static const buttonPrimary = Color(0xFF0B3D91);
  static const buttonPrimaryPressed = Color(0xFF082E6D);
  static const buttonSecondary = Color(0xFFD8E5F7);
  static const buttonSecondaryPressed = Color(0xFFC3D7F1);
  static const buttonDestructive = Color(0xFFBA3344);
  static const buttonDisabled = Color(0xFFD9E1EC);

  // Text
  static const textPrimary = Color(0xFF0C1F3F);
  static const textSecondary = Color(0xFF536985);
  static const textTertiary = Color(0xFF657991);
  static const textDisabled = Color(0xFF8292A8);
  static const textLink = Color(0xFF0B3D91);
  static const textAccent = Color(0xFF1479D1);
  static const textInverse = Color(0xFFFFFFFF);
  static const textOnLightBlue = Color(0xFF082E6D);
  static const textDestructive = Color(0xFFBA3344);

  // Semantic — success
  static const success = Color(0xFF1F7A63);
  static const successContainer = Color(0xFFDDF2EA);
  static const onSuccessContainer = Color(0xFF155342);

  // Semantic — warning
  static const warning = Color(0xFFB8660F);
  static const warningContainer = Color(0xFFFFF0DB);
  static const onWarningContainer = Color(0xFF6A3600);

  // Semantic — error
  static const error = Color(0xFFBA3344);
  static const errorContainer = Color(0xFFFBE4E7);
  static const onErrorContainer = Color(0xFF76202B);

  // Semantic — info
  static const info = Color(0xFF1479D1);
  static const infoContainer = Color(0xFFD9EDFC);
  static const onInfoContainer = Color(0xFF084B84);

  // Semantic — neutral
  static const neutral = Color(0xFF536985);
  static const neutralContainer = Color(0xFFE8EFF8);
  static const onNeutralContainer = Color(0xFF334B68);
}
