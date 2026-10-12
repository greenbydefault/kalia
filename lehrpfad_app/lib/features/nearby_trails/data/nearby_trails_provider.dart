import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../location/location_permission_controller.dart';
import '../../location/proximity.dart';
import '../../location/user_position_provider.dart';
import '../../onboarding/data/onboarding_prefs_provider.dart';
import '../../trail/data/providers.dart';
import '../../trail/domain/eignung_score.dart';
import '../../trail/domain/trail.dart';

/// Wie viele Wege die Nähe-Liste zeigt.
const nearbyTrailCount = 4;

/// Bis hierhin stehen passende Wege vor unpassenden. Weiter weg zählt
/// nur die Entfernung, sonst verdrängt ein ferner Treffer die nächsten Wege.
const matchPreferenceKm = 25;

/// „Kurze Wege“, wenn im Onboarding niemand gewählt wurde.
const defaultShortKm = 5;

/// Filter-Chips der Nähe-Liste. Standard: alles aus dem Onboarding aktiv.
class HomeFilter {
  const HomeFilter({this.lengthOn = true, this.strollerOn = true});

  final bool lengthOn;
  final bool strollerOn;
}

final homeFilterProvider = NotifierProvider<HomeFilterNotifier, HomeFilter>(
  HomeFilterNotifier.new,
);

class HomeFilterNotifier extends Notifier<HomeFilter> {
  @override
  HomeFilter build() => const HomeFilter();

  void toggleLength() => state = HomeFilter(
    lengthOn: !state.lengthOn,
    strollerOn: state.strollerOn,
  );

  void toggleStroller() => state = HomeFilter(
    lengthOn: state.lengthOn,
    strollerOn: !state.strollerOn,
  );
}

/// Kinderwagen-Näherung aus Tags und Barrierefreiheit (kein eigenes Feld).
bool isStrollerFriendly(Trail t) {
  final tags = t.alleTags;
  if (tags.contains('kinderwagentauglich') ||
      tags.contains('rollstuhltauglich')) {
    return true;
  }
  return scoreEignungen(t).barriere.level >= 4;
}

class NearbyTrailEntry {
  const NearbyTrailEntry({
    required this.trail,
    required this.matches,
    this.distanceM,
    this.hints = const [],
  });

  final Trail trail;

  /// Erfüllt alle aktiven Filter.
  final bool matches;

  /// Luftlinie Anker → Start, `null` ohne Anker.
  final double? distanceM;

  /// Weiche Filter: warum der Weg nicht passt. Die Liste bleibt trotzdem da.
  final List<String> hints;
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

/// Auswahl für die Nähe-Liste. Innerhalb von [matchPreferenceKm] passende
/// Wege vor unpassenden, jeweils nach Entfernung. Darüber nur die Entfernung.
/// Ohne Anker: passende zuerst. Nie leer, solange der Katalog Wege hat.
List<NearbyTrailEntry> selectNearbyTrails(
  List<Trail> trails, {
  required int? maxKm,
  required bool stroller,
  required bool lengthOn,
  required bool strollerOn,
  required LatLng? anchor,
  int limit = nearbyTrailCount,
}) {
  final cap = maxKm ?? defaultShortKm;
  final entries = <NearbyTrailEntry>[
    for (final t in trails)
      () {
        final lengthOk = !lengthOn || t.isFlaeche || t.laengeKm <= cap;
        final strollerOk = !(stroller && strollerOn) || isStrollerFriendly(t);
        return NearbyTrailEntry(
          trail: t,
          matches: lengthOk && strollerOk,
          distanceM: anchor == null ? null : distanceToStartM(t, anchor),
          hints: [
            if (!lengthOk) 'länger als $cap km',
            if (!strollerOk) 'nicht kinderwagentauglich',
          ],
        );
      }(),
  ];
  int byDistance(NearbyTrailEntry a, NearbyTrailEntry b) {
    final da = a.distanceM;
    final db = b.distanceM;
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    return da.compareTo(db);
  }

  final preferenceM = matchPreferenceKm * 1000.0;
  bool near(NearbyTrailEntry e) =>
      e.distanceM != null && e.distanceM! <= preferenceM;
  entries.sort((a, b) {
    if (anchor == null) {
      if (a.matches != b.matches) return a.matches ? -1 : 1;
      return byDistance(a, b);
    }
    if (near(a) && near(b) && a.matches != b.matches) {
      return a.matches ? -1 : 1;
    }
    return byDistance(a, b);
  });
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

/// `null` solange die Trails laden.
final nearbyTrailEntriesProvider = Provider<List<NearbyTrailEntry>?>((ref) {
  final trails = ref.watch(trailsProvider).asData?.value;
  if (trails == null) return null;
  final prefs = ref.watch(onboardingPrefsValueProvider);
  final filter = ref.watch(homeFilterProvider);
  return selectNearbyTrails(
    trails,
    maxKm: prefs.maxLaengeKm,
    stroller: prefs.stroller,
    lengthOn: filter.lengthOn,
    strollerOn: filter.strollerOn,
    anchor: ref.watch(mapAnchorProvider),
  );
});
