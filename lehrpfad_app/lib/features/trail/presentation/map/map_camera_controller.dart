import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/map_config.dart';
import '../../../../core/config/map_motion.dart';
import '../../../location/user_position_provider.dart';
import '../../domain/trail.dart';
import 'camera_target.dart';
import 'map_camera_animator.dart';
import 'trail_cluster_index.dart';

/// Snapshot, den das Widget der Kartenkamera reicht — ohne Intent-Politik.
class MapCameraInputs {
  const MapCameraInputs({
    required this.selected,
    required this.trails,
    this.pendingCameraTrailId,
    this.followPosition,
    this.locateTarget,
    this.userAnchor,
  });

  final Trail? selected;
  final List<Trail>? trails;
  final String? pendingCameraTrailId;
  final LatLng? followPosition;
  final LocateTarget? locateTarget;
  final LatLng? userAnchor;

  static Set<String> idSet(List<Trail>? trails) => {
    if (trails != null)
      for (final trail in trails) trail.id,
  };
}

/// Kartenkamera der Übersichtskarte: ein Owner für Fit, Flug, Follow, Locate
/// und wann welcher Intent feuert.
///
/// Reine Klasse ohne Widget — das Widget liefert [apply]-Snapshots. Kein
/// setState hier drin; der Animator bewegt die Karte ohne Rebuilds.
///
/// Priorität: Geste > neuer Intent > Follow.
class MapCameraController {
  MapCameraController({
    TickerProvider? vsync,
    required this._isMounted,
    required this._onFadeReset,
    required this._onFadeStart,
    CameraFlight? flight,
    MapController? mapController,
  }) : mapController = mapController ?? MapController() {
    _flight =
        flight ??
        MapCameraAnimator(mapController: this.mapController, vsync: vsync!);
  }

  final MapController mapController;
  late final CameraFlight _flight;

  final bool Function() _isMounted;
  final void Function() _onFadeReset;
  final void Function() _onFadeStart;

  Object? _flyToken;
  int _intentGen = 0;
  bool _followPaused = false;

  bool get isAnimating => _flight.isAnimating;

  /// Intent-Politik aus Widget-Snapshots. Consume von Pending passiert hier.
  void apply({
    required MapCameraInputs current,
    required MapCameraInputs previous,
    VoidCallback? onPendingConsumed,
  }) {
    final selected = current.selected;
    final oldSelected = previous.selected;
    final locateChanged =
        current.locateTarget != null &&
        current.locateTarget != previous.locateTarget;

    if (selected == null) {
      if (oldSelected != null) {
        clearSelection();
      }
      final oldIds = MapCameraInputs.idSet(previous.trails);
      final newIds = MapCameraInputs.idSet(current.trails);
      if (oldSelected == null &&
          !locateChanged &&
          oldIds != newIds &&
          newIds.isNotEmpty) {
        fitCatalog(current.trails!, anchor: current.userAnchor);
      }
    } else if (selected.id != oldSelected?.id) {
      final pending = current.pendingCameraTrailId;
      if (pending == null) {
        showTrail(selected, peek: true, external: false);
      } else {
        onPendingConsumed?.call();
        showTrail(selected, peek: true, external: pending == selected.id);
      }
    }

    final follow = current.followPosition;
    if (follow != null && follow != previous.followPosition) {
      this.follow(follow);
    }

    if (locateChanged) {
      locate(current.locateTarget!.position);
    }
  }

  /// Tap: Kamera bleibt, nur Track-Fade. Externer Einstieg (Meine Routen):
  /// Fit auf die Trail-Geometrie.
  ///
  /// [peek] setzt Bottom-Padding beim externen Fit. [external] nutzt den
  /// langen Flug und startet den Track-Fade erst danach; Tap faded sofort.
  void showTrail(Trail trail, {required bool peek, required bool external}) {
    _bumpGen();
    if (external) {
      unawaited(_flyToTrail(trail, peek: peek));
    } else {
      _onFadeStart();
    }
  }

