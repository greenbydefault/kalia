import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/completion_source.dart';
import '../domain/trail_completion.dart';
import '../domain/trail_walk.dart';
import '../domain/walk_status.dart';

/// Remote-Persistenz für eingeloggte User.
class SupabaseTrailProgressRepository {
  SupabaseTrailProgressRepository(this._client);

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<Set<String>> fetchBookmarkIds() async {
    final uid = _userId;
    if (uid == null) return {};
    final rows = await _client
        .from('trail_bookmarks')
        .select('trail_id')
        .eq('user_id', uid);
    return {for (final r in rows) r['trail_id'] as String};
  }

  Future<void> upsertBookmark(String trailId) async {
    final uid = _userId;
    if (uid == null) return;
    await _client.from('trail_bookmarks').upsert({
      'user_id': uid,
      'trail_id': trailId,
    });
  }

  Future<void> deleteBookmark(String trailId) async {
    final uid = _userId;
    if (uid == null) return;
    await _client
        .from('trail_bookmarks')
        .delete()
        .eq('user_id', uid)
        .eq('trail_id', trailId);
  }

  Future<Map<String, TrailCompletion>> fetchCompletions() async {
    final uid = _userId;
    if (uid == null) return {};
    final rows = await _client
        .from('trail_completions')
        .select('trail_id, completed_at, source')
        .eq('user_id', uid);
    final map = <String, TrailCompletion>{};
    for (final r in rows) {
      final trailId = r['trail_id'] as String;
      map[trailId] = TrailCompletion(
        trailId: trailId,
        completedAt: DateTime.parse(r['completed_at'] as String),
        source: CompletionSource.fromWire(r['source'] as String?),
      );
    }
    return map;
  }

  Future<void> upsertCompletion(TrailCompletion completion) async {
    final uid = _userId;
    if (uid == null) return;
    await _client.from('trail_completions').upsert({
      'user_id': uid,
      'trail_id': completion.trailId,
      'completed_at': completion.completedAt.toIso8601String(),
      'source': completion.source.wire,
    });
  }

  Future<void> deleteCompletion(String trailId) async {
    final uid = _userId;
    if (uid == null) return;
    await _client
        .from('trail_completions')
        .delete()
        .eq('user_id', uid)
        .eq('trail_id', trailId);
  }

  Future<List<TrailWalk>> fetchWalks() async {
    final uid = _userId;
    if (uid == null) return [];
    final rows = await _client
        .from('trail_walks')
        .select(
          'id, trail_id, status, started_at, updated_at, completed_at, '
          'progress_m, progress_ratio, last_lat, last_lon, visited_station_ids',
        )
        .eq('user_id', uid);
    return [for (final r in rows) _walkFromRow(r)];
  }

  Future<void> upsertWalk(TrailWalk walk) async {
    final uid = _userId;
    if (uid == null) return;
    await _client.from('trail_walks').upsert({
      'id': walk.id,
      'user_id': uid,
      'trail_id': walk.trailId,
      'status': walk.status.wire,
      'started_at': walk.startedAt.toIso8601String(),
      'updated_at': walk.updatedAt.toIso8601String(),
      'completed_at': walk.completedAt?.toIso8601String(),
      'progress_m': walk.progressM,
      'progress_ratio': walk.progressRatio,
      'last_lat': walk.lastLat,
      'last_lon': walk.lastLon,
      'visited_station_ids': walk.visitedStationIds,
    });
  }

  TrailWalk _walkFromRow(Map<String, dynamic> r) {
    final visited = r['visited_station_ids'];
    return TrailWalk(
      id: r['id'] as String,
      trailId: r['trail_id'] as String,
      status: WalkStatus.fromWire(r['status'] as String?),
      startedAt: DateTime.parse(r['started_at'] as String),
      updatedAt: DateTime.parse(r['updated_at'] as String),
      completedAt: r['completed_at'] == null
          ? null
          : DateTime.parse(r['completed_at'] as String),
      progressM: (r['progress_m'] as num?)?.toDouble() ?? 0,
      progressRatio: (r['progress_ratio'] as num?)?.toDouble() ?? 0,
      lastLat: (r['last_lat'] as num?)?.toDouble(),
      lastLon: (r['last_lon'] as num?)?.toDouble(),
      visitedStationIds: visited is List
          ? visited.map((e) => e.toString()).toList()
          : const [],
    );
  }
}
