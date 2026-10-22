import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/supabase_config.dart';
import '../core/sync/sync_providers.dart';
import '../features/auth/data/auth_providers.dart';
import '../features/offline/offline.dart';
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
  _startCatalogSync(ref);
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

/// Katalogabgleich bei App-Start, Resume und Netz-Rückkehr. Der Controller
/// drosselt auf [OfflineConfig.syncMinInterval]; gibt es keinen lokalen
/// Katalog (Web), passiert nichts.
void _startCatalogSync(Ref ref) {
  final controller = ref.watch(catalogSyncControllerProvider);
  if (controller == null) return;

  Future<void> run() async {
    final report = await controller.maybeSync();
    if (report == null || !ref.mounted) return;
    if (report.speciesFetched + report.speciesRemoved > 0) {
      ref.invalidate(speciesCatalogProvider);
    }
  }

  unawaited(
    ref.read(catalogBootProvider.future).then((_) => run(), onError: (_) {}),
  );
  final lifecycle = AppLifecycleListener(onResume: () => unawaited(run()));
  ref.onDispose(lifecycle.dispose);
  ref.listen(isOnlineProvider, (prev, next) {
    if (next && prev == false) unawaited(run());
  });
}
