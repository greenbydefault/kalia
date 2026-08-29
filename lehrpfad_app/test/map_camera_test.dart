import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:lehrpfad_app/core/config/map_motion.dart';
import 'package:lehrpfad_app/features/trail/domain/trail.dart';
import 'package:lehrpfad_app/features/trail/presentation/map/camera_target.dart';
import 'package:lehrpfad_app/features/trail/presentation/map/map_camera_animator.dart';
import 'package:lehrpfad_app/features/trail/presentation/map/map_camera_controller.dart';

class _FakeFlight implements CameraFlight {
  int followCount = 0;
  int cancelCount = 0;
  int flyToBoundsCount = 0;
  int flyToCount = 0;
  Duration? lastDuration;
  EdgeInsets? lastPadding;
  bool _animating = false;
  Completer<void>? _hanging;

  @override
  bool get isAnimating => _animating;

  Future<void> _hang() {
    _hanging = Completer();
    _animating = true;
    return _hanging!.future;
  }

  void complete() {
    _animating = false;
    if (_hanging != null && !_hanging!.isCompleted) {
      _hanging!.complete();
    }
    _hanging = null;
  }

  @override
  Future<void> flyToBounds(
    LatLngBounds bounds, {
    EdgeInsets padding = const EdgeInsets.all(48),
    Duration duration = MapMotion.fly,
    Curve curve = MapMotion.flyCurve,
  }) {
    flyToBoundsCount++;
    lastPadding = padding;
    lastDuration = duration;
    return _hang();
  }

  @override
  Future<void> flyTo(
    LatLng center,
    double zoom, {
    Duration duration = MapMotion.fly,
    Curve curve = MapMotion.flyCurve,
  }) {
    flyToCount++;
    lastDuration = duration;
    return _hang();
  }

  @override
  void follow(LatLng position) => followCount++;

  @override
  void cancel() {
    cancelCount++;
    complete();
  }

  @override
  void dispose() {}
}

Trail _trail() => Trail(
  id: 't',
  name: 't',
  typ: 'wald',
  kurzbeschreibung: 'k',
  beschreibung: 'b',
  laengeKm: 1,
  dauerMin: 30,
  rundkurs: false,
  markierung: 'm',
  betreiber: 'b',
  region: 'r',
  anreise: 'a',
  startName: 's',
  arten: const [],
  route: const [LatLng(52.52, 13.40), LatLng(52.60, 13.50)],
  stationen: const [],
  amenities: const [],
);

void main() {
  late _FakeFlight flight;
  late MapCameraController camera;

  MapCameraController make() => MapCameraController(
    isMounted: () => true,
    onFadeReset: () {},
    onFadeStart: () {},
    flight: flight,
  );

  tearDown(() {
    camera.dispose();
  });

  testWidgets('Geste cancelt Flug', (tester) async {
    flight = _FakeFlight();
    camera = make();
    camera.showTrail(_trail(), peek: true, external: true);
    expect(flight.flyToBoundsCount, 1);
    expect(flight.isAnimating, isTrue);

    camera.onUserGesture();
    expect(flight.cancelCount, 1);
    expect(flight.isAnimating, isFalse);
  });

  testWidgets('fitCatalog nach showTrail wird verworfen', (tester) async {
    flight = _FakeFlight();
    camera = make();
    camera.fitCatalog([_trail()]);
    camera.showTrail(_trail(), peek: true, external: true);
    expect(flight.flyToBoundsCount, 1);

    await tester.pump();
    expect(flight.flyToBoundsCount, 1);
  });

  testWidgets('Follow während Flug ist no-op', (tester) async {
    flight = _FakeFlight();
    camera = make();
    camera.showTrail(_trail(), peek: true, external: true);
    camera.follow(const LatLng(52, 13));
    expect(flight.followCount, 0);
  });

  testWidgets('Follow ohne Pause und ohne Flug geht durch', (tester) async {
    flight = _FakeFlight();
    camera = make();
    camera.follow(const LatLng(52, 13));
    expect(flight.followCount, 1);
  });

  testWidgets('externer Einstieg fittet Bounds mit Peek-Padding', (
    tester,
  ) async {
    flight = _FakeFlight();
    camera = make();
    camera.showTrail(_trail(), peek: true, external: true);
    expect(flight.lastPadding, CameraTarget.peekPadding);
    expect(flight.lastDuration, MapMotion.fly);
  });
}
