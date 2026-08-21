import 'package:latlong2/latlong.dart';

import '../trail/domain/trail.dart';
import '../trail_progress/geo/polyline_metrics.dart';
import '../trail_progress/geo/snap_to_path.dart';
import '../trail_progress/tracking/location_service.dart';

const linieOnSiteRadiusM = 250.0;
const flaecheOnSiteRadiusM = 150.0;
const maxFixAccuracyM = 100.0;

enum OnSiteResult { yes, no, inaccurate, unknown }

/// Distanz User → nächster Punkt des Trails.
/// Linie: Polyline. Fläche: 0 im Polygon, sonst Kante.
/// `null` wenn der Trail keine Geometrie hat.
double? distanceToTrailM(Trail trail, LatLng user) {
  if (trail.isFlaeche && trail.area.length >= 3) {
    if (pointInPolygon(user, trail.area)) return 0;
    return _distanceToClosedRingM(user, trail.area);
  }
  if (trail.route.length >= 2) {
    return nearestPointOnPolyline(
      user,
      PolylineMetrics.from(trail.route),
    ).distanceToPathM;
  }
  final start = trail.startOrNull;
  if (start == null) return null;
  return haversineMeters(user, start);
}

double onSiteRadiusM(Trail trail) =>
    trail.isFlaeche ? flaecheOnSiteRadiusM : linieOnSiteRadiusM;

OnSiteResult onSiteResult(Trail trail, LocationFix? fix) {
  if (fix == null) return OnSiteResult.unknown;
  if (fix.accuracyM != null && fix.accuracyM! > maxFixAccuracyM) {
    return OnSiteResult.inaccurate;
  }
  final d = distanceToTrailM(trail, fix.position);
  if (d == null) return OnSiteResult.unknown;
  return d <= onSiteRadiusM(trail) ? OnSiteResult.yes : OnSiteResult.no;
}

void assertAccurate(LocationFix fix) {
  if (fix.accuracyM != null && fix.accuracyM! > maxFixAccuracyM) {
    throw LocationException(
      LocationFailure.inaccurate,
      'GPS zu ungenau, kurz warten.',
    );
  }
}

void assertOnSite(Trail trail, LocationFix fix) {
  assertAccurate(fix);
  final d = distanceToTrailM(trail, fix.position);
  if (d == null) {
    throw LocationException(
      LocationFailure.unavailable,
      'Dieser Ort hat keine Position.',
    );
  }
  final limit = onSiteRadiusM(trail);
  if (d > limit) {
    throw LocationException(
      LocationFailure.tooFar,
      'Noch ${formatDistanceM(d)} zum Start',
    );
  }
}

String formatDistanceM(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  final km = meters / 1000;
  if (km < 10) return '${km.toStringAsFixed(1)} km';
  return '${km.round()} km';
}

/// Ray-Casting, inkl. Punkt auf Kante.
bool pointInPolygon(LatLng point, List<LatLng> polygon) {
  if (polygon.length < 3) return false;
  var inside = false;
  for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    final a = polygon[i];
    final b = polygon[j];
    if (_onSegment(point, a, b)) return true;
    final intersect =
        (a.latitude > point.latitude) != (b.latitude > point.latitude) &&
        point.longitude <
            (b.longitude - a.longitude) *
                    (point.latitude - a.latitude) /
                    (b.latitude - a.latitude) +
                a.longitude;
    if (intersect) inside = !inside;
  }
  return inside;
}

double _distanceToClosedRingM(LatLng point, List<LatLng> ring) {
  final closed = [...ring, if (ring.first != ring.last) ring.first];
  return nearestPointOnPolyline(
    point,
    PolylineMetrics.from(closed),
  ).distanceToPathM;
}

bool _onSegment(LatLng p, LatLng a, LatLng b, {double eps = 1e-10}) {
  final cross =
      (p.latitude - a.latitude) * (b.longitude - a.longitude) -
      (p.longitude - a.longitude) * (b.latitude - a.latitude);
  if (cross.abs() > 1e-7) return false;
  final dot =
      (p.latitude - a.latitude) * (b.latitude - a.latitude) +
      (p.longitude - a.longitude) * (b.longitude - a.longitude);
  if (dot < -eps) return false;
  final len2 =
      (b.latitude - a.latitude) * (b.latitude - a.latitude) +
      (b.longitude - a.longitude) * (b.longitude - a.longitude);
  return dot - len2 <= eps;
}
