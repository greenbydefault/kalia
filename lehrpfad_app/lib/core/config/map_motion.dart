import 'package:flutter/material.dart';

/// Zentrale Motion-Tokens für Karten-Kamera und Karten-Overlays.
///
/// Alle Karten-Instanzen (Übersichtskarte, Hero-Karte, künftige Karten)
/// beziehen Dauern und Kurven von hier, damit sich jedes Kamera- und
/// Fade-Verhalten an einer Stelle justieren lässt. Pendant zu
/// `SheetMotion` für Sheets/Cards.
abstract final class MapMotion {
  /// Langer Flug: Cluster-Expansion, Locate, Katalog-Fit, externe Einstiege.
  static const Duration fly = Duration(milliseconds: 1800);
  static const Curve flyCurve = Curves.easeInOutCubic;

  /// Einfittung: Tap auf der Übersichtskarte, Hero-Karte beim Foto/Karte-Toggle.
  static const Duration fit = Duration(milliseconds: 800);
  static const Curve fitCurve = Curves.easeOutCubic;

  /// Einblenden des ausgewählten Tracks auf der Übersichtskarte.
  static const Duration trackFade = Duration(milliseconds: 450);

  /// Fade+Scale beim Auftauchen von Cluster-/Trail-Markern.
  static const Duration markerAppear = Duration(milliseconds: 200);
}
