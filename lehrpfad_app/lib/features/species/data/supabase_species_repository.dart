import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/merkmal.dart';
import '../domain/species.dart';
import 'species_repository.dart';

/// Laedt den gesamten Artenkatalog in einem Request.
class SupabaseSpeciesRepository implements SpeciesRepository {
  SupabaseSpeciesRepository(this._client);

  final SupabaseClient _client;

  static const _columns =
      'id, name_de, name_lat, kategorie, kurztext, content, aliases, '
      'image_path, image_credit, audio_path, icon_key, '
      'gruppe, seltenheit, gefahr, nahrung, '
      'tax_reich, tax_stamm, tax_klasse, tax_ordnung, tax_familie, masse, '
      'species_merkmale(merkmal_id), '
      'species_beziehungen(typ, to_species_id, name_de, name_lat, kurztext)';

  @override
  Future<List<Species>> getCatalog() async {
    final rows = await _client
        .from('species')
        .select(_columns)
        .order('name_de', ascending: true);
    return rows.map(rowToJson).map(Species.fromJson).toList();
  }

  @override
  Future<List<Merkmal>> getMerkmale() async {
    final rows = await _client
        .from('merkmale')
        .select('id, name_de, beschreibung, icon_key, gruppe, sortierung')
        .order('sortierung', ascending: true);
    return rows.map(merkmalRowToJson).map(Merkmal.fromJson).toList();
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
    'gruppe': row['gruppe'] ?? '',
    'seltenheit': row['seltenheit'] ?? '',
    'gefahr': row['gefahr'] ?? 0,
    'nahrung': row['nahrung'] ?? const <String>[],
    'taxonomie': {
      'reich': row['tax_reich'] ?? '',
      'stamm': row['tax_stamm'] ?? '',
      'klasse': row['tax_klasse'] ?? '',
      'ordnung': row['tax_ordnung'] ?? '',
      'familie': row['tax_familie'] ?? '',
    },
    'masse': row['masse'] ?? const <dynamic>[],
    'merkmale': (row['species_merkmale'] as List? ?? const [])
        .map((e) => e['merkmal_id'] as String)
        .toList(),
    'beziehungen': (row['species_beziehungen'] as List? ?? const [])
        .map(
          (e) => {
            'typ': e['typ'],
            'toSpeciesId': e['to_species_id'],
            'nameDe': e['name_de'] ?? '',
            'nameLat': e['name_lat'] ?? '',
            'kurztext': e['kurztext'] ?? '',
          },
        )
        .toList(),
  };

  /// snake_case Row → Seed-JSON (camelCase) fuer [Merkmal.fromJson].
  static Map<String, dynamic> merkmalRowToJson(Map<String, dynamic> row) => {
    'id': row['id'],
    'nameDe': row['name_de'],
    'beschreibung': row['beschreibung'] ?? '',
    'iconKey': row['icon_key'] ?? '',
    'gruppe': row['gruppe'] ?? '',
    'sortierung': row['sortierung'] ?? 0,
  };
}
