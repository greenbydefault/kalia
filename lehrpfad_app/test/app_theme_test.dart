import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/app/theme/app_theme.dart';
import 'package:lehrpfad_app/app/theme/app_typography.dart';

void main() {
  final theme = AppTheme.light();
  final text = theme.textTheme;
  // Material-3-Geometrie, auf der die Hebel aufsetzen.
  const base = Typography.englishLike2021;

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

  test('Body-Stufen wachsen um bodyBoost', () {
    expect(
      text.bodyLarge?.fontSize,
      base.bodyLarge!.fontSize! + AppTypography.bodyBoost,
    );
    expect(
      text.bodyMedium?.fontSize,
      base.bodyMedium!.fontSize! + AppTypography.bodyBoost,
    );
    expect(
      text.bodySmall?.fontSize,
      base.bodySmall!.fontSize! + AppTypography.bodyBoost,
    );
  });

  test('Tags und Chip-Label wachsen um chipBoost', () {
    expect(
      text.labelSmall?.fontSize,
      base.labelSmall!.fontSize! + AppTypography.chipBoost,
    );
    expect(
      theme.chipTheme.labelStyle?.fontSize,
      base.labelLarge!.fontSize! + AppTypography.chipBoost,
    );
  });

  test('Titel-, Headline-, Display- und Label-Stufen bleiben', () {
    expect(text.titleLarge?.fontSize, base.titleLarge!.fontSize);
    expect(text.titleMedium?.fontSize, base.titleMedium!.fontSize);
    expect(text.headlineSmall?.fontSize, base.headlineSmall!.fontSize);
    expect(text.displayLarge?.fontSize, base.displayLarge!.fontSize);
    expect(text.labelLarge?.fontSize, base.labelLarge!.fontSize);
    expect(text.labelMedium?.fontSize, base.labelMedium!.fontSize);
  });
}
