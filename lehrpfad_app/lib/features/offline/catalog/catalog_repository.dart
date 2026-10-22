import 'package:flutter/foundation.dart';

import '../../species/data/species_repository.dart';
import '../../species/domain/merkmal.dart';
import '../../species/domain/species.dart';
import '../../trail/domain/trail.dart';
import '../storage/offline_database.dart';

/// Lokaler Katalog: die UI liest nur hieraus, nie vom Netz.
abstract interface class CatalogRepository {
  /// Alle sichtbaren Trails; emittiert neu, wenn der Sync etwas ändert.
  Stream<List<Trail>> watchTrails();

  Future<List<Species>> species();

  /// Trails mit aktiver Sperrung/Gefahr (`trail_hints`).
  Future<Set<String>> closedTrailIds();
}

class DriftCatalogRepository implements CatalogRepository {
  DriftCatalogRepository(this._db);

  final OfflineDatabase _db;

  @override
  Stream<List<Trail>> watchTrails() => _db.watchTrailJsons().map(_parseTrails);

  @override
  Future<List<Species>> species() async => [
    for (final json in await _db.speciesJsons()) Species.fromJson(json),
  ];

  @override
  Future<Set<String>> closedTrailIds() => _db.closedTrailIds();

  static List<Trail> _parseTrails(List<Map<String, dynamic>> jsons) {
    final trails = <Trail>[];
    for (final json in jsons) {
      try {
        trails.add(Trail.fromJson(json));
      } catch (e) {
        // Ein defekter Eintrag darf die übrigen Trails nicht blockieren.
        debugPrint(
          'DriftCatalogRepository: Trail ${json['id']} übersprungen ($e)',
        );
      }
    }
    return trails;
  }
}

/// [SpeciesRepository] auf dem lokalen Katalog. Merkmale (kleiner,
/// unversionierter Katalog) kommen weiter aus [merkmale].
class OfflineSpeciesRepository implements SpeciesRepository {
  OfflineSpeciesRepository(this._catalog, this._merkmale, {Future<void>? ready})
    : _ready = ready ?? Future.value();

  final CatalogRepository _catalog;
  final SpeciesRepository _merkmale;

  /// Seed-Import abgeschlossen.
  final Future<void> _ready;

  @override
  Future<List<Species>> getCatalog() async {
    await _ready;
    final list = await _catalog.species();
    list.sort((a, b) => a.nameDe.compareTo(b.nameDe));
    return list;
  }

  @override
  Future<List<Merkmal>> getMerkmale() => _merkmale.getMerkmale();
}
