import 'package:flutter/widgets.dart';

/// Respektiert „Bewegung reduzieren“ (`MediaQuery.disableAnimations`).
///
/// Dauer fällt auf ein paar Millisekunden, Endlosschleifen entfallen.
extension ReducedMotion on BuildContext {
  bool get reduceMotion => MediaQuery.maybeDisableAnimationsOf(this) ?? false;

  /// [d] normal, bei reduzierter Bewegung praktisch sofort.
  Duration motion(Duration d) =>
      reduceMotion ? const Duration(milliseconds: 10) : d;
}

/// Motion-Tokens des Onboardings (GSAP-Referenz in Flutter-Kurven).
abstract final class OnboardingMotion {
  static const Duration screen = Duration(milliseconds: 600);
  static const Curve screenCurve = Curves.easeInOutCubic;

  static const Duration sceneLayer = Duration(milliseconds: 700);
  static const Duration sceneStagger = Duration(milliseconds: 35);
  static const Duration sun = Duration(milliseconds: 900);
  static const Duration path = Duration(milliseconds: 1200);
  static const Duration textStagger = Duration(milliseconds: 80);

  static const Duration chipPop = Duration(milliseconds: 500);
  static const Duration chipStagger = Duration(milliseconds: 60);
  static const Duration countUp = Duration(milliseconds: 600);

  static const Duration pinFall = Duration(milliseconds: 1000);
  static const Duration pulse = Duration(milliseconds: 1800);

  static const Duration cardEnter = Duration(milliseconds: 700);
  static const Duration cardStagger = Duration(milliseconds: 100);
}
