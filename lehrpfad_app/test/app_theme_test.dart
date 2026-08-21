import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/app/theme/app_theme.dart';
import 'package:lehrpfad_app/app/theme/app_typography.dart';

void main() {
  final theme = AppTheme.light();
  final text = theme.textTheme;

  test('Headlines nutzen League Gothic Regular', () {
    for (final style in [
      text.displayLarge,
      text.displayMedium,
      text.displaySmall,
      text.headlineLarge,
      text.headlineMedium,
      text.headlineSmall,
      text.titleLarge,
      text.titleMedium,
      text.titleSmall,
    ]) {
      expect(style?.fontFamily, AppTypography.headlineFamily);
      expect(style?.fontWeight, FontWeight.w400);
    }
  });

  test('Body und Labels bleiben ohne Headline-Font', () {
    for (final style in [
      text.bodyLarge,
      text.bodyMedium,
      text.bodySmall,
      text.labelLarge,
      text.labelMedium,
      text.labelSmall,
    ]) {
      expect(style?.fontFamily, isNot(AppTypography.headlineFamily));
    }
  });
}
