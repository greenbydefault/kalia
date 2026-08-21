import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/trail_comment.dart';
import 'comments_repository.dart';

/// Kommentare aus Supabase, Anzeigename per Embed aus `profiles`
/// (FK comments.user_id -> profiles.id).
class SupabaseCommentsRepository implements CommentsRepository {
  SupabaseCommentsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<TrailComment>> getComments(String trailId) async {
    final rows = await _client
        .from('comments')
        .select('id, trail_id, user_id, text, created_at, '
            'profiles(display_name)')
        .eq('trail_id', trailId)
        .order('created_at', ascending: false);
    final uid = _client.auth.currentUser?.id;
    return rows.map((row) {
      final profile = row['profiles'] as Map<String, dynamic>?;
      return TrailComment(
        id: row['id'] as int,
        trailId: row['trail_id'] as String,
        authorName: profile?['display_name'] as String? ?? 'Unbekannt',
        text: row['text'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
        isMine: row['user_id'] == uid,
      );
    }).toList();
  }

  @override
  Future<void> addComment(String trailId, String text) {
    return _client.from('comments').insert({
      'trail_id': trailId,
      'user_id': _client.auth.currentUser!.id,
      'text': text,
    });
  }

  @override
  Future<void> deleteComment(int commentId) {
    return _client.from('comments').delete().eq('id', commentId);
  }
}
