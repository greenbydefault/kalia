import 'package:flutter/material.dart';

/// Design-Tokens der App. Einzige Stelle für Font-Familien und Schriftgrößen.
///
/// Die ganze App nutzt [family]. Call-Sites rühren `fontFamily` nicht an;
/// `TextPainter` ohne Theme-Vererbung setzen [family] explizit.
///
/// Größen laufen über zwei Hebel auf den Material-3-Stufen:
/// - [bodyBoost] für alle Beschreibungs- und Fließtexte (`body*`)
/// - [chipBoost] für Chips und kleine Tags (`labelSmall`, Chip-Label)
///
/// Widgets wählen eine Rolle (`bodyMedium`, `labelSmall`, …) und schreiben
/// keine `fontSize`. Ein Wert hier nachziehen verschiebt die ganze App.
abstract final class AppTypography {
  static const family = 'Hanken Grotesk';

  /// Aufschlag in px auf `bodyLarge`, `bodyMedium`, `bodySmall`.
  static const double bodyBoost = 4;

  /// Aufschlag in px auf Chip-Label und `labelSmall` (Tags, Badges).
  static const double chipBoost = 2;

  /// Material-3-Geometrie (`Typography.englishLike2021`) plus Hebel,
  /// Letter-Spacing überall 0.
  ///
  /// `ThemeData.textTheme` trägt vor der Lokalisierung durch `MaterialApp`
  /// noch keine Größen, deshalb kommen sie hier aus der Geometrie.
  static TextTheme textTheme(TextTheme base) {
    const geo = Typography.englishLike2021;

    TextStyle? style(TextStyle? s, TextStyle? g, [double boost = 0]) =>
        s?.copyWith(
          fontSize: (s.fontSize ?? g?.fontSize ?? 14) + boost,
          letterSpacing: 0,
        );

    return base.copyWith(
      displayLarge: style(base.displayLarge, geo.displayLarge),
      displayMedium: style(base.displayMedium, geo.displayMedium),
      displaySmall: style(base.displaySmall, geo.displaySmall),
      headlineLarge: style(base.headlineLarge, geo.headlineLarge),
      headlineMedium: style(base.headlineMedium, geo.headlineMedium),
      headlineSmall: style(base.headlineSmall, geo.headlineSmall),
      titleLarge: style(base.titleLarge, geo.titleLarge),
      titleMedium: style(base.titleMedium, geo.titleMedium),
      titleSmall: style(base.titleSmall, geo.titleSmall),
      bodyLarge: style(base.bodyLarge, geo.bodyLarge, bodyBoost),
      bodyMedium: style(base.bodyMedium, geo.bodyMedium, bodyBoost),
      bodySmall: style(base.bodySmall, geo.bodySmall, bodyBoost),
      labelLarge: style(base.labelLarge, geo.labelLarge),
      labelMedium: style(base.labelMedium, geo.labelMedium),
      labelSmall: style(base.labelSmall, geo.labelSmall, chipBoost),
    );
  }

  /// Chip-Label: `labelLarge` der Basis plus [chipBoost]. Farben folgen den
  /// Material-Zuständen (aktiv, ausgewählt, deaktiviert).
  static TextStyle chipLabel(TextTheme base, ColorScheme scheme) {
    final label = base.labelLarge!;
    return label.copyWith(
      fontSize:
          (label.fontSize ?? Typography.englishLike2021.labelLarge!.fontSize!) +
          chipBoost,
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
