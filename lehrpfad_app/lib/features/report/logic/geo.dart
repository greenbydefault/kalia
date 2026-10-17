import 'dart:math' as math;

/// Erdradius der Spec (Abschnitt 6.5).
const earthRadiusM = 6371008.8;

double _rad(double deg) => deg * math.pi / 180;

/// Haversine-Abstand in Metern.
double distanceM(double lat1, double lng1, double lat2, double lng2) {
  final dLat = _rad(lat2 - lat1);
  final dLng = _rad(lng2 - lng1);
  final a =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(_rad(lat1)) *
          math.cos(_rad(lat2)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * earthRadiusM * math.asin(math.min(1, math.sqrt(a.toDouble())));
}

/// Punkt mit Genauigkeit. Im Track ohne Zeitstempel (Spec 7.3).
class TrackPoint {
  const TrackPoint(this.lat, this.lng, [this.accuracyM = 0]);

  final double lat;
  final double lng;
  final double accuracyM;

  double distanceTo(TrackPoint other) =>
      distanceM(lat, lng, other.lat, other.lng);

  @override
  bool operator ==(Object other) =>
      other is TrackPoint &&
      other.lat == lat &&
      other.lng == lng &&
      other.accuracyM == accuracyM;

  @override
  int get hashCode => Object.hash(lat, lng, accuracyM);

  @override
  String toString() => 'TrackPoint($lat, $lng, ±$accuracyM)';
}

/// Ein Track besteht aus Segmenten, nach jeder Pause beginnt ein neues.
typedef TrackSegments = List<List<TrackPoint>>;
