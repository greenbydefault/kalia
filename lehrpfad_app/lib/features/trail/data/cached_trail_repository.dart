import 'dart:convert';
import 'dart:io';

import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/trail.dart';
import 'seed_trail_repository.dart';
import 'trail_repository.dart';

/// Decorator um ein Remote-Repository: frische Daten werden als JSON-Datei
/// im App-Support-Verzeichnis abgelegt. Bei Offline/Fehler wird der Cache
/// gelesen, beim allerersten Start ohne Cache das gebündelte Seed-Asset.
class CachedTrailRepository implements TrailRepository {
  CachedTrailRepository(this._remote, {TrailRepository? fallback})
    : _fallback = fallback ?? SeedTrailRepository();

  final TrailRepository _remote;
  final TrailRepository _fallback;

  static const _cacheFileName = 'trails_cache.json';

  @override
  Future<List<Trail>> getTrails({LatLng? near, double? radiusKm}) async {
    try {
      final trails = await _remote.getTrails(near: near, radiusKm: radiusKm);
      await _writeCache(trails);
      return trails;
    } catch (_) {
      return _readCacheOrFallback();
    }
  }

  Future<List<Trail>> _readCacheOrFallback() async {
    try {
      final file = await _cacheFile();
      if (file.existsSync()) {
        final json = jsonDecode(await file.readAsString()) as List;
        return json
            .map((t) => Trail.fromJson(t as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // Korrupte oder unlesbare Cache-Datei -> Seed-Fallback
    }
    return _fallback.getTrails();
  }

  Future<File> _cacheFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_cacheFileName');
  }

  Future<void> _writeCache(List<Trail> trails) async {
    try {
      final file = await _cacheFile();
      await file.writeAsString(
        jsonEncode(trails.map((t) => t.toJson()).toList()),
      );
    } catch (_) {
      // Schreibfehler ignorieren – die frischen Daten sind ja bereits da
    }
  }
}
