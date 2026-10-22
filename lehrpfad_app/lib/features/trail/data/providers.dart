import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/supabase_client_provider.dart';
import '../../offline/providers/catalog_providers.dart';
import '../domain/trail.dart';
import 'cached_trail_repository.dart';
import 'seed_trail_repository.dart';
import 'supabase_trail_repository.dart';
import 'trail_repository.dart';

/// Aktive Datenquelle. Mit Client: Supabase + CatalogCache
/// (Seed als Erststart-Fallback). Ohne Client: nur der lokale Seed.
final trailRepositoryProvider = Provider<TrailRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client != null) {
    return CachedTrailRepository(SupabaseTrailRepository(client));
  }
  return SeedTrailRepository();
});

final _trailsFastProvider = FutureProvider<List<Trail>>((ref) async {
  final repo = ref.watch(trailRepositoryProvider);
  if (repo is CachedTrailRepository) return repo.loadFast();
  return repo.getTrails();
});

final _trailsRemoteProvider = FutureProvider<List<Trail>>((ref) async {
  final repo = ref.watch(trailRepositoryProvider);
  if (repo is! CachedTrailRepository) return const [];
  return repo.loadRemote();
});

/// Nativ mit Backend: der lokale Katalog (drift). Wartet nur auf den
/// Seed-Import, nie aufs Netz; der Sync schreibt in die DB, der Stream folgt.
final _catalogTrailsProvider = StreamProvider<List<Trail>>((ref) async* {
  final catalog = ref.watch(catalogRepositoryProvider)!;
  await ref.watch(catalogBootProvider.future);
  yield* catalog.watchTrails();
});

/// Nativ: lokaler Katalog. Web und Entwicklung ohne Backend: Cache oder Seed
/// sofort, Supabase danach.
final trailsProvider = Provider<AsyncValue<List<Trail>>>((ref) {
  if (ref.watch(catalogRepositoryProvider) != null) {
    return ref.watch(_catalogTrailsProvider);
  }
  final repo = ref.watch(trailRepositoryProvider);
  final fast = ref.watch(_trailsFastProvider);
  if (repo is! CachedTrailRepository) return fast;
  // Remote erst danach: sonst belegen die Hero-Requests die Verbindungen,
  // und der Seed kommt nicht durch.
  if (!fast.hasValue) {
    return fast.isLoading ? const AsyncLoading() : fast;
  }
  final remote = ref.watch(_trailsRemoteProvider);
  if (remote.hasValue) return remote;
  return fast;
});

/// Aktuell ausgewählter Trail (öffnet das Detail-Sheet).
final selectedTrailProvider = NotifierProvider<SelectedTrailNotifier, Trail?>(
  SelectedTrailNotifier.new,
);

class SelectedTrailNotifier extends Notifier<Trail?> {
  @override
  Trail? build() => null;

  void select(Trail trail) {
    state = trail;
  }

  void clear() {
    state = null;
  }
}

/// Einmaliges Kamera-Ziel (Trail-ID) für externe Einstiege wie
/// „Meine Routen“. Map-Taps setzen es nie — Tap bewegt die Kamera
/// nicht. Pending löst den langen Flug auf die Geometrie aus.
/// Wird vom `MapCameraController` nach Annahme verbraucht.
final pendingCameraTrailProvider =
    NotifierProvider<PendingCameraTrailNotifier, String?>(
      PendingCameraTrailNotifier.new,
    );

class PendingCameraTrailNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void request(String trailId) {
    state = trailId;
  }

  void clear() {
    state = null;
  }
}

/// Aktiver Map-Typ-Filter. `null` = alle Typen sichtbar.
final mapTypFilterProvider = NotifierProvider<MapTypFilterNotifier, String?>(
  MapTypFilterNotifier.new,
);

class MapTypFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String typ) {
    state = typ;
  }

  void clear() {
    state = null;
  }
}
