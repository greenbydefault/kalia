import '../../../core/sync/sync_engine.dart';
import '../../../core/sync/sync_mutation.dart';
import '../../../core/sync/synced_id_set.dart';
import 'local_sightings_store.dart';
import 'sightings_repository.dart';
import 'supabase_sightings_repository.dart';

/// Sync-Queue-Entity für Gesehen-Markierungen.
const sightingSyncEntity = 'sighting';

/// Lokal immer; Remote optional (wenn [remote] gesetzt und User eingeloggt).
/// Remote-Ausführung und Login-Merge laufen über die [SyncEngine].
class HybridSightingsRepository implements SightingsRepository {
  HybridSightingsRepository({
    SightingsStore? local,
    SupabaseSightingsRepository? remote,
  }) : _local = local ?? LocalSightingsStore(),
       _remote = remote;

  final SightingsStore _local;
  final SupabaseSightingsRepository? _remote;
  SyncEngine? _engine;
  late final SyncedIdSet _ids = SyncedIdSet(
    entity: sightingSyncEntity,
    read: _local.read,
    write: _local.write,
    engine: () => _engine,
  );

  /// Registriert Executor/Merge an der Engine. Aufruf im Provider, vor flush.
  void attach(SyncEngine engine) {
    _engine = engine;
    final r = _remote;
    if (r == null) return;
    engine.registerExecutor(sightingSyncEntity, (m) async {
      if (m.op == SyncOp.delete.name) {
        await r.markUnseen(m.key);
      } else {
        await r.markSeen(m.key);
      }
    });
    engine.registerMergeHandler(sightingSyncEntity, () async {
      await mergeWithRemote(await r.fetchSeenIds());
    });
  }

  @override
  Future<Set<String>> getSeenIds() => _local.read();

  @override
  Future<void> persistSeenIds(Set<String> ids) => _local.write(ids);

  @override
  Future<void> applySeenChange({
    required Set<String> ids,
    required String speciesId,
    required bool seen,
  }) {
    return _ids.writeAndEnqueue(next: ids, key: speciesId, present: seen);
  }

  @override
  Future<void> setSeen(String speciesId, bool seen) async {
    final previous = await _local.read();
    final next = {...previous};
    if (seen) {
      next.add(speciesId);
    } else {
      next.remove(speciesId);
    }
    await applySeenChange(ids: next, speciesId: speciesId, seen: seen);
  }

  Future<Set<String>> mergeWithRemote(Set<String> remoteIds) =>
      _ids.mergeUnion(remoteIds);
}
