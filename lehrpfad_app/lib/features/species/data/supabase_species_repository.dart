import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/species.dart';
import 'species_repository.dart';

/// Laedt den gesamten Artenkatalog in einem Request.
class SupabaseSpeciesRepository implements SpeciesRepository {
  SupabaseSpeciesRepository(this._client);

  final SupabaseClient _client;

  static const _columns =
      'id, name_de, name_lat, kategorie, kurztext, content, aliases, '
      'image_path, image_credit, audio_path, icon_key';

  @override
  Future<List<Species>> getCatalog() async {
    final rows = await _client
        .from('species')
        .select(_columns)
        .order('name_de', ascending: true);
    return rows.map(rowToJson).map(Species.fromJson).toList();
  }

  /// snake_case Row → Seed-JSON (camelCase) fuer [Species.fromJson].
  static Map<String, dynamic> rowToJson(Map<String, dynamic> row) => {
    'id': row['id'],
    'nameDe': row['name_de'],
    'nameLat': row['name_lat'] ?? '',
    'kategorie': row['kategorie'],
    'kurztext': row['kurztext'] ?? '',
    'content': row['content'] ?? const <String, dynamic>{},
    'aliases': row['aliases'] ?? const <String>[],
    'imagePath': row['image_path'],
    'imageCredit': row['image_credit'] ?? '',
    'audioPath': row['audio_path'],
    'iconKey': row['icon_key'] ?? '',
  };
}
