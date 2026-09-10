import 'package:flutter/widgets.dart';

/// Gedämpfte Fling-Physics für App-Scrolls.
///
/// Nur die ballistische Simulation (Fling) wird angepasst — der Drag selbst
/// bleibt unverändert.
///
/// Tuning: [velocityFactor] und [maxVelocity] unten.
class SmoothScrollPhysics extends ScrollPhysics {
  /// Faktor auf die Fling-Geschwindigkeit (kleiner = kürzerer Auslauf).
  static const double velocityFactor = 0.6;

  /// Absolute Obergrenze der Fling-Geschwindigkeit in px/s.
  static const double maxVelocity = 3500;

  const SmoothScrollPhysics({super.parent});

  @override
  SmoothScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SmoothScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final damped = (velocity * velocityFactor).clamp(-maxVelocity, maxVelocity);
    return super.createBallisticSimulation(position, damped.toDouble());
  }
}
