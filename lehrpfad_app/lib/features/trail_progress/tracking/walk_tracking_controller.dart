import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../location/proximity.dart';
import '../../trail/data/providers.dart';
import '../../trail/domain/trail.dart';
import '../data/trail_progress_providers.dart';
import '../domain/completion_source.dart';
import '../domain/trail_walk.dart';
import '../geo/polyline_metrics.dart';
import '../geo/walk_progress_evaluator.dart';
import 'location_service.dart';
import 'walk_snapshot.dart';

final walkSnapshotProvider =
    NotifierProvider<WalkTrackingController, WalkSnapshot?>(
      WalkTrackingController.new,
    );

/// Hält Location-Stream, Snap-Math und throttled Snapshots.
class WalkTrackingController extends Notifier<WalkSnapshot?> {
  static const _minUpdateInterval = Duration(milliseconds: 900);
  static const _minMoveM = 3.0;
  static const _remotePersistInterval = Duration(seconds: 20);

  StreamSubscription<LatLng>? _sub;
  PolylineMetrics? _metrics;
  Trail? _trail;
  TrailWalk? _walk;
  DateTime? _lastUiAt;
  LatLng? _lastUiPos;
  DateTime? _lastPersistAt;
  bool _starting = false;

  @override
  WalkSnapshot? build() {
    ref.onDispose(() {
      unawaited(_sub?.cancel());
    });
    return null;
  }

  LocationService get _location => ref.read(locationServiceProvider);

  Future<void> startTour(Trail trail) async {
    if (_starting) return;
    _starting = true;
    try {
      await _requireOnSite(trail);
      final walk = await ref
          .read(activeWalkProvider.notifier)
          .startWalk(trail.id);
      await _attach(trail, walk);
    } finally {
      _starting = false;
    }
  }

  Future<void> resumeTour(Trail trail, TrailWalk walk) async {
    await _requireOnSite(trail);
    await _attach(trail, walk);
  }

  Future<void> _requireOnSite(Trail trail) async {
    await _location.ensurePermission(requestAlways: false);
    final fix = await _location.getFix();
    assertOnSite(trail, fix);
    if (!kIsWeb) {
      try {
        await _location.ensurePermission(requestAlways: true);
      } catch (_) {}
    }
  }

  Future<void> _attach(Trail trail, TrailWalk walk) async {
    await _sub?.cancel();
    _trail = trail;
    _walk = walk;
    _metrics = PolylineMetrics.from(trail.route);
    _lastUiAt = null;
    _lastUiPos = null;
    _lastPersistAt = DateTime.now();

    _sub = _location.watchPosition().listen(
      _onPosition,
      onError: _onStreamError,
    );

    try {
      final initial = await _location.getFix();
      await _onPosition(initial.position, force: true);
    } on LocationException catch (e) {
      _onStreamError(e);
    }
  }

  void _onStreamError(Object error) {
    final current = state;
    final message = error is LocationException
        ? error.message
        : 'Standort verloren';
    if (current != null) {
      state = current.copyWith(locationError: message);
      return;
    }
    final trail = _trail;
    if (trail == null) return;
    final fallback = trail.startOrNull;
    if (fallback == null) return;
    state = WalkSnapshot(
      trailId: trail.id,
      rawPosition: fallback,
      snappedPosition: fallback,
      progressM: _walk?.progressM ?? 0,
      progressRatio: _walk?.progressRatio ?? 0,
      offTrack: false,
      visitedStationIds: _walk?.visitedStationIds ?? const [],
      showRouteProgress: trail.isLinie,
      locationError: message,
    );
  }

  Future<void> stopTour({bool abandon = false}) async {
    await _sub?.cancel();
    _sub = null;
    final walk = _walk;
    _trail = null;
    _metrics = null;
    _walk = null;
    state = null;
    if (walk == null) return;
    if (abandon) {
      await ref.read(activeWalkProvider.notifier).abandonWalk();
    }
  }

  Future<void> endTourCompleted() async {
    final walk = _walk;
    await _sub?.cancel();
    _sub = null;
    _trail = null;
    _metrics = null;
    _walk = null;
    state = null;
    if (walk != null) {
      await ref
          .read(activeWalkProvider.notifier)
          .completeWalk(walk, source: CompletionSource.gps);
    }
  }

  Future<void> _onPosition(LatLng position, {bool force = false}) async {
    final trail = _trail;
    final metrics = _metrics;
    var walk = _walk;
    if (trail == null || metrics == null || walk == null) return;

    final now = DateTime.now();
    if (!force) {
      final lastAt = _lastUiAt;
      final lastPos = _lastUiPos;
      if (lastAt != null &&
          now.difference(lastAt) < _minUpdateInterval &&
          lastPos != null &&
          haversineMeters(position, lastPos) < _minMoveM) {
        return;
      }
    }

    final visited = walk.visitedStationIds.toSet();
    final eval = evaluateWalkProgress(
      trail: trail,
      metrics: metrics,
      position: position,
      visitedStationIds: visited,
      startedAt: walk.startedAt,
      now: now,
    );

    final nextVisited = [...walk.visitedStationIds];
    for (final id in eval.newlyVisitedStationIds) {
      if (!nextVisited.contains(id)) nextVisited.add(id);
    }

    walk = walk.copyWith(
      progressM: eval.snap.alongTrackM,
      progressRatio: eval.progressRatio,
      lastLat: position.latitude,
      lastLon: position.longitude,
      visitedStationIds: nextVisited,
      updatedAt: now.toUtc(),
    );
    _walk = walk;

    _lastUiAt = now;
    _lastUiPos = position;
    state = WalkSnapshot(
      trailId: trail.id,
      rawPosition: position,
      snappedPosition: eval.snap.snapped,
      progressM: eval.snap.alongTrackM,
      progressRatio: eval.progressRatio,
      offTrack: eval.offTrack,
      visitedStationIds: nextVisited,
      nextStation: eval.nextStation,
      justVisitedStationId: eval.newlyVisitedStationIds.isEmpty
          ? null
          : eval.newlyVisitedStationIds.last,
      showRouteProgress: trail.isLinie,
    );

    final lastPersist = _lastPersistAt;
    final shouldPersist =
        eval.newlyVisitedStationIds.isNotEmpty ||
        lastPersist == null ||
        now.difference(lastPersist) >= _remotePersistInterval ||
        eval.shouldAutoComplete;
    if (shouldPersist) {
      _lastPersistAt = now;
      await ref.read(activeWalkProvider.notifier).updateWalk(walk);
    }

    if (eval.shouldAutoComplete) {
      await endTourCompleted();
    }
  }

  /// Auto-Resume nur wenn vor Ort; sonst bleibt die Tour pausiert.
  Future<void> ensureTrackingForActiveWalk() async {
    final walk = ref.read(activeWalkProvider).asData?.value;
    if (walk == null || state != null) return;
    final trails = ref.read(trailsProvider).asData?.value;
    if (trails == null) return;
    Trail? trail;
    for (final t in trails) {
      if (t.id == walk.trailId) {
        trail = t;
        break;
      }
    }
    if (trail == null) return;
    try {
      await resumeTour(trail, walk);
    } on LocationException {
      // Pausiert bleiben — UI zeigt PausedTourBar, kein stilles GPS.
    } catch (_) {}
  }
}
