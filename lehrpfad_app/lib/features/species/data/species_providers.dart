import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../auth/data/auth_providers.dart';
import '../../trail/data/providers.dart';
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
  if (SupabaseConfig.isConfigured) {
    return CachedSpeciesRepository(
      SupabaseSpeciesRepository(Supabase.instance.client),
    );
  }
  return SeedSpeciesRepository();
});

final speciesCatalogProvider = FutureProvider<List<Species>>((ref) {
  return ref.watch(speciesRepositoryProvider).getCatalog();
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
  if (SupabaseConfig.isConfigured) {
    return HybridSightingsRepository(
      remote: SupabaseSightingsRepository(Supabase.instance.client),
    );
  }
  return HybridSightingsRepository();
});

/// Gesehene Species-IDs; synced bei Login.
final sightingsProvider =
    NotifierProvider<SightingsNotifier, AsyncValue<Set<String>>>(
  SightingsNotifier.new,
);

class SightingsNotifier extends Notifier<AsyncValue<Set<String>>> {
  @override
  AsyncValue<Set<String>> build() {
    // Auth-Wechsel: nach Login mergen
    if (SupabaseConfig.isConfigured) {
      ref.listen(authStateProvider, (prev, next) {
        final user = next.asData?.value;
        final hadUser = prev?.asData?.value != null;
        if (user != null && !hadUser) {
          _mergeOnLogin();
        }
      });
    }
    _load();
    return const AsyncLoading();
  }

  SightingsRepository get _repo => ref.read(sightingsRepositoryProvider);

  Future<void> _load() async {
    try {
      final ids = await _repo.getSeenIds();
      state = AsyncData(ids);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> _mergeOnLogin() async {
    final remote = SupabaseSightingsRepository(Supabase.instance.client);
    try {
      final remoteIds = await remote.fetchSeenIds();
      final merged = await _repo.mergeWithRemote(remoteIds);
      state = AsyncData(merged);
    } catch (_) {
      // Offline nach Login: lokale Daten behalten
    }
  }

  Future<void> setSeen(String speciesId, bool seen) async {
    final previous = state.asData?.value ?? {};
    final next = {...previous};
    if (seen) {
      next.add(speciesId);
    } else {
      next.remove(speciesId);
    }
    state = AsyncData(next);
    try {
      await _repo.applySeenChange(
        ids: next,
        speciesId: speciesId,
        seen: seen,
      );
    } catch (_) {
      state = AsyncData(previous);
    }
  }

  bool isSeen(String speciesId) =>
      state.asData?.value.contains(speciesId) ?? false;
}
