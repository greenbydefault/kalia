import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import 'polyline_metrics.dart';

class SnapResult {
  const SnapResult({
    required this.snapped,
    required this.distanceToPathM,
    required this.alongTrackM,
    required this.segmentIndex,
  });

  final LatLng snapped;
  final double distanceToPathM;
  final double alongTrackM;
  final int segmentIndex;
}

/// Nächster Punkt auf der Polyline + Along-Track-Meter.
SnapResult nearestPointOnPolyline(LatLng point, PolylineMetrics metrics) {
  final pts = metrics.points;
  if (pts.isEmpty) {
    return SnapResult(
      snapped: point,
      distanceToPathM: double.infinity,
      alongTrackM: 0,
      segmentIndex: 0,
    );
  }
  if (pts.length == 1) {
    return SnapResult(
      snapped: pts.first,
      distanceToPathM: haversineMeters(point, pts.first),
      alongTrackM: 0,
      segmentIndex: 0,
    );
  }

  var bestDist = double.infinity;
  var bestSnap = pts.first;
  var bestAlong = 0.0;
  var bestSeg = 0;

  for (var i = 0; i < pts.length - 1; i++) {
    final a = pts[i];
    final b = pts[i + 1];
    final projected = _projectOnSegment(point, a, b);
    final dist = haversineMeters(point, projected.point);
    if (dist < bestDist) {
      bestDist = dist;
      bestSnap = projected.point;
      bestAlong =
          metrics.cumDistM[i] + metrics.segmentLengthsM[i] * projected.t;
      bestSeg = i;
    }
  }

  return SnapResult(
    snapped: bestSnap,
    distanceToPathM: bestDist,
    alongTrackM: bestAlong.clamp(0.0, metrics.totalLengthM),
    segmentIndex: bestSeg,
  );
}

class _Projection {
  const _Projection(this.point, this.t);
  final LatLng point;
  final double t;
}

/// Projektion in lokalem equirectangular Raum (gut genug für Trail-Segmente).
_Projection _projectOnSegment(LatLng p, LatLng a, LatLng b) {
  final midLat = (a.latitude + b.latitude) / 2;
  final cosLat = math.cos(midLat * math.pi / 180);
  final ax = a.longitude * cosLat;
  final ay = a.latitude;
  final bx = b.longitude * cosLat;
  final by = b.latitude;
  final px = p.longitude * cosLat;
  final py = p.latitude;

  final dx = bx - ax;
  final dy = by - ay;
  final len2 = dx * dx + dy * dy;
  if (len2 <= 0) return _Projection(a, 0);

  var t = ((px - ax) * dx + (py - ay) * dy) / len2;
  t = t.clamp(0.0, 1.0);
  return _Projection(
    LatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    ),
    t,
  );
}
