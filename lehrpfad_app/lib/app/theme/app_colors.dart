import 'package:flutter/material.dart';

/// Design-Tokens der App. Einzige Stelle für Farbwerte.
///
/// Neutral-Skala (n50–n950) speist Theme und UI. Brand-Aliases zeigen
/// vorerst auf Neutrals; später hier einfärben, Call-Sites bleiben.
abstract final class AppColors {
  // ── Neutral-Skala (härtere Stufen für Lesbarkeit) ─────────────────
  static const n50 = Color(0xFFFAFAFA);
  static const n100 = Color(0xFFF0F0F0);
  static const n200 = Color(0xFFE2E2E2);
  static const n300 = Color(0xFFC8C8C8);
  static const n400 = Color(0xFF9E9E9E);
  static const n500 = Color(0xFF6B6B6B);
  static const n600 = Color(0xFF4A4A4A);
  static const n700 = Color(0xFF333333);
  static const n800 = Color(0xFF1F1F1F);
  static const n900 = Color(0xFF141414);
  static const n950 = Color(0xFF0A0A0A);

  // ── Semantik (später Brand einfärben: brand / brandDark) ──────────
  static const brand = n900;
  static const brandDark = n950;
  static const ink = n950;
  static const inkMuted = n600;
  static const paper = n50;
  static const hairline = n300;

  /// Einzige Nicht-Neutral-Farbe: Fehlertexte lesbar halten.
  static const error = Color(0xFFB3261E);

  /// Pin-Ring für Trails mit `eintritt: true`. Nicht Eignungs-Gelb.
  static const eintrittRing = Color(0xFFC9A227);

  // ── Eignungs-Spektrum (Signal-Balken, Level 1→5, L→R rot→grün) ──
  static const eignung1 = Color(0xFFC62828);
  static const eignung2 = Color(0xFFEF6C00);
  static const eignung3 = Color(0xFFF9A825);
  static const eignung4 = Color(0xFF7CB342);
  static const eignung5 = Color(0xFF2E7D32);

  static const eignungSpectrum = <Color>[
    eignung1,
    eignung2,
    eignung3,
    eignung4,
    eignung5,
  ];

  // ── Opacity-Helfer (Scrims / Text auf Bildern) ────────────────────
  static const scrim26 = Color(0x420A0A0A); // n950 @ 26%
  static const scrim38 = Color(0x610A0A0A); // n950 @ 38%
  static const scrim54 = Color(0x8A0A0A0A); // n950 @ 54%
  static const onImage54 = Color(0x8AFAFAFA); // n50 @ 54%
  static const onImage70 = Color(0xB3FAFAFA); // n50 @ 70%
}
