import 'package:flutter/material.dart';

/// Zentrale Motion-Tokens für Bottom-Cards und Trail-Sheet-Snaps.
abstract final class SheetMotion {
  static const Duration enter = Duration(milliseconds: 450);
  static const Duration exit = Duration(milliseconds: 280);
  static const Duration fade = Duration(milliseconds: 350);
  static const Duration size = Duration(milliseconds: 350);

  static const Curve enterCurve = Curves.easeOutCubic;
  static const Curve exitCurve = Curves.easeInCubic;
  static const Curve fadeCurve = Curves.easeOut;

  static AnimationStyle get sheetAnimationStyle => AnimationStyle(
    duration: enter,
    curve: enterCurve,
    reverseDuration: exit,
    reverseCurve: exitCurve,
  );
}
