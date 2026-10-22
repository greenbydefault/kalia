/// Offline-First: lokaler Katalog, Versionsabgleich, Asset-Resolver.
///
/// Öffentliche Schnittstelle. Phase 1: Katalog (drift), Seed-Import, Sync,
/// Resolver, Konnektivität. Download-Engine, Tiles, Outbox folgen später.
library;

export 'catalog/catalog_repository.dart';
export 'catalog/catalog_sync.dart' show SyncReport, diffVersions;
export 'catalog/seed_loader.dart';
export 'models/asset_ref.dart';
export 'models/trail_index_entry.dart';
export 'offline_config.dart';
export 'providers/catalog_providers.dart';
export 'providers/connectivity_provider.dart';
export 'resolver/asset_resolver.dart';
export 'storage/file_store.dart';
