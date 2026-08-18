import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_theme.dart';
import 'semantic_colors.dart';

abstract final class AppTheme {
  static final ColorScheme _colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.buttonPrimary,
    onPrimary: AppColors.textInverse,
    primaryContainer: AppColors.surfaceSelected,
    onPrimaryContainer: AppColors.textOnLightBlue,
    secondary: AppColors.textSecondary,
    onSecondary: AppColors.textInverse,
    secondaryContainer: AppColors.surfaceSecondary,
    onSecondaryContainer: AppColors.textPrimary,
    tertiary: AppColors.textAccent,
    onTertiary: AppColors.textInverse,
    tertiaryContainer: AppColors.infoContainer,
    onTertiaryContainer: AppColors.onInfoContainer,
    error: AppColors.error,
    onError: AppColors.textInverse,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onErrorContainer,
    surface: AppColors.surfacePrimary,
    onSurface: AppColors.textPrimary,
    surfaceContainerHighest: AppColors.surfaceSecondary,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.borderDefault,
    outlineVariant: AppColors.divider,
    inverseSurface: AppColors.surfaceDark,
    onInverseSurface: AppColors.textInverse,
    inversePrimary: AppColors.textAccent,
    scrim: AppColors.surfaceOverlay,
  );

  static ThemeData get light {
    final textTheme = AppTextTheme.build(AppColors.textPrimary);

    return ThemeData(
      useMaterial3: true,
      colorScheme: _colorScheme,
      scaffoldBackgroundColor: AppColors.bgBase,
      textTheme: textTheme,
      extensions: const [SemanticColors.light],
      dividerColor: AppColors.divider,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgBase,
        foregroundColor: AppColors.textPrimary,
        // Pin surfaceTint off and elevation constant — M3 defaults tint the bar with
        // ColorScheme.primary once content scrolls under it, which read as a color change.
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        elevation: 2,
        scrolledUnderElevation: 2,
        titleTextStyle: textTheme.titleLarge,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.bgBase,
        surfaceTintColor: Colors.transparent,
        // No pill behind the selected icon — color alone signals the active tab.
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? AppColors.buttonPrimary : AppColors.textTertiary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected) ? AppColors.buttonPrimary : AppColors.textTertiary,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfacePrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.divider),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonPrimary,
          foregroundColor: AppColors.textInverse,
          disabledBackgroundColor: AppColors.buttonDisabled,
          disabledForegroundColor: AppColors.textDisabled,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed) ? AppColors.buttonPrimaryPressed : null,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.buttonSecondary,
          foregroundColor: AppColors.textPrimary,
          disabledBackgroundColor: AppColors.buttonDisabled,
          disabledForegroundColor: AppColors.textDisabled,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed) ? AppColors.buttonSecondaryPressed : null,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.buttonPrimary,
          disabledForegroundColor: AppColors.textDisabled,
          side: const BorderSide(color: AppColors.borderDefault),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.buttonPrimary,
          disabledForegroundColor: AppColors.textDisabled,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderFocused, width: 1.5),
        ),
        // Explicit, not left to InputDecorator's fallback default — TextField and
        // DropdownButtonFormField resolve a missing errorBorder differently, which made the
        // same errorText render a red outline on one and nothing on the other.
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textInverse),
        actionTextColor: AppColors.textAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

/// Destructive/ghost button styles — no dedicated Material widget for these.
abstract final class AppButtonStyles {
  static final destructive = ElevatedButton.styleFrom(
    backgroundColor: AppColors.buttonDestructive,
    foregroundColor: AppColors.textInverse,
    disabledBackgroundColor: AppColors.buttonDisabled,
    disabledForegroundColor: AppColors.textDisabled,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );

  static final ghost = TextButton.styleFrom(
    foregroundColor: AppColors.buttonPrimary,
    disabledForegroundColor: AppColors.textDisabled,
  );
}
