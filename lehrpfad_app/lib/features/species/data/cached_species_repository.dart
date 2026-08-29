import 'dart:convert';

import '../../../core/cache/catalog_cache.dart';
import '../../../core/cache/catalog_cache_platform.dart';
import '../../../core/cache/catalog_fetch.dart';
import '../domain/merkmal.dart';
import '../domain/species.dart';
import 'seed_species_repository.dart';
import 'species_repository.dart';

/// Remote → CatalogCache → Seed-Fallback (wie Trails).
class CachedSpeciesRepository implements SpeciesRepository {
  CachedSpeciesRepository(
    this._remote, {
    SpeciesRepository? fallback,
    CatalogCache? cache,
  }) : _fallback = fallback ?? SeedSpeciesRepository(),
       _cache = cache ?? createCatalogCache();

  final SpeciesRepository _remote;
  final SpeciesRepository _fallback;
  final CatalogCache _cache;

  static const catalogKey = 'species_cache';
  static const merkmaleKey = 'merkmale_cache';

  @override
  Future<List<Species>> getCatalog() => loadCatalog(
    cache: _cache,
    key: catalogKey,
    remote: _remote.getCatalog,
    encode: (catalog) => jsonEncode(catalog.map((s) => s.toJson()).toList()),
    decode: (raw) async {
      final json = jsonDecode(raw) as List;
      return json
          .map((e) => Species.fromJson(e as Map<String, dynamic>))
          .toList();
    },
    seed: _fallback.getCatalog,
  );

  @override
  Future<List<Merkmal>> getMerkmale() => loadCatalog(
    cache: _cache,
    key: merkmaleKey,
    remote: _remote.getMerkmale,
    encode: (merkmale) => jsonEncode(merkmale.map((m) => m.toJson()).toList()),
    decode: (raw) async {
      final json = jsonDecode(raw) as List;
      return json
          .map((e) => Merkmal.fromJson(e as Map<String, dynamic>))
          .toList();
    },
    seed: _fallback.getMerkmale,
  );
}
