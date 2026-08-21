import 'package:flutter/material.dart';

import 'smooth_scroll_physics.dart';

/// ScrollBehavior, das [SmoothScrollPhysics] über die Plattform-Physics legt.
class SmoothScrollBehavior extends MaterialScrollBehavior {
  const SmoothScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return SmoothScrollPhysics(parent: super.getScrollPhysics(context));
  }
}

/// Drop-in-Wrapper: wrappt [child] mit [SmoothScrollBehavior].
///
/// Für Trail-Detail-Views; künftige Screens denselben Wrapper nutzen.
class SmoothScroll extends StatelessWidget {
  final Widget child;

  const SmoothScroll({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const SmoothScrollBehavior(),
      child: child,
    );
  }
}

/// Programmatisches Smooth-Scrollen (z. B. zu Station/Abschnitt).
extension ScrollControllerSmoothX on ScrollController {
  Future<void> smoothAnimateTo(
    double offset, {
    Duration duration = const Duration(milliseconds: 450),
    Curve curve = Curves.easeOutCubic,
  }) {
    return animateTo(offset, duration: duration, curve: curve);
  }
}
