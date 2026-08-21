import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/trail.dart';
import 'trail_repository.dart';

/// Lädt Trails inkl. Stationen und Amenities aus Supabase (ein Request über
/// eingebettete Relationen). Die Row-Mapper sind bewusst statisch und public,
/// damit sie ohne Client testbar sind.
class SupabaseTrailRepository implements TrailRepository {
  SupabaseTrailRepository(this._client);

  final SupabaseClient _client;

  // Explizite Spaltenliste: die Generated Columns (pos/start_pos) kämen als
  // unlesbare WKB-Hex-Strings mit und werden hier ausgeklammert.
  static const _columns = 'id, name, typ, form, kurzbeschreibung, beschreibung, '
      'laenge_km, dauer_min, rundkurs, markierung, betreiber, region, website, '
      'eintritt, eintritt_preise, oeffnungszeiten, besuchshinweise, '
      'anreise, start_name, arten, tags, route, area, '
      'stations(id, osm_id, lat, lon, km, reihenfolge, titel, thema, kurztext, '
      'erlebnisse, barrierefrei, steckbrief), '
      'amenities(osm_id, lat, lon, kategorie, name)';

  @override
  Future<List<Trail>> getTrails({LatLng? near, double? radiusKm}) async {
    final rows = await _client
        .from('trails')
        .select(_columns)
        .order('reihenfolge', referencedTable: 'stations', ascending: true)
        .order('name', ascending: true);
    return rows.map(trailRowToJson).map(Trail.fromJson).toList();
  }

  /// Mappt eine trails-Row (snake_case) auf das Seed-JSON-Format,
  /// das [Trail.fromJson] erwartet.
  static Map<String, dynamic> trailRowToJson(Map<String, dynamic> row) => {
    'id': row['id'],
    'name': row['name'],
    'typ': row['typ'],
    'kurzbeschreibung': row['kurzbeschreibung'],
    'beschreibung': row['beschreibung'],
    'laengeKm': row['laenge_km'],
    'dauerMin': row['dauer_min'],
    'rundkurs': row['rundkurs'],
    'markierung': row['markierung'],
    'betreiber': row['betreiber'],
    'region': row['region'],
    'website': row['website'],
    'eintritt': row['eintritt'] ?? false,
    'eintrittPreise': row['eintritt_preise'],
    'oeffnungszeiten': row['oeffnungszeiten'],
    'besuchshinweise': row['besuchshinweise'],
    'anreise': row['anreise'],
    'startName': row['start_name'],
    'arten': row['arten'] ?? const <String>[],
    'tags': row['tags'] ?? const <String>[],
    'form': row['form'],
    'route': row['route'] ?? const <dynamic>[],
    'area': row['area'] ?? const <dynamic>[],
    'stationen': (row['stations'] as List? ?? const [])
        .map((s) => stationRowToJson(s as Map<String, dynamic>))
        .toList(),
    'amenities': (row['amenities'] as List? ?? const [])
        .map((a) => amenityRowToJson(a as Map<String, dynamic>))
        .toList(),
  };

  static Map<String, dynamic> stationRowToJson(Map<String, dynamic> row) => {
    'id': row['id'],
    'osmId': row['osm_id'],
    'lat': row['lat'],
    'lon': row['lon'],
    'km': row['km'],
    'reihenfolge': row['reihenfolge'],
    'titel': row['titel'],
    'thema': row['thema'],
    'kurztext': row['kurztext'],
    'erlebnisse': row['erlebnisse'] ?? const <String>[],
    'barrierefrei': row['barrierefrei'],
    'steckbrief': row['steckbrief'],
  };

  static Map<String, dynamic> amenityRowToJson(Map<String, dynamic> row) => {
    'osmId': row['osm_id'],
    'lat': row['lat'],
    'lon': row['lon'],
    'kategorie': row['kategorie'],
    'name': row['name'],
  };
}
