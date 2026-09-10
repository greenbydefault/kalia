import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/app/app.dart';
import 'package:lehrpfad_app/shared/scrolling/smooth_scroll.dart';
import 'package:lehrpfad_app/shared/scrolling/smooth_scroll_physics.dart';

FixedScrollMetrics _metrics({required double pixels}) {
  return FixedScrollMetrics(
    minScrollExtent: 0,
    maxScrollExtent: 5000,
    pixels: pixels,
    viewportDimension: 800,
    axisDirection: AxisDirection.down,
    devicePixelRatio: 1,
  );
}

void main() {
  const physics = SmoothScrollPhysics(parent: ClampingScrollPhysics());

  test('dämpft Fling-Velocity mit velocityFactor', () {
    final sim = physics.createBallisticSimulation(_metrics(pixels: 0), 1000);
    expect(sim, isNotNull);
    expect(sim!.dx(0), closeTo(1000 * SmoothScrollPhysics.velocityFactor, 0.1));
  });

  test('klemmt Fling-Velocity auf maxVelocity', () {
    final sim = physics.createBallisticSimulation(_metrics(pixels: 0), 10000);
    expect(sim, isNotNull);
    expect(sim!.dx(0).abs(), closeTo(SmoothScrollPhysics.maxVelocity, 0.1));
  });

  test('dämpft negative Fling-Velocity', () {
    final sim = physics.createBallisticSimulation(
      _metrics(pixels: 2000),
      -1000,
    );
    expect(sim, isNotNull);
    expect(
      sim!.dx(0),
      closeTo(-1000 * SmoothScrollPhysics.velocityFactor, 0.1),
    );
  });

  testWidgets('LehrpfadApp setzt SmoothScrollBehavior', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LehrpfadApp()));
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.scrollBehavior, isA<SmoothScrollBehavior>());
  });
}
