import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:lehrpfad_app/core/config/map_config.dart';
import 'package:lehrpfad_app/core/config/map_motion.dart';
import 'package:lehrpfad_app/features/location/user_position_provider.dart';
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
  LatLngBounds? lastBounds;
  LatLng? lastCenter;
  double? lastZoom;
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
    lastBounds = bounds;
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
    lastCenter = center;
    lastZoom = zoom;
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

Trail _trail({String id = 't', LatLng? start}) {
  final a = start ?? const LatLng(52.52, 13.40);
  return Trail(
    id: id,
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
    route: [a, LatLng(a.latitude + 0.01, a.longitude + 0.01)],
    stationen: const [],
    amenities: const [],
  );
}

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

  testWidgets('Ort beim Trail-Laden rahmt den Anker, nicht den Katalog', (
    tester,
  ) async {
    flight = _FakeFlight();
    camera = make();
    const anchor = LatLng(52.52, 13.40);
    const near = LatLng(52.53, 13.41);
    const far = LatLng(48.14, 11.58);
    final locate = LocateTarget(position: anchor, nonce: 1);
    camera.apply(
      previous: MapCameraInputs(
        selected: null,
        trails: null,
        locateTarget: locate,
        userAnchor: anchor,
        framePlace: true,
      ),
      current: MapCameraInputs(
        selected: null,
        trails: [
          _trail(id: 'near', start: near),
          _trail(id: 'far', start: far),
        ],
        locateTarget: locate,
        userAnchor: anchor,
        framePlace: true,
      ),
    );

    expect(flight.flyToCount, 0);
    expect(flight.flyToBoundsCount, 1);
    tester.binding.scheduleFrame();
    await tester.pump();
    expect(flight.flyToBoundsCount, 1);
    final bounds = flight.lastBounds!;
    expect(bounds.contains(anchor), isTrue);
    expect(bounds.contains(near), isTrue);
    expect(bounds.contains(far), isFalse);
  });

  testWidgets('GPS-Locate verwirft den Katalog-Fit', (tester) async {
    flight = _FakeFlight();
    camera = make();
    const gps = LatLng(52.52, 13.40);
    camera.apply(
      previous: const MapCameraInputs(selected: null, trails: null),
      current: MapCameraInputs(
        selected: null,
        trails: [
          _trail(id: 'near', start: const LatLng(52.53, 13.41)),
          _trail(id: 'far', start: const LatLng(48.14, 11.58)),
        ],
        userAnchor: gps,
        locateTarget: const LocateTarget(position: gps, nonce: 1),
      ),
    );

    expect(flight.flyToCount, 1);
    expect(flight.lastCenter, gps);
    tester.binding.scheduleFrame();
    await tester.pump();
    expect(flight.flyToBoundsCount, 0);
  });

  testWidgets('Ort ohne nahen Pfad zentriert mit Stadt-Zoom', (tester) async {
    flight = _FakeFlight();
    camera = make();
    const anchor = LatLng(52.52, 13.40);
    camera.apply(
      previous: const MapCameraInputs(
        selected: null,
        trails: null,
        userAnchor: anchor,
        framePlace: true,
      ),
      current: MapCameraInputs(
        selected: null,
        trails: [_trail(id: 'far', start: const LatLng(48.14, 11.58))],
        userAnchor: anchor,
        framePlace: true,
      ),
    );

    expect(flight.flyToBoundsCount, 0);
    expect(flight.flyToCount, 1);
    tester.binding.scheduleFrame();
    await tester.pump();
    expect(flight.flyToBoundsCount, 0);
    expect(flight.lastCenter, anchor);
    expect(flight.lastZoom, MapConfig.placeZoom);
  });
}
