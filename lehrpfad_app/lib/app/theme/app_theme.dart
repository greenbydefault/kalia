import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Zentraler Theme-Aufbau. Ein Dark-Theme lässt sich später als
/// zweite Methode ergänzen, ohne die App-Shell anzufassen.
abstract final class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.brand,
      onPrimary: AppColors.n50,
      secondary: AppColors.n700,
      onSecondary: AppColors.n50,
      tertiary: AppColors.n600,
      onTertiary: AppColors.n50,
      error: AppColors.error,
      onError: AppColors.n50,
      surface: AppColors.n50,
      onSurface: AppColors.n950,
      surfaceContainerHighest: AppColors.n100,
      outline: AppColors.n400,
      outlineVariant: AppColors.n300,
      shadow: AppColors.n950,
      scrim: AppColors.n950,
    );

    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.paper,
      fontFamily: AppTypography.family,
    );

    return base.copyWith(
      textTheme: AppTypography.textTheme(base.textTheme),
      primaryTextTheme: AppTypography.textTheme(base.primaryTextTheme),
      chipTheme: base.chipTheme.copyWith(
        labelStyle: AppTypography.chipLabel(base.textTheme, scheme),
      ),
      navigationBarTheme: _navigationBarTheme(base.textTheme),
    );
  }

  /// Bottom-Nav ohne Indikator-Pill: aktiv = ink, inaktiv = n400.
  static NavigationBarThemeData _navigationBarTheme(TextTheme text) {
    Color farbe(Set<WidgetState> s) =>
        s.contains(WidgetState.selected) ? AppColors.ink : AppColors.n400;

    return NavigationBarThemeData(
      height: 69,
      backgroundColor: AppColors.paper,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: Colors.transparent,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: farbe(s), size: 24),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => text.labelMedium!.copyWith(
          fontSize: AppTypography.labelMedium,
          letterSpacing: 0,
          color: farbe(s),
          fontWeight: s.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w500,
        ),
      ),
    );
  }
}
