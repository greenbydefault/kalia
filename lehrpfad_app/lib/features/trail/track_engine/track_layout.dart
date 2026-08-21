import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../domain/station.dart';
import 'track_style.dart';

/// Reiner 2D-Punkt (kein Flutter-`Offset`).
class TrackPoint {
  final double x;
  final double y;
  const TrackPoint(this.x, this.y);

  double distanceTo(TrackPoint o) {
    final dx = x - o.x;
    final dy = y - o.y;
    return math.sqrt(dx * dx + dy * dy);
  }
}

class TrackStationMarker {
  final Station station;
  final TrackPoint point;
  const TrackStationMarker({required this.station, required this.point});
}

/// Viewport-Fit: simplify → equirectangular → uniform scale/center.
class TrackLayout {
  final List<TrackPoint> route;
  final List<TrackStationMarker> stations;
  final double width;
  final double height;
  final bool closedLoop;

  const TrackLayout({
    required this.route,
    required this.stations,
    required this.width,
    required this.height,
    required this.closedLoop,
  });

  bool get isEmpty => route.length < 2;

  factory TrackLayout.build({
    required List<LatLng> route,
    required List<Station> stations,
    required double width,
    required double height,
    required bool rundkurs,
    double padding = TrackStyle.padding,
  }) {
    if (route.length < 2 || width <= 0 || height <= 0) {
      return TrackLayout(
        route: const [],
        stations: const [],
        width: width,
        height: height,
        closedLoop: rundkurs,
      );
    }

    final simplified = simplifyPolyline(
      route,
      targetCount: TrackStyle.simplifyTarget,
    );

    var minLat = simplified.first.latitude;
    var maxLat = minLat;
    var minLon = simplified.first.longitude;
    var maxLon = minLon;
    void expand(LatLng p) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLon = math.min(minLon, p.longitude);
      maxLon = math.max(maxLon, p.longitude);
    }

    for (final p in simplified) {
      expand(p);
    }
    for (final s in stations) {
      expand(s.position);
    }

    final cosLat = math.cos((minLat + maxLat) / 2 * math.pi / 180);
    final safeCos = cosLat.abs() < 1e-6 ? 1e-6 : cosLat;

    TrackPoint toLocal(LatLng p) => TrackPoint(
      (p.longitude - minLon) * safeCos,
      maxLat - p.latitude,
    );

    final localRoute = [for (final p in simplified) toLocal(p)];
    final localStations = [
      for (final s in stations) (station: s, point: toLocal(s.position)),
    ];

    var minX = localRoute.first.x;
    var maxX = minX;
    var minY = localRoute.first.y;
    var maxY = minY;
    void expandXY(TrackPoint p) {
      minX = math.min(minX, p.x);
      maxX = math.max(maxX, p.x);
      minY = math.min(minY, p.y);
      maxY = math.max(maxY, p.y);
    }

    for (final p in localRoute) {
      expandXY(p);
    }
    for (final s in localStations) {
      expandXY(s.point);
    }

    final spanX = math.max(maxX - minX, 1e-9);
    final spanY = math.max(maxY - minY, 1e-9);
    final innerW = math.max(width - 2 * padding, 1.0);
    final innerH = math.max(height - 2 * padding, 1.0);
    final scale = math.min(innerW / spanX, innerH / spanY);
    final ox = padding + (innerW - spanX * scale) / 2;
    final oy = padding + (innerH - spanY * scale) / 2;

    TrackPoint fit(TrackPoint p) =>
        TrackPoint(ox + (p.x - minX) * scale, oy + (p.y - minY) * scale);

    return TrackLayout(
      route: [for (final p in localRoute) fit(p)],
      stations: [
        for (final s in localStations)
          TrackStationMarker(station: s.station, point: fit(s.point)),
      ],
      width: width,
      height: height,
      closedLoop: rundkurs,
    );
  }

  Station? hitTest(
    TrackPoint tap, {
    double hitRadius = TrackStyle.stationHitRadius,
  }) {
    Station? best;
    var bestDist = hitRadius;
    for (final s in stations) {
      final d = s.point.distanceTo(tap);
      if (d <= bestDist) {
        bestDist = d;
        best = s.station;
      }
    }
    return best;
  }
}

/// Douglas-Peucker bis [targetCount] (Endpunkte bleiben).
List<LatLng> simplifyPolyline(List<LatLng> points, {required int targetCount}) {
  if (points.length <= targetCount || points.length < 3) {
    return List<LatLng>.from(points);
  }

  var lo = 0.0;
  var hi = 0.01;
  List<LatLng> best = points;
  for (var i = 0; i < 16; i++) {
    final mid = (lo + hi) / 2;
    final simplified = _douglasPeucker(points, mid);
    if (simplified.length > targetCount) {
      lo = mid;
    } else {
      hi = mid;
      best = simplified;
    }
  }

  if (best.length > targetCount) {
    final step = (points.length - 1) / (targetCount - 1);
    return [
      for (var i = 0; i < targetCount; i++)
        points[(i * step).round().clamp(0, points.length - 1)],
    ];
  }
  return best;
}

List<LatLng> _douglasPeucker(List<LatLng> points, double epsilon) {
  if (points.length < 3) return List<LatLng>.from(points);
  var maxDist = 0.0;
  var index = 0;
  final start = points.first;
  final end = points.last;
  for (var i = 1; i < points.length - 1; i++) {
    final d = _perpDistance(points[i], start, end);
    if (d > maxDist) {
      maxDist = d;
      index = i;
    }
  }
  if (maxDist > epsilon) {
    final left = _douglasPeucker(points.sublist(0, index + 1), epsilon);
    final right = _douglasPeucker(points.sublist(index), epsilon);
    return [...left.sublist(0, left.length - 1), ...right];
  }
  return [start, end];
}

double _perpDistance(LatLng p, LatLng a, LatLng b) {
  final dx = b.longitude - a.longitude;
  final dy = b.latitude - a.latitude;
  if (dx == 0 && dy == 0) {
    final ex = p.longitude - a.longitude;
    final ey = p.latitude - a.latitude;
    return math.sqrt(ex * ex + ey * ey);
  }
  final t =
      ((p.longitude - a.longitude) * dx + (p.latitude - a.latitude) * dy) /
      (dx * dx + dy * dy);
  final ex = p.longitude - (a.longitude + t * dx);
  final ey = p.latitude - (a.latitude + t * dy);
  return math.sqrt(ex * ex + ey * ey);
}
