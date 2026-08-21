import 'package:latlong2/latlong.dart';

import '../../trail/domain/station.dart';
import 'polyline_metrics.dart';

const defaultStationGeofenceRadiusM = 35.0;

/// Station-Schlüssel stabil über Seed und Supabase.
String stationKey(Station station) => station.osmId.toString();

/// Neu betretene Stationen innerhalb des Radius.
List<String> stationsEntered({
  required LatLng position,
  required List<Station> stations,
  required Set<String> alreadyVisited,
  double radiusM = defaultStationGeofenceRadiusM,
}) {
  final entered = <String>[];
  for (final station in stations) {
    final key = stationKey(station);
    if (alreadyVisited.contains(key)) continue;
    if (haversineMeters(position, station.position) <= radiusM) {
      entered.add(key);
    }
  }
  return entered;
}

Station? nextUnvisitedStation({
  required List<Station> stations,
  required Set<String> visited,
}) {
  final sorted = [...stations]
    ..sort((a, b) => a.reihenfolge.compareTo(b.reihenfolge));
  for (final s in sorted) {
    if (!visited.contains(stationKey(s))) return s;
  }
  return null;
}
