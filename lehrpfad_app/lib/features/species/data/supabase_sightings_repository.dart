import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/fund.dart';

/// Remote-Funde für den eingeloggten User.
class SupabaseSightingsRepository {
  SupabaseSightingsRepository(this._client);

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<Map<String, Fund>> fetchFunde() async {
    final uid = _userId;
    if (uid == null) return {};
    final rows = await _client
        .from('species_sightings')
        .select('species_id, seen_at, trail_id, entdeckt_von')
        .eq('user_id', uid);
    return {
      for (final r in rows)
        r['species_id'] as String: Fund(
          speciesId: r['species_id'] as String,
          entdecktAm: DateTime.tryParse(r['seen_at'] as String? ?? ''),
          trailId: r['trail_id'] as String?,
          von: EntdecktVon.parse(r['entdeckt_von'] as String?),
        ),
    };
  }

  Future<void> upsertFund(Fund fund) async {
    final uid = _userId;
    if (uid == null) return;
    await _client.from('species_sightings').upsert({
      'user_id': uid,
      'species_id': fund.speciesId,
      if (fund.entdecktAm != null)
        'seen_at': fund.entdecktAm!.toUtc().toIso8601String(),
      'trail_id': fund.trailId,
      'entdeckt_von': fund.von?.name,
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
