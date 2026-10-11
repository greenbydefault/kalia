import 'dart:convert';

import '../../../core/cache/catalog_cache.dart';
import '../../../core/cache/catalog_cache_platform.dart';
import '../../../core/cache/catalog_fetch.dart';
import '../domain/nearby.dart';
import 'nearby_zeiten_repository.dart';
import 'seed_nearby_zeiten_repository.dart';

/// Remote → CatalogCache → Seed-Fallback (wie [CachedNearbyRepository]).
class CachedNearbyZeitenRepository implements NearbyZeitenRepository {
  CachedNearbyZeitenRepository(
    this._remote, {
    NearbyZeitenRepository? fallback,
    CatalogCache? cache,
  }) : _fallback = fallback ?? SeedNearbyZeitenRepository(),
       _cache = cache ?? createCatalogCache();

  final NearbyZeitenRepository _remote;
  final NearbyZeitenRepository _fallback;
  final CatalogCache _cache;

  static const catalogKey = 'trail_pois_cache';

  @override
  Future<NearbyZeiten> getZeiten() => loadCatalog(
    cache: _cache,
    key: catalogKey,
    remote: () async {
      final zeiten = await _remote.getZeiten();
      // Leere Tabelle (noch nicht geseedet) wie Fehler behandeln → Cache/Seed.
      if (zeiten.isEmpty) throw StateError('trail_pois leer');
      return zeiten;
    },
    encode: (zeiten) => jsonEncode(zeitenToSeedJson(zeiten)),
    decode: (raw) async =>
        zeitenFromSeedJson(jsonDecode(raw) as Map<String, dynamic>),
    seed: _fallback.getZeiten,
  );
}
