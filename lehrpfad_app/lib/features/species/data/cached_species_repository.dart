import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/species.dart';
import 'seed_species_repository.dart';
import 'species_repository.dart';

/// Remote → Support-Dir-Cache → Seed-Fallback (wie Trails).
class CachedSpeciesRepository implements SpeciesRepository {
  CachedSpeciesRepository(this._remote, {SpeciesRepository? fallback})
    : _fallback = fallback ?? SeedSpeciesRepository();

  final SpeciesRepository _remote;
  final SpeciesRepository _fallback;

  static const _cacheFileName = 'species_cache.json';

  @override
  Future<List<Species>> getCatalog() async {
    try {
      final catalog = await _remote.getCatalog();
      await _writeCache(catalog);
      return catalog;
    } catch (_) {
      return _readCacheOrFallback();
    }
  }

  Future<List<Species>> _readCacheOrFallback() async {
    try {
      final file = await _cacheFile();
      if (file.existsSync()) {
        final json = jsonDecode(await file.readAsString()) as List;
        return json
            .map((e) => Species.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // korrupter Cache → Seed
    }
    return _fallback.getCatalog();
  }

  Future<File> _cacheFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_cacheFileName');
  }

  Future<void> _writeCache(List<Species> catalog) async {
    try {
      final file = await _cacheFile();
      await file.writeAsString(
        jsonEncode(catalog.map((s) => s.toJson()).toList()),
      );
    } catch (_) {
      // Schreibfehler ignorieren
    }
  }
}
