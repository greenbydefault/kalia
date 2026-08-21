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

    final theme = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.paper,
    );
    return theme.copyWith(
      textTheme: AppTypography.applyHeadlines(theme.textTheme),
    );
  }
}
