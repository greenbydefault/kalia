import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../../offline/catalog/seed_loader.dart';
import '../domain/trail.dart';
import 'trail_repository.dart';

/// Lädt den gebündelten Katalog (`assets/seed/index.json`). Die Liste der
/// Trails steht im Index, den `tools/export_catalog.py` erzeugt.
class SeedTrailRepository implements TrailRepository {
  SeedTrailRepository({SeedLoader? loader}) : _loader = loader ?? SeedLoader();

  final SeedLoader _loader;

  /// Für die erste Nähe-Liste, bevor Supabase da ist.
  Future<List<Trail>> loadBodies() => getTrails();

  @override
  Future<List<Trail>> getTrails({LatLng? near, double? radiusKm}) async {
    final sw = Stopwatch()..start();
    final entries = await _loader.loadTrails();
    final trails = <Trail>[];
    for (final e in entries) {
      try {
        trails.add(Trail.fromJson(e.json));
      } catch (err) {
        // Ein fehlerhafter Seed darf die übrigen Trails nicht blockieren.
        debugPrint('SeedTrailRepository: "${e.id}" übersprungen ($err)');
      }
    }
    debugPrint('trails seed ${trails.length} ${sw.elapsedMilliseconds} ms');
    return trails;
  }
}
