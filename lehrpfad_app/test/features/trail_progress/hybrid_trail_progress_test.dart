import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/core/sync/sync_engine.dart';
import 'package:lehrpfad_app/core/sync/sync_mutation.dart';
import 'package:lehrpfad_app/features/trail_progress/data/hybrid_trail_progress_repository.dart';
import 'package:lehrpfad_app/features/trail_progress/data/local_trail_progress_store.dart';
import 'package:lehrpfad_app/features/trail_progress/domain/completion_source.dart';
import 'package:lehrpfad_app/features/trail_progress/domain/trail_completion.dart';
import 'package:lehrpfad_app/features/trail_progress/domain/trail_walk.dart';
import 'package:lehrpfad_app/features/trail_progress/domain/walk_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

TrailWalk _walk(
  String id, {
  WalkStatus status = WalkStatus.completed,
  DateTime? updatedAt,
}) {
  final t = updatedAt ?? DateTime.utc(2026, 1, 1);
  return TrailWalk(
    id: id,
    trailId: 'trail-$id',
    status: status,
    startedAt: t,
    updatedAt: t,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('merge: eine active, local wins Completions, nur fehlende Walks', () async {
    final local = LocalTrailProgressStore();
    await local.writeBookmarks({'local-only', 'shared'});
    await local.writeCompletions({
      'a': TrailCompletion(
        trailId: 'a',
        completedAt: DateTime.utc(2026, 2, 1),
        source: CompletionSource.manual,
      ),
    });
    await local.writeWalks([
      _walk('synced'),
      _walk('local-only'),
      _walk(
        'active-local',
        status: WalkStatus.active,
        updatedAt: DateTime.utc(2026, 3, 1),
      ),
    ]);

    final engine = SyncEngine();
    final enqueued = <SyncMutation>[];
    final repo = HybridTrailProgressRepository(local: local);
    repo.attach(engine);
    engine.registerExecutor(bookmarkSyncEntity, (m) async => enqueued.add(m));
    engine.registerExecutor(completionSyncEntity, (m) async => enqueued.add(m));
    engine.registerExecutor(walkSyncEntity, (m) async => enqueued.add(m));

    await repo.mergeWithRemote(
      remoteBookmarks: {'shared', 'remote-only'},
      remoteCompletions: {
        'a': TrailCompletion(
          trailId: 'a',
          completedAt: DateTime.utc(2026, 1, 1),
          source: CompletionSource.gps,
        ),
        'b': TrailCompletion(
          trailId: 'b',
          completedAt: DateTime.utc(2026, 1, 1),
          source: CompletionSource.gps,
        ),
      },
      remoteWalks: [
        _walk('synced'),
        _walk('active-remote', status: WalkStatus.active),
      ],
    );

    expect(await local.readBookmarks(), {
      'local-only',
      'shared',
      'remote-only',
    });
    final completions = await local.readCompletions();
    expect(completions['a']!.source, CompletionSource.manual);
    expect(completions.containsKey('b'), isTrue);

    final walks = await local.readWalks();
    expect(walks.where((w) => w.status == WalkStatus.active).length, 1);
    expect(
      walks.firstWhere((w) => w.status == WalkStatus.active).id,
      'active-local',
    );

    expect(
      enqueued.where((m) => m.entity == bookmarkSyncEntity).map((m) => m.key),
      ['local-only'],
    );
    expect(
      enqueued.where((m) => m.entity == completionSyncEntity).map((m) => m.key),
      isEmpty,
    );
    expect(
      enqueued.where((m) => m.entity == walkSyncEntity).map((m) => m.key).toSet(),
      {'local-only', 'active-local'},
    );
  });

  test('clearActiveWalk queued nur die in diesem Call gedrehten', () async {
    final local = LocalTrailProgressStore();
    await local.writeWalks([
      _walk('old-abandoned', status: WalkStatus.abandoned),
      _walk('now-active', status: WalkStatus.active),
    ]);
    final engine = SyncEngine();
    final keys = <String>[];
    final repo = HybridTrailProgressRepository(local: local);
    repo.attach(engine);
    engine.registerExecutor(walkSyncEntity, (m) async => keys.add(m.key));

    await repo.clearActiveWalk();
    expect(keys, ['now-active']);
  });

  test('attach ohne Remote registriert keinen Executor — enqueue ist No-Op', () async {
    final engine = SyncEngine();
    HybridTrailProgressRepository().attach(engine);
    await engine.enqueue(
      SyncMutation.create(
        entity: walkSyncEntity,
        key: 'x',
        op: SyncOp.upsert,
      ),
    );
    expect(await engine.pendingCount, 0);
  });
}
