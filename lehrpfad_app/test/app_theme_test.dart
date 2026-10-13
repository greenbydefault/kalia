import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/app/theme/app_theme.dart';
import 'package:lehrpfad_app/app/theme/app_typography.dart';

void main() {
  final theme = AppTheme.light();
  final text = theme.textTheme;

  test('Alle Text-Styles nutzen Hanken Grotesk', () {
    expect(AppTypography.family, 'Hanken Grotesk');
    expect(theme.textTheme.bodyMedium?.fontFamily, AppTypography.family);
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
      text.bodyLarge,
      text.bodyMedium,
      text.bodySmall,
      text.labelLarge,
      text.labelMedium,
      text.labelSmall,
    ]) {
      expect(style?.fontFamily, AppTypography.family);
    }
  });
}
