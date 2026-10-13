import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../onboarding/data/onboarding_prefs_provider.dart';
import '../trail/data/providers.dart';
import '../trail/domain/catalog_filter.dart';
import '../trail/domain/trail.dart';
import 'home_filter.dart';
import 'user_position_provider.dart';

/// Typ × Umkreis × Länge × Kinderwagen. Einzige gefilterte Menge für Karte
/// und „Nächste Wege“. `null` solange die Trails noch laden.
final visibleTrailsProvider = Provider<List<Trail>?>((ref) {
  final trails = ref.watch(trailsProvider).asData?.value;
  if (trails == null) return null;
  final prefs = ref.watch(onboardingPrefsValueProvider);
  final home = ref.watch(homeFilterProvider);
  return filterCatalog(
    trails,
    typ: ref.watch(mapTypFilterProvider),
    radius: ref.watch(effectiveMapRadiusProvider),
    anchor: ref.watch(mapAnchorProvider),
    maxKm: prefs.maxLaengeKm,
    lengthOn: home.lengthOn,
    strollerOn: prefs.stroller && home.strollerOn,
  );
});
