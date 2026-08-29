import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/supabase_config.dart';
import '../core/sync/sync_providers.dart';
import '../features/auth/data/auth_providers.dart';
import '../features/species/data/species_providers.dart';
import '../features/trail_progress/data/trail_list_providers.dart';
import '../features/trail_progress/data/trail_progress_providers.dart';

/// Sync-Lebenszyklus: hält die Engine samt Repos am Leben,
/// flusht die Queue beim App-Start und orchestriert den Login-Merge.
///
/// Wiring (attach) liegt in den Repository-Providern, nicht hier.
/// Muss einmalig von einem sichtbaren Widget gewatched werden (AppShell).
final syncLifecycleProvider = Provider<void>((ref) {
  if (!SupabaseConfig.isConfigured) return;
  final engine = ref.watch(syncEngineProvider);

  // Repos keep-alive, damit attach() vor flush/login steht.
  ref.watch(trailProgressRepositoryProvider);
  ref.watch(trailListRepositoryProvider);
  ref.watch(sightingsRepositoryProvider);

  unawaited(engine.flush());

  ref.listen(authStateProvider, (prev, next) async {
    final user = next.asData?.value;
    final hadUser = prev?.asData?.value != null;
    if (user == null || hadUser) return;
    await engine.mergeAllOnLogin();
    ref.invalidate(trailBookmarksProvider);
    ref.invalidate(trailCompletionsProvider);
    ref.invalidate(activeWalkProvider);
    ref.invalidate(trailListsProvider);
    ref.invalidate(sightingsProvider);
  });
});
