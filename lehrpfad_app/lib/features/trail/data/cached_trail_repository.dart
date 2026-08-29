import 'dart:convert';

import 'package:latlong2/latlong.dart';

import '../../../core/cache/catalog_cache.dart';
import '../../../core/cache/catalog_cache_platform.dart';
import '../../../core/cache/catalog_fetch.dart';
import '../domain/trail.dart';
import 'seed_trail_repository.dart';
import 'trail_hero_assets.dart';
import 'trail_repository.dart';

/// Decorator um ein Remote-Repository: unfiltered Catalog → Cache,
/// bei Offline/Fehler Cache, sonst Seed.
class CachedTrailRepository implements TrailRepository {
  CachedTrailRepository(
    this._remote, {
    TrailRepository? fallback,
    CatalogCache? cache,
  }) : _fallback = fallback ?? SeedTrailRepository(),
       _cache = cache ?? createCatalogCache();

  final TrailRepository _remote;
  final TrailRepository _fallback;
  final CatalogCache _cache;

  static const cacheKey = 'trails_cache';

  @override
  Future<List<Trail>> getTrails({LatLng? near, double? radiusKm}) {
    final filtered = near != null || radiusKm != null;
    return loadCatalog(
      cache: _cache,
      key: cacheKey,
      skipWrite: filtered,
      remote: () => _remote.getTrails(near: near, radiusKm: radiusKm),
      encode: (trails) => jsonEncode(trails.map((t) => t.toJson()).toList()),
      decode: (raw) async {
        final json = jsonDecode(raw) as List;
        final trails = <Trail>[];
        for (final t in json) {
          final map = t as Map<String, dynamic>;
          await attachHeroBilder(map);
          trails.add(Trail.fromJson(map));
        }
        return trails;
      },
      seed: () => _fallback.getTrails(),
    );
  }
}
