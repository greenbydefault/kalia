import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../location/location_permission_controller.dart';
import '../../location/proximity.dart';
import '../../location/user_position_provider.dart';
import '../../location/visible_trails_provider.dart';
import '../../trail/domain/trail.dart';

/// Wie viele Wege die Nähe-Liste zeigt.
const nearbyTrailCount = 4;

class NearbyTrailEntry {
  const NearbyTrailEntry({required this.trail, this.distanceM});

  final Trail trail;

  /// Luftlinie Anker → Start, `null` ohne Anker.
  final double? distanceM;
}

enum NearbyAnchorState { ready, locating, unavailable }

/// Ohne Anker keine Entfernungsliste. Standort an und noch kein Fehler: warten.
NearbyAnchorState resolveNearbyAnchor({
  required bool hasAnchor,
  required bool locationKnown,
  required bool locationOn,
  required bool loading,
  required bool hasError,
}) {
  if (hasAnchor) return NearbyAnchorState.ready;
  if (!locationKnown) return NearbyAnchorState.locating;
  if (locationOn && (!hasError || loading)) return NearbyAnchorState.locating;
  return NearbyAnchorState.unavailable;
}

/// Rang der Nähe-Liste: die [limit] nächsten der bereits gefilterten
/// [trails] (siehe `filterCatalog`), nach Entfernung sortiert
/// (ohne Anker unsortiert in Katalogreihenfolge).
List<NearbyTrailEntry> rankNearbyTrails(
  List<Trail> trails, {
  required LatLng? anchor,
  int limit = nearbyTrailCount,
}) {
  final entries = <NearbyTrailEntry>[
    for (final t in trails)
      NearbyTrailEntry(
        trail: t,
        distanceM: anchor == null ? null : distanceToStartM(t, anchor),
      ),
  ];
  int byDistance(NearbyTrailEntry a, NearbyTrailEntry b) {
    final da = a.distanceM;
    final db = b.distanceM;
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    return da.compareTo(db);
  }

  entries.sort(byDistance);
  return entries.take(limit).toList();
}

final nearbyAnchorStateProvider = Provider<NearbyAnchorState>((ref) {
  final pos = ref.watch(userPositionProvider);
  return resolveNearbyAnchor(
    hasAnchor: ref.watch(mapAnchorProvider) != null,
    locationKnown: ref.watch(mapLocationResolvedProvider),
    locationOn: ref.watch(mapLocationEnabledProvider),
    loading: pos.loading,
    hasError: pos.lastError != null,
  );
});

/// Die nächsten Wege aus `visibleTrailsProvider`. `null` solange die Trails
/// laden.
final nearbyTrailEntriesProvider = Provider<List<NearbyTrailEntry>?>((ref) {
  final visible = ref.watch(visibleTrailsProvider);
  if (visible == null) return null;
  return rankNearbyTrails(visible, anchor: ref.watch(mapAnchorProvider));
});
