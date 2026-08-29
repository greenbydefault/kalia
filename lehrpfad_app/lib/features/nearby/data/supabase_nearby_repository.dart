import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/nearby_place.dart';
import 'nearby_repository.dart';

/// Lädt den gesamten Katalog der Orte in der Nähe in einem Request.
class SupabaseNearbyRepository implements NearbyRepository {
  SupabaseNearbyRepository(this._client);

  final SupabaseClient _client;

  static const _columns =
      'id, name, kategorie, kurztext, lat, lon, website, oeffnungszeiten, opening_hours, telefon';

  @override
  Future<List<NearbyPlace>> getCatalog() async {
    final rows = await _client
        .from('pois')
        .select(_columns)
        .order('name', ascending: true);
    return rows.map(rowToJson).map(NearbyPlace.fromJson).toList();
  }

  /// snake_case Row → Seed-JSON (camelCase) für [NearbyPlace.fromJson].
  static Map<String, dynamic> rowToJson(Map<String, dynamic> row) => {
    'id': row['id'],
    'name': row['name'],
    'kategorie': row['kategorie'],
    'kurztext': row['kurztext'] ?? '',
    'lat': row['lat'],
    'lon': row['lon'],
    'website': row['website'],
    'oeffnungszeiten': row['oeffnungszeiten'],
    'opening_hours': row['opening_hours'],
    'telefon': row['telefon'],
  };
}
