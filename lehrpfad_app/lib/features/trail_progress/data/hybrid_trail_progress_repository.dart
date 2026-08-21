import '../domain/completion_source.dart';
import '../domain/trail_completion.dart';
import '../domain/trail_walk.dart';
import '../domain/walk_status.dart';
import 'local_trail_progress_store.dart';
import 'supabase_trail_progress_repository.dart';
import 'trail_progress_repository.dart';

/// Lokal immer; Remote optional (Login).
class HybridTrailProgressRepository implements TrailProgressRepository {
  HybridTrailProgressRepository({LocalTrailProgressStore? local, this.remote})
    : _local = local ?? LocalTrailProgressStore();

  final LocalTrailProgressStore _local;
  final SupabaseTrailProgressRepository? remote;

  @override
  Future<Set<String>> getBookmarkIds() => _local.readBookmarks();

  @override
  Future<void> setBookmarked(String trailId, bool bookmarked) async {
    final ids = await _local.readBookmarks();
    final next = {...ids};
    if (bookmarked) {
      next.add(trailId);
    } else {
      next.remove(trailId);
    }
    await _local.writeBookmarks(next);
    final r = remote;
    if (r == null) return;
    try {
      if (bookmarked) {
        await r.upsertBookmark(trailId);
      } else {
        await r.deleteBookmark(trailId);
      }
    } catch (_) {}
  }

  @override
  Future<Map<String, TrailCompletion>> getCompletions() =>
      _local.readCompletions();

  @override
  Future<void> setCompleted(
    String trailId, {
    required bool completed,
    CompletionSource source = CompletionSource.manual,
  }) async {
    final map = await _local.readCompletions();
    final next = {...map};
    if (completed) {
      next[trailId] = TrailCompletion(
        trailId: trailId,
        completedAt: DateTime.now().toUtc(),
        source: source,
      );
    } else {
      next.remove(trailId);
    }
    await _local.writeCompletions(next);
    final r = remote;
    if (r == null) return;
    try {
      if (completed) {
        await r.upsertCompletion(next[trailId]!);
      } else {
        await r.deleteCompletion(trailId);
      }
    } catch (_) {}
  }

  @override
  Future<TrailWalk?> getActiveWalk() => _local.readActiveWalk();

  @override
  Future<List<TrailWalk>> getWalks() => _local.readWalks();

  @override
  Future<void> saveWalk(TrailWalk walk) async {
    final walks = await _local.readWalks();
    final next = <TrailWalk>[];
    var replaced = false;
    for (final w in walks) {
      if (w.id == walk.id) {
        next.add(walk);
        replaced = true;
      } else if (walk.status == WalkStatus.active &&
          w.status == WalkStatus.active) {
        next.add(
          w.copyWith(
            status: WalkStatus.abandoned,
            updatedAt: DateTime.now().toUtc(),
            clearLastPosition: true,
          ),
        );
      } else {
        next.add(w);
      }
    }
    if (!replaced) next.add(walk);
    await _local.writeWalks(next);
    final r = remote;
    if (r == null) return;
    try {
      await r.upsertWalk(walk);
    } catch (_) {}
  }

  @override
  Future<void> clearActiveWalk() async {
    final walks = await _local.readWalks();
    final now = DateTime.now().toUtc();
    final next = [
      for (final w in walks)
        if (w.status == WalkStatus.active)
          w.copyWith(
            status: WalkStatus.abandoned,
            updatedAt: now,
            clearLastPosition: true,
          )
        else
          w,
    ];
    await _local.writeWalks(next);
    final r = remote;
    if (r == null) return;
    for (final w in next.where((w) => w.status == WalkStatus.abandoned)) {
      try {
        await r.upsertWalk(w);
      } catch (_) {}
    }
  }

  @override
  Future<void> mergeWithRemote({
    required Set<String> remoteBookmarks,
    required Map<String, TrailCompletion> remoteCompletions,
    required List<TrailWalk> remoteWalks,
  }) async {
    final localBookmarks = await _local.readBookmarks();
    final mergedBookmarks = {...localBookmarks, ...remoteBookmarks};
    await _local.writeBookmarks(mergedBookmarks);

    final localCompletions = await _local.readCompletions();
    final mergedCompletions = {...remoteCompletions, ...localCompletions};
    await _local.writeCompletions(mergedCompletions);

    final localWalks = await _local.readWalks();
    final byId = <String, TrailWalk>{
      for (final w in remoteWalks) w.id: w,
      for (final w in localWalks) w.id: w,
    };
    // Nur eine active behalten (lokal bevorzugt)
    TrailWalk? active;
    final mergedWalks = <TrailWalk>[];
    for (final w in byId.values) {
      if (w.status != WalkStatus.active) {
        mergedWalks.add(w.copyWith(clearLastPosition: true));
        continue;
      }
      if (active == null || w.updatedAt.isAfter(active.updatedAt)) {
        if (active != null) {
          mergedWalks.add(
            active.copyWith(
              status: WalkStatus.abandoned,
              updatedAt: DateTime.now().toUtc(),
              clearLastPosition: true,
            ),
          );
        }
        active = w;
      } else {
        mergedWalks.add(
          w.copyWith(
            status: WalkStatus.abandoned,
            updatedAt: DateTime.now().toUtc(),
            clearLastPosition: true,
          ),
        );
      }
    }
    if (active != null) mergedWalks.add(active);
    await _local.writeWalks(mergedWalks);

    final r = remote;
    if (r == null) return;
    try {
      final missingBookmarks = mergedBookmarks.difference(remoteBookmarks);
      if (missingBookmarks.isNotEmpty) {
        await r.upsertBookmarks(missingBookmarks);
      }
      final missingCompletions = <String, TrailCompletion>{};
      for (final e in mergedCompletions.entries) {
        if (!remoteCompletions.containsKey(e.key)) {
          missingCompletions[e.key] = e.value;
        }
      }
      if (missingCompletions.isNotEmpty) {
        await r.upsertCompletions(missingCompletions);
      }
      for (final w in mergedWalks) {
        await r.upsertWalk(w);
      }
    } catch (_) {}
  }
}