  /// Cluster-Tap: Bounds der Kinder-Starts, sonst Center + expansionZoom.
  void expandCluster(TrailMapCluster cluster, List<LatLng> childStarts) {
    _followPaused = true;
    _bumpGen();
    unawaited(_expandCluster(cluster, childStarts));
  }

  void locate(LatLng position) {
    _followPaused = true;
    _bumpGen();
    unawaited(_locate(position));
  }

  /// Tour-Follow. No-op bei Geste/Intent-Pause oder laufendem Flug.
  void follow(LatLng position) {
    if (_followPaused || _flight.isAnimating) return;
    _flight.follow(position);
  }

  /// Katalog-Fit (Filterwechsel, keine Selection). Post-Frame; neuere
  /// Intents entwerten über [_intentGen].
  void fitCatalog(List<Trail> trails, {LatLng? anchor}) {
    final gen = _bumpGen();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isMounted()) return;
      if (gen != _intentGen) return;
      final pts = allPoints(trails, anchor: anchor);
      final target = CameraTarget.fromPoints(
        pts,
        padding: CameraTarget.catalogPadding,
      );
      if (target == null) return;
      unawaited(
        _runFlight(
          () => _flight.flyToBounds(target.bounds, padding: target.padding),
        ),
      );
    });
  }

  /// User-Pan/Zoom: Flug abbrechen, Follow pausieren, Katalog-Fit entwerten.
  void onUserGesture() {
    _followPaused = true;
    _bumpGen();
    _flyToken = null;
    _flight.cancel();
  }

  /// Deselect: Fade/Flug weg, kein Auto-Fit zurück auf den Katalog.
  void clearSelection() {
    _flyToken = null;
    _bumpGen();
    _flight.cancel();
    _onFadeReset();
  }

  void dispose() {
    _flight.dispose();
    mapController.dispose();
  }

  Future<void> _flyToTrail(Trail trail, {required bool peek}) async {
    final token = Object();
    _flyToken = token;
    _onFadeReset();
    final target = CameraTarget.fromTrail(
      trail,
      padding: CameraTarget.paddingFor(peek: peek),
    );
    if (target == null) return;
    await _flight.flyToBounds(
      target.bounds,
      padding: target.padding,
      duration: MapMotion.fly,
      curve: MapMotion.flyCurve,
    );
    if (!_isMounted() || !identical(_flyToken, token)) return;
    _onFadeStart();
  }

  Future<void> _expandCluster(
    TrailMapCluster cluster,
    List<LatLng> childStarts,
  ) {
    if (childStarts.length >= 2) {
      final target = CameraTarget.fromPoints(
        childStarts,
        padding: CameraTarget.catalogPadding,
      );
      if (target == null) return Future.value();
      return _runFlight(
        () => _flight.flyToBounds(target.bounds, padding: target.padding),
      );
    }
    return _runFlight(
      () => _flight.flyTo(cluster.center, cluster.expansionZoom.toDouble()),
    );
  }

  Future<void> _locate(LatLng position) {
    return _runFlight(() {
      final zoom = _currentZoom < MapConfig.locateZoom
          ? MapConfig.locateZoom
          : _currentZoom;
      return _flight.flyTo(position, zoom);
    });
  }

  Future<void> _runFlight(Future<void> Function() start) {
    final token = Object();
    _flyToken = token;
    return start();
  }

  MapCamera? get _tryCamera {
    try {
      return mapController.camera;
    } catch (_) {
      return null;
    }
  }

  double get _currentZoom => _tryCamera?.zoom ?? MapConfig.defaultZoom;

  int _bumpGen() => ++_intentGen;

  static List<LatLng> allPoints(List<Trail> trails, {LatLng? anchor}) => [
    for (final trail in trails) ...trail.mapPoints,
    ?anchor,
  ];
}
