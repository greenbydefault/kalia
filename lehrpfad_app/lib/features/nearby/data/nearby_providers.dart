import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/supabase_client_provider.dart';
import '../../trail/data/providers.dart';
import '../domain/nearby.dart';
import '../domain/nearby_place.dart';
import 'cached_nearby_repository.dart';
import 'nearby_repository.dart';
import 'seed_nearby_repository.dart';
import 'supabase_nearby_repository.dart';

final nearbyRepositoryProvider = Provider<NearbyRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client != null) {
    return CachedNearbyRepository(SupabaseNearbyRepository(client));
  }
  return SeedNearbyRepository();
});

final nearbyCatalogProvider = FutureProvider<List<NearbyPlace>>((ref) {
  return ref.watch(nearbyRepositoryProvider).getCatalog();
});

/// Orte im Umkreis eines Trails, distanzsortiert.
final nearbyPlacesProvider =
    Provider.family<AsyncValue<List<NearbyTreffer>>, String>((ref, trailId) {
      final trailsAsync = ref.watch(trailsProvider);
      final catalogAsync = ref.watch(nearbyCatalogProvider);
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
          return catalogAsync.when(
            loading: () => const AsyncLoading(),
            error: AsyncError.new,
            data: (catalog) => AsyncData(nearby(match.first, catalog)),
          );
        },
      );
    });

/// Ausgewählter Ort auf der Karte (Peek). Unabhängig von [selectedTrailProvider].
final selectedNearbyPlaceProvider =
    NotifierProvider<SelectedNearbyPlaceNotifier, NearbyTreffer?>(
      SelectedNearbyPlaceNotifier.new,
    );

class SelectedNearbyPlaceNotifier extends Notifier<NearbyTreffer?> {
  @override
  NearbyTreffer? build() => null;

  void select(NearbyTreffer treffer) {
    state = treffer;
  }

  void clear() {
    state = null;
  }
}
