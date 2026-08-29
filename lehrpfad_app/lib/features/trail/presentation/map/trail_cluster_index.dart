import 'package:latlong2/latlong.dart';
import 'package:supercluster/supercluster.dart';

import '../../domain/trail.dart';

/// Supercluster-Index über Trail-Startpunkte.
///
/// [nodesAt] ist die einzige Query — Zoom als double, intern `floor`.
/// Selected/User gehören nicht hierher, der Caller filtert vorher.
class TrailClusterIndex {
  TrailClusterIndex(List<Trail> trails, {int radius = 80})
    : _index = SuperclusterImmutable<Trail>(
        getX: (t) => t.start.longitude,
        getY: (t) => t.start.latitude,
        radius: radius,
      ) {
    _index.load([
      for (final trail in trails)
        if (trail.startOrNull != null) trail,
    ]);
  }

  final SuperclusterImmutable<Trail> _index;

  List<TrailMapNode> nodesAt(double zoom) {
    return [
      for (final element in _index.search(-180, -90, 180, 90, zoom.floor()))
        switch (element) {
          ImmutableLayerCluster<Trail>(
            :final id,
            :final childPointCount,
            :final latitude,
            :final longitude,
          ) =>
            TrailMapCluster(
              id: id,
              center: LatLng(latitude, longitude),
              count: childPointCount,
              expansionZoom: expansionZoom(id),
            ),
          ImmutableLayerPoint<Trail>(:final originalPoint) => TrailMapPoint(
            originalPoint,
          ),
          ImmutableLayerElement<Trail>() => throw StateError(
            'Unbekanntes Supercluster-Element',
          ),
        },
    ];
  }

  int expansionZoom(int clusterId) => _index.expansionZoomOf(clusterId);

  /// Startpunkte aller Blätter in [clusterId]. Leer, wenn Supercluster
  /// den Cluster nicht kennt — Caller fällt dann auf Center+expansionZoom.
  List<LatLng> startsIn(int clusterId, {required int count}) {
    try {
      final points = _index.pointsWithin(clusterId, limit: count);
      return [for (final p in points) p.originalPoint.start];
    } catch (_) {
      return const [];
    }
  }
}

sealed class TrailMapNode {
  const TrailMapNode();
}

class TrailMapPoint extends TrailMapNode {
  const TrailMapPoint(this.trail);

  final Trail trail;
}

class TrailMapCluster extends TrailMapNode {
  const TrailMapCluster({
    required this.id,
    required this.center,
    required this.count,
    required this.expansionZoom,
  });

  final int id;
  final LatLng center;
  final int count;
  final int expansionZoom;
}
