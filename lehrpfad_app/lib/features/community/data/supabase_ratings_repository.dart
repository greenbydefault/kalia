import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/trail_rating.dart';
import 'ratings_repository.dart';

/// Sterne-Bewertungen aus Supabase. Die Aggregation (Schnitt/Anzahl)
/// passiert clientseitig – bei der erwarteten Datenmenge guenstiger als
/// eine eigene Datenbank-View.
class SupabaseRatingsRepository implements RatingsRepository {
  SupabaseRatingsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<TrailRating> getRating(String trailId) async {
    final rows = await _client
        .from('ratings')
        .select('user_id, stars')
        .eq('trail_id', trailId);
    final uid = _client.auth.currentUser?.id;
    var sum = 0;
    int? myStars;
    for (final row in rows) {
      final stars = row['stars'] as int;
      sum += stars;
      if (row['user_id'] == uid) myStars = stars;
    }
    return TrailRating(
      average: rows.isEmpty ? 0 : sum / rows.length,
      count: rows.length,
      myStars: myStars,
    );
  }

  @override
  Future<void> setRating(String trailId, int stars) {
    return _client.from('ratings').upsert({
      'trail_id': trailId,
      'user_id': _client.auth.currentUser!.id,
      'stars': stars,
    });
  }

  @override
  Future<void> removeRating(String trailId) {
    return _client
        .from('ratings')
        .delete()
        .eq('trail_id', trailId)
        .eq('user_id', _client.auth.currentUser!.id);
  }
}
