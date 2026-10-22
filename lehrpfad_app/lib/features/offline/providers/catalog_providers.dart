import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/supabase_client_provider.dart';
import '../../../core/config/supabase_config.dart';
import '../../species/data/seed_species_repository.dart';
import '../catalog/catalog_repository.dart';
import '../catalog/catalog_sync.dart';
import '../catalog/seed_loader.dart';
import '../offline_config.dart';
import '../resolver/asset_resolver.dart';
import '../storage/file_store.dart';
import '../storage/offline_database.dart';
import '../storage/offline_platform.dart' as platform;

/// Lokaler Katalog nur nativ **und** mit Backend. Sonst `null`: Web und
/// Entwicklung ohne Defines laufen wie bisher über Cache bzw. Seed.
final offlineDatabaseProvider = Provider<OfflineDatabase?>((ref) {
  if (!platform.offlineStorageSupported || !SupabaseConfig.isConfigured) {
    return null;
  }
  final db = platform.openOfflineDatabase();
  ref.onDispose(db.close);
  return db;
});

final seedLoaderProvider = Provider<SeedLoader>((ref) => SeedLoader());

/// Katalog bereit: Seed ist importiert (Erststart bzw. App-Update).
final catalogBootProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(offlineDatabaseProvider);
  if (db == null) return;
  await ref.watch(seedLoaderProvider).importInto(db);
});

final catalogRepositoryProvider = Provider<CatalogRepository?>((ref) {
  final db = ref.watch(offlineDatabaseProvider);
  return db == null ? null : DriftCatalogRepository(db);
});

/// Offline-fähiges Artenrepo, wenn der lokale Katalog aktiv ist.
final offlineSpeciesRepositoryProvider = Provider<OfflineSpeciesRepository?>((
  ref,
) {
  final catalog = ref.watch(catalogRepositoryProvider);
  if (catalog == null) return null;
  return OfflineSpeciesRepository(
    catalog,
    SeedSpeciesRepository(),
    ready: ref.watch(catalogBootProvider.future),
  );
});

final fileStoreProvider = FutureProvider<FileStore>((ref) async {
  try {
    return await platform.openFileStore();
  } catch (_) {
    return const NullFileStore();
  }
});

/// trailId → imageId der gebündelten Thumbs.
final seedThumbImagesProvider = FutureProvider<Map<String, String>>((
  ref,
) async {
  try {
    return (await ref.watch(seedLoaderProvider).loadIndex()).thumbImages;
  } catch (_) {
    return const {};
  }
});

final assetResolverProvider = Provider<AssetResolver>((ref) {
  return AssetResolver(
    files: ref.watch(fileStoreProvider).asData?.value ?? const NullFileStore(),
    storageBaseUrl: SupabaseConfig.url,
    seedThumbImages:
        ref.watch(seedThumbImagesProvider).asData?.value ?? const {},
  );
});

/// Löst den Katalogabgleich aus, höchstens alle [OfflineConfig.syncMinInterval].
final catalogSyncControllerProvider = Provider<CatalogSyncController?>((ref) {
  final db = ref.watch(offlineDatabaseProvider);
  final client = ref.watch(supabaseClientProvider);
  if (db == null || client == null) return null;
  return CatalogSyncController(
    CatalogSync(SupabaseCatalogRemote(client), db),
    db,
  );
});

class CatalogSyncController {
  CatalogSyncController(this._sync, this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final CatalogSync _sync;
  final OfflineDatabase _db;
  final DateTime Function() _now;
  bool _running = false;

  /// Synct, wenn das letzte Mal länger als das Intervall her ist (oder
  /// [force]). Fehler (offline, Timeout) sind kein Problem: lokaler Stand
  /// bleibt, der nächste Auslöser versucht es wieder.
  Future<SyncReport?> maybeSync({bool force = false}) async {
    if (_running) return null;
    if (!force && !await _due()) return null;
    _running = true;
    try {
      return await _sync.run();
    } catch (e) {
      debugPrint('CatalogSync fehlgeschlagen ($e)');
      return null;
    } finally {
      _running = false;
    }
  }

  Future<bool> _due() async {
    final raw = await _db.meta(OfflineDatabase.metaLastSyncAt);
    final last = raw == null ? null : DateTime.tryParse(raw);
    return last == null ||
        _now().difference(last) >= OfflineConfig.syncMinInterval;
  }
}
