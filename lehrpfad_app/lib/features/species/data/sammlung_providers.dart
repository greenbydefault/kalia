import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/cache/prefs_store.dart';
import '../../nearby_trails/data/karte_state.dart';
import '../../nearby_trails/domain/karte_logik.dart';
import '../../trail/data/providers.dart';
import '../../trail/domain/trail.dart';
import '../domain/sammlung_ansicht.dart';
import '../domain/species.dart';
import 'species_providers.dart';

const _kategorieKey = 'sammlung_kategorie';
const sammlungKategorien = ['flora', 'fauna', 'geraete'];

/// Aktive Kategorie. Default Fauna, zuletzt gewählte wird gemerkt.
final sammlungKategorieProvider =
    NotifierProvider<SammlungKategorieNotifier, String>(
      SammlungKategorieNotifier.new,
    );

class SammlungKategorieNotifier extends Notifier<String> {
  final _prefs = PrefsStore();
  bool _gewaehlt = false;

  @override
  String build() {
    _lade();
    return 'fauna';
  }

  Future<void> _lade() async {
    try {
      final raw = await _prefs.readString(_kategorieKey);
      if (!_gewaehlt && raw != null && sammlungKategorien.contains(raw)) {
        state = raw;
      }
    } catch (_) {}
  }

  /// Wechsel setzt den Gruppen-Filter zurück und merkt die Wahl.
  void waehle(String kategorie) {
    _gewaehlt = true;
    if (kategorie == state) return;
    state = kategorie;
    ref.read(sammlungGruppeProvider.notifier).waehle(null);
    _prefs.writeString(_kategorieKey, kategorie).catchError((_) {});
  }
}

/// Gruppen-Filter (`null` = Alle).
final sammlungGruppeProvider =
    NotifierProvider<SammlungGruppeNotifier, String?>(
      SammlungGruppeNotifier.new,
    );

class SammlungGruppeNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void waehle(String? gruppe) => state = gruppe;
}

/// Art, die gerade im Sheet freigeschaltet wurde; die Kachel wird
/// hervorgehoben, bis das Sheet schließt.
final sammlungFrischProvider =
    NotifierProvider<SammlungFrischNotifier, String?>(
      SammlungFrischNotifier.new,
    );

class SammlungFrischNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setze(String? speciesId) => state = speciesId;
}

/// Ansicht der aktiven Kategorie mit aktuellem Filter.
final sammlungAnsichtProvider = Provider<AsyncValue<SammlungAnsicht>>((ref) {
  final katalog = ref.watch(speciesCatalogProvider);
  final funde = ref.watch(fundeProvider);
  final kategorie = ref.watch(sammlungKategorieProvider);
  final gruppe = ref.watch(sammlungGruppeProvider);
  if (katalog.hasError) return AsyncError(katalog.error!, katalog.stackTrace!);
  final k = katalog.asData?.value;
  if (k == null) return const AsyncLoading();
  return AsyncData(
    SammlungAnsicht.berechne(
      katalog: k,
      funde: funde.asData?.value ?? const {},
      kategorie: kategorie,
      gruppe: gruppe,
      now: DateTime.now(),
    ),
  );
});

/// Ein Pfad, auf dem eine Art vorkommt, mit geschätzter Anfahrt.
class Chance {
  const Chance({required this.trail, this.minuten});

  final Trail trail;

  /// `null` ohne Standort/Bezugspunkt.
  final int? minuten;
}

/// Offener Eintrag mit bestem Pfad in der Nähe.
class NaehTreffer {
  const NaehTreffer({required this.species, required this.chance});

  final Species species;
  final Chance chance;
}

/// Art-ID → Trails, auf denen sie vorkommt (über `trail.arten`).
final speciesTrailsProvider = Provider<Map<String, List<Trail>>>((ref) {
  final trails = ref.watch(trailsProvider).asData?.value;
  final resolver = ref.watch(speciesResolverProvider).asData?.value;
  if (trails == null || resolver == null) return const {};
  final out = <String, List<Trail>>{};
  for (final t in trails) {
    for (final s in resolver.resolve(t.arten)) {
      (out[s.id] ??= []).add(t);
    }
  }
  return out;
});

/// Pfade zur Art, nach Anfahrt sortiert (ohne [bezug]: nach Name).
List<Chance> chancenFuer(List<Trail> trails, LatLng? bezug) {
  final out = <Chance>[
    for (final t in trails)
      Chance(
        trail: t,
        minuten: () {
          final start = t.startOrNull;
          if (bezug == null || start == null) return null;
          return schaetzeAnfahrtMin(bezug, start);
        }(),
      ),
  ];
  out.sort((a, b) {
    final ma = a.minuten;
    final mb = b.minuten;
    if (ma != null && mb != null && ma != mb) return ma.compareTo(mb);
    if (ma == null && mb != null) return 1;
    if (ma != null && mb == null) return -1;
    return a.trail.name.compareTo(b.trail.name);
  });
  return out;
}

/// Pfade zu einer Art für das Detail-Sheet.
final chancenFuerProvider = Provider.family<List<Chance>, String>((ref, id) {
  final trails = ref.watch(speciesTrailsProvider)[id] ?? const <Trail>[];
  return chancenFuer(trails, ref.watch(bezugCoordsProvider));
});

/// „Noch offen in eurer Nähe“: bis zu [max] offene Einträge der aktiven
/// Kategorie, kürzeste Anfahrt zuerst. Leer ohne Bezugspunkt.
List<NaehTreffer> naehTreffer({
  required List<Species> offen,
  required Map<String, List<Trail>> speciesTrails,
  required LatLng? bezug,
  int max = 2,
}) {
  if (bezug == null) return const [];
  final out = <NaehTreffer>[];
  for (final s in offen) {
    final trails = speciesTrails[s.id];
    if (trails == null || trails.isEmpty) continue;
    final beste = chancenFuer(trails, bezug).first;
    if (beste.minuten == null) continue;
    out.add(NaehTreffer(species: s, chance: beste));
  }
  out.sort((a, b) => a.chance.minuten!.compareTo(b.chance.minuten!));
  return out.take(max).toList();
}

final sammlungNaeheProvider = Provider<List<NaehTreffer>>((ref) {
  final ansicht = ref.watch(sammlungAnsichtProvider).asData?.value;
  if (ansicht == null) return const [];
  return naehTreffer(
    offen: ansicht.offen,
    speciesTrails: ref.watch(speciesTrailsProvider),
    bezug: ref.watch(bezugCoordsProvider),
  );
});

/// Trail-ID → Name, für „Entdeckt am …“ und Zuletzt-Liste.
final trailNamenProvider = Provider<Map<String, String>>((ref) {
  final trails = ref.watch(trailsProvider).asData?.value ?? const <Trail>[];
  return {for (final t in trails) t.id: t.name};
});
