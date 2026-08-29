import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/trail_list.dart';

/// Remote-Persistenz für eingeloggte User.
class SupabaseTrailListRepository {
  SupabaseTrailListRepository(this._client);

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<List<TrailList>> fetchLists() async {
    final uid = _userId;
    if (uid == null) return [];
    final listRows = await _client
        .from('trail_lists')
        .select('id, name, created_at, updated_at')
        .eq('user_id', uid);
    if (listRows.isEmpty) return [];

    final ids = [for (final row in listRows) row['id'] as String];
    final itemRows = await _client
        .from('trail_list_items')
        .select('list_id, trail_id, added_at')
        .inFilter('list_id', ids);

    final itemsByList = <String, List<TrailListItem>>{};
    for (final row in itemRows) {
      final item = TrailListItem(
        listId: row['list_id'] as String,
        trailId: row['trail_id'] as String,
        addedAt: DateTime.parse(row['added_at'] as String),
      );
      itemsByList.putIfAbsent(item.listId, () => []).add(item);
    }

    return [
      for (final row in listRows)
        TrailList(
          id: row['id'] as String,
          name: row['name'] as String,
          createdAt: DateTime.parse(row['created_at'] as String),
          updatedAt: DateTime.parse(row['updated_at'] as String),
          items: itemsByList[row['id'] as String] ?? const [],
        ),
    ];
  }

  Future<void> upsertList(TrailList list) async {
    final uid = _userId;
    if (uid == null) return;
    await _client.from('trail_lists').upsert({
      'id': list.id,
      'user_id': uid,
      'name': list.name,
      'created_at': list.createdAt.toIso8601String(),
      'updated_at': list.updatedAt.toIso8601String(),
    });
  }

  Future<void> deleteList(String id) async {
    final uid = _userId;
    if (uid == null) return;
    await _client.from('trail_lists').delete().eq('id', id).eq('user_id', uid);
  }

  Future<void> upsertItem(TrailListItem item) async {
    if (_userId == null) return;
    await _client.from('trail_list_items').upsert({
      'list_id': item.listId,
      'trail_id': item.trailId,
      'added_at': item.addedAt.toIso8601String(),
    });
  }

  Future<void> deleteItem({
    required String listId,
    required String trailId,
  }) async {
    if (_userId == null) return;
    await _client
        .from('trail_list_items')
        .delete()
        .eq('list_id', listId)
        .eq('trail_id', trailId);
  }

}
