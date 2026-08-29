import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/supabase_client_provider.dart';
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

/// Alle verfügbaren Trails, asynchron geladen.
final trailsProvider = FutureProvider<List<Trail>>(
  (ref) => ref.watch(trailRepositoryProvider).getTrails(),
);

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
