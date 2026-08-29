import 'dart:convert';

import '../../../core/cache/catalog_cache.dart';
import '../../../core/cache/catalog_cache_platform.dart';
import '../../../core/cache/catalog_fetch.dart';
import '../domain/nearby_place.dart';
import 'nearby_repository.dart';
import 'seed_nearby_repository.dart';

/// Remote → CatalogCache → Seed-Fallback (wie Trails/Species).
class CachedNearbyRepository implements NearbyRepository {
  CachedNearbyRepository(
    this._remote, {
    NearbyRepository? fallback,
    CatalogCache? cache,
  }) : _fallback = fallback ?? SeedNearbyRepository(),
       _cache = cache ?? createCatalogCache();

  final NearbyRepository _remote;
  final NearbyRepository _fallback;
  final CatalogCache _cache;

  static const catalogKey = 'pois_cache';

  @override
  Future<List<NearbyPlace>> getCatalog() => loadCatalog(
    cache: _cache,
    key: catalogKey,
    remote: _remote.getCatalog,
    encode: (catalog) => jsonEncode(catalog.map((p) => p.toJson()).toList()),
    decode: (raw) async {
      final json = jsonDecode(raw) as List;
      return json
          .map((e) => NearbyPlace.fromJson(e as Map<String, dynamic>))
          .toList();
    },
    seed: _fallback.getCatalog,
  );
}
