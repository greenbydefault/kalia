import '../../trail/domain/trail.dart';
import 'nearby_place.dart';

/// Vorberechnete Auto-Fahrzeiten: Trail-ID → Ort-ID → Sekunden.
///
/// Quelle: `assets/seed/nearby_zeiten.json` / Tabelle `trail_pois`
/// (`tools/nearby_zeiten.py`). Enthält nur Paare bis [nearbyMaxFahrzeitSek].
typedef NearbyZeiten = Map<String, Map<String, int>>;

/// Ein Ort gehört zum Trail, wenn die Auto-Fahrt vom Trail-Start höchstens
/// so lange dauert (alle Kategorien). Muss zu `MAX_SEK` in
/// `tools/nearby_zeiten.py` passen.
const nearbyMaxFahrzeitSek = 20 * 60;

/// Harte Kappung der Anzeige pro Trail (Liste + Marker).
const nearbyMaxProTrail = 8;

/// Erst Mix, dann auffüllen: höchstens so viele Treffer einer Kategorie
/// bevor [nearbyMaxProTrail] mit den Nächsten (auch gleicher Kategorie) voll wird.
const nearbyMaxProKategorie = 2;

/// Treffer: Ort plus Auto-Fahrzeit in Sekunden vom Trail-Start.
class NearbyTreffer {
  final NearbyPlace place;
  final int fahrzeitSek;

  const NearbyTreffer({required this.place, required this.fahrzeitSek});

  /// Auf ganze Minuten gerundet, mindestens 1.
  int get fahrzeitMin => (fahrzeitSek / 60).round().clamp(1, 1 << 30);
}

/// Orte zum Trail, nach Fahrzeit sortiert, max. [nearbyMaxProTrail].
///
/// Fahrzeiten kommen aus [zeiten] (vorberechnet, App routet nie selbst).
/// Trail ohne Eintrag → leere Liste. Orte, die nicht im Katalog stehen, werden
/// übersprungen. Cap: erst max. [nearbyMaxProKategorie] pro Kategorie, Rest
/// nach Fahrzeit.
List<NearbyTreffer> nearby(
  Trail trail,
  List<NearbyPlace> catalog,
  NearbyZeiten zeiten,
) {
  final fuerTrail = zeiten[trail.id];
  if (fuerTrail == null || fuerTrail.isEmpty) return const [];
  final hits = <NearbyTreffer>[];
  for (final place in catalog) {
    final sek = fuerTrail[place.id];
    if (sek == null || sek > nearbyMaxFahrzeitSek) continue;
    hits.add(NearbyTreffer(place: place, fahrzeitSek: sek));
  }
  hits.sort(_nachFahrzeit);
  return capNearby(hits);
}

int _nachFahrzeit(NearbyTreffer a, NearbyTreffer b) {
  final c = a.fahrzeitSek.compareTo(b.fahrzeitSek);
  return c != 0 ? c : a.place.id.compareTo(b.place.id);
}

/// Kürzt [hits] (bereits nach Fahrzeit sortiert) auf [nearbyMaxProTrail].
///
/// Erster Durchlauf: nächste Treffer, solange die Kategorie unter
/// [nearbyMaxProKategorie] liegt. Zweiter Durchlauf: Rest nach Fahrzeit.
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
  picked.sort(_nachFahrzeit);
  return picked;
}

/// Anzeige: `direkt am Trail` (unter 1 Min) / `12 Min Auto`.
String formatFahrzeit(int sek) {
  if (sek < 60) return 'direkt am Trail';
  return '${(sek / 60).round()} Min Auto';
}
