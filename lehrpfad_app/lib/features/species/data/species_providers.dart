import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/supabase_client_provider.dart';
import '../../../core/sync/optimistic_id_set_notifier.dart';
import '../../../core/sync/sync_providers.dart';
import '../../trail/data/providers.dart';
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
  return ref.watch(merkmaleCatalogProvider).whenData(
    (merkmale) => {for (final m in merkmale) m.id: m},
  );
});

final speciesResolverProvider = Provider<AsyncValue<SpeciesResolver>>((ref) {
  return ref.watch(speciesCatalogProvider).whenData(SpeciesResolver.new);
});

/// Arten eines Trails in der Reihenfolge von `trail.arten`.
final trailSpeciesProvider =
    Provider.family<AsyncValue<List<Species>>, String>((ref, trailId) {
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
});

final sightingsRepositoryProvider = Provider<SightingsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final remote = client == null ? null : SupabaseSightingsRepository(client);
  final repo = HybridSightingsRepository(remote: remote);
  final engine = ref.watch(syncEngineProvider);
  if (remote != null) repo.attach(engine);
  return repo;
});

/// Gesehene Species-IDs; synced bei Login (via Sync-Lifecycle).
final sightingsProvider =
    NotifierProvider<SightingsNotifier, AsyncValue<Set<String>>>(
  SightingsNotifier.new,
);

class SightingsNotifier extends OptimisticIdSetNotifier {
  SightingsRepository get _repo => ref.read(sightingsRepositoryProvider);

  @override
  Future<Set<String>> loadIds() => _repo.getSeenIds();

  @override
  Future<void> persistChange({
    required String id,
    required bool included,
    required Set<String> next,
  }) {
    return _repo.applySeenChange(
      ids: next,
      speciesId: id,
      seen: included,
    );
  }

  Future<void> setSeen(String speciesId, bool seen) =>
      setIncluded(speciesId, seen);

  bool isSeen(String speciesId) => containsId(speciesId);
}
