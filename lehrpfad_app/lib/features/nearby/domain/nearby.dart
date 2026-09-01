import '../../trail/domain/haversine.dart';
import '../../trail/domain/trail.dart';
import 'nearby_place.dart';

/// Default-Umkreis für Orte in der Nähe (Distanz zu [Trail.start]).
const nearbyRadiusDefaultKm = 20.0;

/// Engerer Umkreis für Übernachtung — nur Camping.
const nearbyRadiusProKategorie = <String, double>{'camping': 5.0};

/// Harte Kappung der Anzeige pro Trail (Liste + Marker).
const nearbyMaxProTrail = 8;

/// Erst Mix, dann auffüllen: höchstens so viele Treffer einer Kategorie
/// bevor [nearbyMaxProTrail] mit den Nächsten (auch gleicher Kategorie) voll wird.
const nearbyMaxProKategorie = 2;

double nearbyRadiusKmFor(String kategorie) =>
    nearbyRadiusProKategorie[kategorie] ?? nearbyRadiusDefaultKm;

/// Treffer: Ort plus Distanz in km zum Trail-Start.
class NearbyTreffer {
  final NearbyPlace place;
  final double distanzKm;

  const NearbyTreffer({required this.place, required this.distanzKm});
}

/// Orte im Umkreis um [Trail.start], nach Distanz sortiert, max. [nearbyMaxProTrail].
///
/// Distanz = Haversine zu [Trail.startOrNull]. Kein Start → leere Liste.
/// Radius pro Kategorie: [nearbyRadiusKmFor] (Camping 5 km, sonst 20 km).
/// Cap: erst max. [nearbyMaxProKategorie] pro Kategorie, Rest nach Distanz.
List<NearbyTreffer> nearby(Trail trail, List<NearbyPlace> catalog) {
  final start = trail.startOrNull;
  if (start == null) return const [];
  final hits = <NearbyTreffer>[];
  for (final place in catalog) {
    final radiusM = nearbyRadiusKmFor(place.kategorie) * 1000;
    final m = haversineMeters(place.position, start);
    if (m <= radiusM) {
      hits.add(NearbyTreffer(place: place, distanzKm: m / 1000));
    }
  }
  hits.sort((a, b) => a.distanzKm.compareTo(b.distanzKm));
  return capNearby(hits);
}

/// Kürzt [hits] (bereits distanzsortiert) auf [nearbyMaxProTrail].
///
/// Erster Durchlauf: nächste Treffer, solange die Kategorie unter
/// [nearbyMaxProKategorie] liegt. Zweiter Durchlauf: Rest nach Distanz.
List<NearbyTreffer> capNearby(List<NearbyTreffer> hits) {
  if (hits.length <= nearbyMaxProTrail) return hits;
  final picked = <NearbyTreffer>[];
  final seen = <NearbyTreffer>{};
  final counts = <String, int>{};
  for (final t in hits) {
    if (picked.length >= nearbyMaxProTrail) break;
    final n = counts[t.place.kategorie] ?? 0;
    if (n >= nearbyMaxProKategorie) continue;
    picked.add(t);
    seen.add(t);
    counts[t.place.kategorie] = n + 1;
  }
  if (picked.length < nearbyMaxProTrail) {
    for (final t in hits) {
      if (picked.length >= nearbyMaxProTrail) break;
      if (seen.contains(t)) continue;
      picked.add(t);
    }
  }
  picked.sort((a, b) => a.distanzKm.compareTo(b.distanzKm));
  return picked;
}

/// Anzeige: `320 m` / `3,2 km` / `12 km`.
String formatDistanzKm(double km) {
  if (km < 0.1) return '${(km * 1000).round()} m';
  if (km < 10) return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
  return '${km.round()} km';
}
