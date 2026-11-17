import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/supabase_client_provider.dart';
import '../../../core/sync/sync_providers.dart';
import '../../offline/providers/catalog_providers.dart';
import '../../trail/data/providers.dart';
import '../domain/fund.dart';
import '../domain/merkmal.dart';
import '../domain/species.dart';
import 'cached_species_repository.dart';
import 'hybrid_sightings_repository.dart';
import 'seed_species_repository.dart';
import 'sightings_repository.dart';
import 'species_repository.dart';
import 'species_resolver.dart';
import 'supabase_sightings_repository.dart';
import 'supabase_species_repository.dart';

final speciesRepositoryProvider = Provider<SpeciesRepository>((ref) {
  final offline = ref.watch(offlineSpeciesRepositoryProvider);
  if (offline != null) return offline;
  final client = ref.watch(supabaseClientProvider);
  if (client != null) {
    return CachedSpeciesRepository(SupabaseSpeciesRepository(client));
  }
  return SeedSpeciesRepository();
});

final speciesCatalogProvider = FutureProvider<List<Species>>((ref) {
  return ref.watch(speciesRepositoryProvider).getCatalog();
});

final merkmaleCatalogProvider = FutureProvider<List<Merkmal>>((ref) {
  return ref.watch(speciesRepositoryProvider).getMerkmale();
});

/// Merkmale-Lookup: ID → Merkmal.
final merkmaleByIdProvider = Provider<AsyncValue<Map<String, Merkmal>>>((ref) {
  return ref
      .watch(merkmaleCatalogProvider)
      .whenData((merkmale) => {for (final m in merkmale) m.id: m});
});

final speciesResolverProvider = Provider<AsyncValue<SpeciesResolver>>((ref) {
  return ref.watch(speciesCatalogProvider).whenData(SpeciesResolver.new);
});

/// Arten eines Trails in der Reihenfolge von `trail.arten`.
final trailSpeciesProvider = Provider.family<AsyncValue<List<Species>>, String>(
  (ref, trailId) {
    final trailsAsync = ref.watch(trailsProvider);
    final resolverAsync = ref.watch(speciesResolverProvider);
    return trailsAsync.when(
      loading: () => const AsyncLoading(),
      error: AsyncError.new,
      data: (trails) {
        final match = trails.where((t) => t.id == trailId);
        if (match.isEmpty) {
          return AsyncError(
            StateError('Trail $trailId fehlt'),
            StackTrace.current,
          );
        }
        final trail = match.first;
        return resolverAsync.when(
          loading: () => const AsyncLoading(),
          error: AsyncError.new,
          data: (resolver) => AsyncData(resolver.resolve(trail.arten)),
        );
      },
    );
  },
);

final sightingsRepositoryProvider = Provider<SightingsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final remote = client == null ? null : SupabaseSightingsRepository(client);
  final repo = HybridSightingsRepository(remote: remote);
  final engine = ref.watch(syncEngineProvider);
  if (remote != null) repo.attach(engine);
  return repo;
});

/// Funde (Species-ID → Fund); synced bei Login (via Sync-Lifecycle).
final fundeProvider =
    NotifierProvider<FundeNotifier, AsyncValue<Map<String, Fund>>>(
      FundeNotifier.new,
    );

/// Gesehene Species-IDs, abgeleitet aus [fundeProvider].
final sightingsProvider = Provider<AsyncValue<Set<String>>>((ref) {
  return ref.watch(fundeProvider).whenData((m) => m.keys.toSet());
});

class FundeNotifier extends Notifier<AsyncValue<Map<String, Fund>>> {
  SightingsRepository get _repo => ref.read(sightingsRepositoryProvider);

  @override
  AsyncValue<Map<String, Fund>> build() {
    _load();
    return const AsyncLoading();
  }

  Future<void> _load() async {
    try {
      state = AsyncData(await _repo.getFunde());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Map<String, Fund> get _aktuell => state.asData?.value ?? const {};

  bool istGefunden(String speciesId) => _aktuell.containsKey(speciesId);

  /// Legt den Fund an (Datum = jetzt). Existiert er schon, bleibt er.
  Future<Fund> entdecke(String speciesId, {String? trailId}) async {
    final vorhanden = _aktuell[speciesId];
    if (vorhanden != null) return vorhanden;
    final fund = Fund(
      speciesId: speciesId,
      entdecktAm: DateTime.now().toUtc(),
      trailId: trailId,
    );
    await _schreibe(speciesId, fund);
    return fund;
  }

  /// Entfernt den Fund und liefert ihn für „Rückgängig“ zurück.
  Future<Fund?> entferne(String speciesId) async {
    final vorhanden = _aktuell[speciesId];
    if (vorhanden == null) return null;
    await _schreibe(speciesId, null);
    return vorhanden;
  }

  /// Stellt einen entfernten Fund samt Datum, Pfad und Wer wieder her.
  Future<void> wiederherstellen(Fund fund) => _schreibe(fund.speciesId, fund);

  /// Setzt „Wer hat’s entdeckt?“, `null` hebt die Auswahl auf.
  Future<void> setzeVon(String speciesId, EntdecktVon? von) async {
    final vorhanden = _aktuell[speciesId];
    if (vorhanden == null) return;
    await _schreibe(speciesId, vorhanden.withVon(von));
  }

  Future<void> _schreibe(String speciesId, Fund? fund) async {
    final previous = _aktuell;
    final next = {...previous};
    if (fund == null) {
      next.remove(speciesId);
    } else {
      next[speciesId] = fund;
    }
    state = AsyncData(next);
    try {
      await _repo.applyChange(funde: next, speciesId: speciesId);
    } catch (_) {
      state = AsyncData(previous);
    }
  }
}
