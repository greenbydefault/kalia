import 'package:flutter/material.dart';

/// Design-Tokens der App. Einzige Stelle für Font-Familien und Schriftgrößen.
///
/// Die ganze App nutzt [family]. Call-Sites rühren `fontFamily` nicht an;
/// `TextPainter` ohne Theme-Vererbung setzen [family] explizit.
///
/// Größen sind fest und gerade (2-px-Raster). Widgets wählen eine Rolle
/// (`bodyMedium`, `labelSmall`, …) und schreiben keine `fontSize`.
/// Ein Wert hier nachziehen verschiebt die ganze App.
abstract final class AppTypography {
  static const family = 'Hanken Grotesk';

  static const displayLarge = 56.0;
  static const displayMedium = 44.0;
  static const displaySmall = 36.0;
  static const headlineLarge = 32.0;
  static const headlineMedium = 28.0;
  static const headlineSmall = 24.0;
  static const titleLarge = 22.0;
  static const titleMedium = 18.0;
  static const titleSmall = 16.0;
  static const bodyLarge = 16.0;
  static const bodyMedium = 16.0;
  static const bodySmall = 14.0;
  static const labelLarge = 14.0;
  static const labelMedium = 12.0;
  static const labelSmall = 12.0;

  /// Material-3-Geometrie (`Typography` aus [ThemeData]) mit festen Größen,
  /// Letter-Spacing überall 0. Höhe und Gewicht bleiben an der Rolle.
  static TextTheme textTheme(TextTheme base) {
    TextStyle? style(TextStyle? s, double size) =>
        s?.copyWith(fontSize: size, letterSpacing: 0);

    return base.copyWith(
      displayLarge: style(base.displayLarge, displayLarge),
      displayMedium: style(base.displayMedium, displayMedium),
      displaySmall: style(base.displaySmall, displaySmall),
      headlineLarge: style(base.headlineLarge, headlineLarge),
      headlineMedium: style(base.headlineMedium, headlineMedium),
      headlineSmall: style(base.headlineSmall, headlineSmall),
      titleLarge: style(base.titleLarge, titleLarge),
      titleMedium: style(base.titleMedium, titleMedium),
      titleSmall: style(base.titleSmall, titleSmall),
      bodyLarge: style(base.bodyLarge, bodyLarge),
      bodyMedium: style(base.bodyMedium, bodyMedium),
      bodySmall: style(base.bodySmall, bodySmall),
      labelLarge: style(base.labelLarge, labelLarge),
      labelMedium: style(base.labelMedium, labelMedium),
      labelSmall: style(base.labelSmall, labelSmall),
    );
  }

  /// Chip-Label: Gewicht von `labelLarge`, Größe [labelSmall].
  /// Farben folgen den Material-Zuständen (aktiv, ausgewählt, deaktiviert).
  static TextStyle chipLabel(TextTheme base, ColorScheme scheme) {
    final label = base.labelLarge!;
    return label.copyWith(
      fontSize: labelSmall,
      letterSpacing: 0,
      color: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return scheme.onSurface;
        if (states.contains(WidgetState.selected)) {
          return scheme.onSecondaryContainer;
        }
        return scheme.onSurfaceVariant;
      }),
    );
  }
}
