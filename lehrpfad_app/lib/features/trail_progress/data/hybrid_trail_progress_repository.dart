import '../../../core/sync/sync_engine.dart';
import '../../../core/sync/sync_mutation.dart';
import '../../../core/sync/synced_id_set.dart';
import '../domain/completion_source.dart';
import '../domain/trail_completion.dart';
import '../domain/trail_walk.dart';
import '../domain/walk_status.dart';
import 'local_trail_progress_store.dart';
import 'supabase_trail_progress_repository.dart';
import 'trail_progress_repository.dart';

/// Sync-Queue-Entities für Trail-Progress.
const bookmarkSyncEntity = 'trail_bookmark';
const completionSyncEntity = 'trail_completion';
const walkSyncEntity = 'trail_walk';

/// Lokal immer; Remote optional (Login). Remote-Ausführung und
/// Login-Merge laufen über die [SyncEngine].
class HybridTrailProgressRepository implements TrailProgressRepository {
  HybridTrailProgressRepository({
    LocalTrailProgressStore? local,
    SupabaseTrailProgressRepository? remote,
  }) : _local = local ?? LocalTrailProgressStore(),
       _remote = remote;

  final LocalTrailProgressStore _local;
  final SupabaseTrailProgressRepository? _remote;
  SyncEngine? _engine;
  late final SyncedIdSet _bookmarks = SyncedIdSet(
    entity: bookmarkSyncEntity,
    read: _local.readBookmarks,
    write: _local.writeBookmarks,
    engine: () => _engine,
  );

  /// Registriert Executor/Merge an der Engine. Aufruf im Provider, vor flush.
  void attach(SyncEngine engine) {
    _engine = engine;
    final r = _remote;
    if (r == null) return;
    engine.registerExecutor(bookmarkSyncEntity, (m) async {
      if (m.op == SyncOp.delete.name) {
        await r.deleteBookmark(m.key);
      } else {
        await r.upsertBookmark(m.key);
      }
    });
    engine.registerExecutor(completionSyncEntity, (m) async {
      if (m.op == SyncOp.delete.name) {
        await r.deleteCompletion(m.key);
      } else {
        await r.upsertCompletion(TrailCompletion.fromJson(m.payload));
      }
    });
    engine.registerExecutor(walkSyncEntity, (m) async {
      await r.upsertWalk(TrailWalk.fromJson(m.payload));
    });
    engine.registerMergeHandler('trail_progress', () async {
      await mergeWithRemote(
        remoteBookmarks: await r.fetchBookmarkIds(),
        remoteCompletions: await r.fetchCompletions(),
        remoteWalks: await r.fetchWalks(),
      );
    });
  }

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
    await _bookmarks.writeAndEnqueue(
      next: next,
      key: trailId,
      present: bookmarked,
    );
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
    await _engine?.enqueue(
      SyncMutation.create(
        entity: completionSyncEntity,
        key: trailId,
        op: completed ? SyncOp.upsert : SyncOp.delete,
        payload: completed ? next[trailId]!.toJson() : const {},
      ),
    );
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
    await _engine?.enqueue(
      SyncMutation.create(
        entity: walkSyncEntity,
        key: walk.id,
        op: SyncOp.upsert,
        payload: walk.toJson(),
      ),
    );
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
    final engine = _engine;
    if (engine == null) return;
    for (final w in next) {
      final wasActive = walks.any(
        (prev) => prev.id == w.id && prev.status == WalkStatus.active,
      );
      if (!wasActive || w.status != WalkStatus.abandoned) continue;
      await engine.enqueue(
        SyncMutation.create(
          entity: walkSyncEntity,
          key: w.id,
          op: SyncOp.upsert,
          payload: w.toJson(),
        ),
      );
    }
  }

  Future<void> mergeWithRemote({
    required Set<String> remoteBookmarks,
    required Map<String, TrailCompletion> remoteCompletions,
    required List<TrailWalk> remoteWalks,
  }) async {
    await _bookmarks.mergeUnion(remoteBookmarks);

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

    final engine = _engine;
    if (engine == null) return;
    for (final e in mergedCompletions.entries) {
      if (!remoteCompletions.containsKey(e.key)) {
        await engine.enqueue(
          SyncMutation.create(
            entity: completionSyncEntity,
            key: e.key,
            op: SyncOp.upsert,
            payload: e.value.toJson(),
          ),
        );
      }
    }
    final remoteWalkIds = {for (final w in remoteWalks) w.id};
    for (final w in mergedWalks) {
      if (remoteWalkIds.contains(w.id)) continue;
      await engine.enqueue(
        SyncMutation.create(
          entity: walkSyncEntity,
          key: w.id,
          op: SyncOp.upsert,
          payload: w.toJson(),
        ),
      );
    }
  }
}
