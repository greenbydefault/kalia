import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../location/proximity.dart';
import '../../location/user_position_provider.dart';
import '../../onboarding/data/onboarding_prefs_provider.dart';
import '../../trail/data/providers.dart';
import '../../trail/domain/eignung_score.dart';
import '../../trail/domain/trail.dart';

/// Wie viele Wege die Nähe-Liste zeigt.
const nearbyTrailCount = 4;

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
  });

  final Trail trail;

  /// Erfüllt alle aktiven Filter.
  final bool matches;

  /// Luftlinie Anker → Trail, `null` ohne Anker.
  final double? distanceM;
}

/// Auswahl für die Nähe-Liste: passende Wege zuerst, dann nach Entfernung.
/// Nie leer, solange der Katalog Wege hat.
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
      NearbyTrailEntry(
        trail: t,
        matches:
            (!lengthOn || t.isFlaeche || t.laengeKm <= cap) &&
            (!(stroller && strollerOn) || isStrollerFriendly(t)),
        distanceM: anchor == null ? null : distanceToTrailM(t, anchor),
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

  entries.sort((a, b) {
    if (a.matches != b.matches) return a.matches ? -1 : 1;
    return byDistance(a, b);
  });
  return entries.take(limit).toList();
}

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
