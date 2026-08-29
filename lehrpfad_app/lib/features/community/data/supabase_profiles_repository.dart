import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/user_profile.dart';
import 'profiles_repository.dart';

/// Profile aus der Supabase-Tabelle `profiles`.
class SupabaseProfilesRepository implements ProfilesRepository {
  SupabaseProfilesRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<UserProfile?> getProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select('id, display_name, role')
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;
    return UserProfile(
      id: row['id'] as String,
      displayName: row['display_name'] as String? ?? '',
      role: row['role'] as String? ?? 'user',
    );
  }
}
