import 'package:flutter/material.dart';

import 'smooth_scroll_physics.dart';

/// App-weites ScrollBehavior: [SmoothScrollPhysics] über die Plattform-Physics.
///
/// Hängt an [LehrpfadApp]; neue Screens erben es. Horizontale Pager mit
/// eigenem [ScrollConfiguration] (z. B. SnappingPager) bleiben unberührt.
class SmoothScrollBehavior extends MaterialScrollBehavior {
  const SmoothScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return SmoothScrollPhysics(parent: super.getScrollPhysics(context));
  }
}

/// Lokaler Override mit [SmoothScrollBehavior] (Tests, Overlays außerhalb
/// der App). Produktion setzt das Behavior global in [LehrpfadApp].
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
