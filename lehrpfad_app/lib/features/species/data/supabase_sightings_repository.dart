import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote-Gesehen-Status fuer den eingeloggten User.
class SupabaseSightingsRepository {
  SupabaseSightingsRepository(this._client);

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<Set<String>> fetchSeenIds() async {
    final uid = _userId;
    if (uid == null) return {};
    final rows = await _client
        .from('species_sightings')
        .select('species_id')
        .eq('user_id', uid);
    return {for (final r in rows) r['species_id'] as String};
  }

  Future<void> markSeen(String speciesId) async {
    final uid = _userId;
    if (uid == null) return;
    await _client.from('species_sightings').upsert({
      'user_id': uid,
      'species_id': speciesId,
    });
  }

  Future<void> markUnseen(String speciesId) async {
    final uid = _userId;
    if (uid == null) return;
    await _client
        .from('species_sightings')
        .delete()
        .eq('user_id', uid)
        .eq('species_id', speciesId);
  }

}
