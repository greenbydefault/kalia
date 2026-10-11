import '../domain/nearby.dart';

/// Liefert die vorberechneten Fahrzeiten Trail → Ort (ein Load, kein N+1).
abstract class NearbyZeitenRepository {
  Future<NearbyZeiten> getZeiten();
}

/// Seed-JSON (`{trailId: [{poi, sek}]}`) → [NearbyZeiten].
NearbyZeiten zeitenFromSeedJson(Map<String, dynamic> json) => {
  for (final e in json.entries)
    e.key: {
      for (final z in (e.value as List).cast<Map<String, dynamic>>())
        z['poi'] as String: (z['sek'] as num).toInt(),
    },
};

/// [NearbyZeiten] → Seed-JSON (für den Cache).
Map<String, dynamic> zeitenToSeedJson(NearbyZeiten zeiten) => {
  for (final e in zeiten.entries)
    e.key: [
      for (final z in e.value.entries) {'poi': z.key, 'sek': z.value},
    ],
};
