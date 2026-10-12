import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
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

  /// Cache, sonst Seed ohne Hero-Credits. Blockiert nicht aufs Netz.
  Future<List<Trail>> loadFast() async {
    final sw = Stopwatch()..start();
    try {
      final raw = await _cache.read(cacheKey);
      if (raw != null && raw.isNotEmpty) {
        final trails = _decode(raw);
        debugPrint(
          'trails cache ${trails.length} ${sw.elapsedMilliseconds} ms',
        );
        return trails;
      }
    } catch (e) {
      debugPrint('trails cache skip ($e)');
    }
    if (_fallback is SeedTrailRepository) {
      return _fallback.loadBodies();
    }
    return _fallback.getTrails();
  }

  /// Supabase inkl. Credits. Schreibt den Cache, wenn die UI Luft hat.
  Future<List<Trail>> loadRemote() async {
    final trails = await _remote.getTrails();
    unawaited(
      SchedulerBinding.instance.scheduleTask(() async {
        try {
          await _cache.write(
            cacheKey,
            jsonEncode(trails.map((t) => t.toJson()).toList()),
          );
        } catch (e) {
          debugPrint('trails cache write failed ($e)');
        }
      }, Priority.idle),
    );
    return trails;
  }

  List<Trail> _decode(String raw) {
    final json = jsonDecode(raw) as List;
    return [for (final t in json) Trail.fromJson(t as Map<String, dynamic>)];
  }
}
