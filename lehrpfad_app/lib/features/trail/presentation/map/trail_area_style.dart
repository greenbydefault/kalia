import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// Stil für Flächen-Orte (Spiel-/Erlebnisplätze) auf der Karte.
abstract final class TrailAreaStyle {
  static const Color fill = AppColors.brand;
  static const Color border = AppColors.brand;

  static const double fillOpacityOverview = 0.18;
  static const double fillOpacitySelected = 0.35;
  static const double borderWidthOverview = 2.0;
  static const double borderWidthSelected = 3.0;
}
