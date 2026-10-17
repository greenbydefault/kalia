import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/app/theme/app_theme.dart';
import 'package:lehrpfad_app/app/theme/app_typography.dart';

void main() {
  final theme = AppTheme.light();
  final text = theme.textTheme;

  final all = {
    'displayLarge': text.displayLarge,
    'displayMedium': text.displayMedium,
    'displaySmall': text.displaySmall,
    'headlineLarge': text.headlineLarge,
    'headlineMedium': text.headlineMedium,
    'headlineSmall': text.headlineSmall,
    'titleLarge': text.titleLarge,
    'titleMedium': text.titleMedium,
    'titleSmall': text.titleSmall,
    'bodyLarge': text.bodyLarge,
    'bodyMedium': text.bodyMedium,
    'bodySmall': text.bodySmall,
    'labelLarge': text.labelLarge,
    'labelMedium': text.labelMedium,
    'labelSmall': text.labelSmall,
  };

  const sizes = {
    'displayLarge': AppTypography.displayLarge,
    'displayMedium': AppTypography.displayMedium,
    'displaySmall': AppTypography.displaySmall,
    'headlineLarge': AppTypography.headlineLarge,
    'headlineMedium': AppTypography.headlineMedium,
    'headlineSmall': AppTypography.headlineSmall,
    'titleLarge': AppTypography.titleLarge,
    'titleMedium': AppTypography.titleMedium,
    'titleSmall': AppTypography.titleSmall,
    'bodyLarge': AppTypography.bodyLarge,
    'bodyMedium': AppTypography.bodyMedium,
    'bodySmall': AppTypography.bodySmall,
    'labelLarge': AppTypography.labelLarge,
    'labelMedium': AppTypography.labelMedium,
    'labelSmall': AppTypography.labelSmall,
  };

  test('Alle Text-Styles nutzen Hanken Grotesk', () {
    expect(AppTypography.family, 'Hanken Grotesk');
    expect(theme.textTheme.bodyMedium?.fontFamily, AppTypography.family);
    for (final style in all.values) {
      expect(style?.fontFamily, AppTypography.family);
    }
  });

  test('Letter-Spacing ist überall 0', () {
    for (final e in all.entries) {
      expect(e.value?.letterSpacing, 0, reason: e.key);
    }
    expect(theme.primaryTextTheme.bodyMedium?.letterSpacing, 0);
    expect(theme.chipTheme.labelStyle?.letterSpacing, 0);
  });

  test('Schriftgrößen liegen fest auf dem 2-px-Raster', () {
    for (final e in sizes.entries) {
      final size = all[e.key]?.fontSize;
      expect(size, e.value, reason: e.key);
      expect(size! % 2, 0, reason: e.key);
    }
    expect(theme.chipTheme.labelStyle?.fontSize, AppTypography.labelSmall);
    expect(theme.primaryTextTheme.bodyMedium?.fontSize, AppTypography.bodyMedium);
  });
}
