import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../domain/trail.dart';
import 'cached_trail_repository.dart';
import 'seed_trail_repository.dart';
import 'supabase_trail_repository.dart';
import 'trail_repository.dart';

/// Aktive Datenquelle. Mit gesetzten Supabase-Defines: Supabase + Datei-Cache
/// (Seed als Erststart-Fallback). Ohne Defines: nur der lokale Seed
/// (Offline-Entwicklung, Tests per ProviderScope-Override).
final trailRepositoryProvider = Provider<TrailRepository>((ref) {
  if (SupabaseConfig.isConfigured) {
    return CachedTrailRepository(
      SupabaseTrailRepository(Supabase.instance.client),
    );
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

/// Aktiver Map-Typ-Filter. `null` = alle Typen sichtbar.
final mapTypFilterProvider =
    NotifierProvider<MapTypFilterNotifier, String?>(MapTypFilterNotifier.new);

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
