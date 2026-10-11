import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/nearby.dart';
import 'nearby_zeiten_repository.dart';

/// Lädt alle Fahrzeiten aus `trail_pois` (seitenweise, PostgREST kappt bei 1000).
class SupabaseNearbyZeitenRepository implements NearbyZeitenRepository {
  SupabaseNearbyZeitenRepository(this._client);

  final SupabaseClient _client;

  static const pageSize = 1000;

  @override
  Future<NearbyZeiten> getZeiten() async {
    final rows = <Map<String, dynamic>>[];
    var from = 0;
    while (true) {
      final page = await _client
          .from('trail_pois')
          .select('trail_id, poi_id, sek')
          .order('trail_id', ascending: true)
          .order('poi_id', ascending: true)
          .range(from, from + pageSize - 1);
      rows.addAll(page);
      if (page.length < pageSize) break;
      from += pageSize;
    }
    return rowsToZeiten(rows);
  }

  /// snake_case Rows → [NearbyZeiten].
  static NearbyZeiten rowsToZeiten(List<Map<String, dynamic>> rows) {
    final zeiten = <String, Map<String, int>>{};
    for (final row in rows) {
      final trailId = row['trail_id'] as String;
      (zeiten[trailId] ??= {})[row['poi_id'] as String] = (row['sek'] as num)
          .toInt();
    }
    return zeiten;
  }
}
