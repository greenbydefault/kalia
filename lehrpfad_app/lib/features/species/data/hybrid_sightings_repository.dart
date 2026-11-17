import '../../../core/sync/sync_engine.dart';
import '../../../core/sync/sync_mutation.dart';
import '../domain/fund.dart';
import 'local_funde_store.dart';
import 'sightings_repository.dart';
import 'supabase_sightings_repository.dart';

/// Sync-Queue-Entity für Funde.
const sightingSyncEntity = 'sighting';

/// Lokal immer; Remote optional (wenn [remote] gesetzt und User eingeloggt).
/// Remote-Ausführung und Login-Merge laufen über die [SyncEngine].
class HybridSightingsRepository implements SightingsRepository {
  HybridSightingsRepository({
    FundeStore? local,
    SupabaseSightingsRepository? remote,
  }) : _local = local ?? LocalFundeStore(),
       _remote = remote;

  final FundeStore _local;
  final SupabaseSightingsRepository? _remote;
  SyncEngine? _engine;

  /// Registriert Executor/Merge an der Engine. Aufruf im Provider, vor flush.
  void attach(SyncEngine engine) {
    _engine = engine;
    final r = _remote;
    if (r == null) return;
    engine.registerExecutor(sightingSyncEntity, (m) async {
      if (m.op == SyncOp.delete.name) {
        await r.markUnseen(m.key);
        return;
      }
      // Aktuellen Stand senden, nicht den zur Queue-Zeit: Folge-Mutationen
      // (Wer, Undo) überholen sich sonst gegenseitig.
      final fund = (await _local.read())[m.key];
      if (fund != null) await r.upsertFund(fund);
    });
    engine.registerMergeHandler(sightingSyncEntity, () async {
      await mergeWithRemote(await r.fetchFunde());
    });
  }

  @override
  Future<Map<String, Fund>> getFunde() => _local.read();

  @override
  Future<void> applyChange({
    required Map<String, Fund> funde,
    required String speciesId,
  }) async {
    await _local.write(funde);
    await _engine?.enqueue(
      SyncMutation.create(
        entity: sightingSyncEntity,
        key: speciesId,
        op: funde.containsKey(speciesId) ? SyncOp.upsert : SyncOp.delete,
      ),
    );
  }

  /// Union lokal + remote; pro Art frühestes Datum, lokale Angaben vor
  /// Remote. Was remote fehlt oder dort weniger weiß, wird hochgeladen.
  Future<Map<String, Fund>> mergeWithRemote(Map<String, Fund> remote) async {
    final local = await _local.read();
    final merged = <String, Fund>{...remote};
    for (final e in local.entries) {
      final r = remote[e.key];
      merged[e.key] = r == null ? e.value : Fund.merge(e.value, r);
    }
    await _local.write(merged);
    final sync = _engine;
    if (sync != null) {
      for (final e in merged.entries) {
        if (remote[e.key] == e.value) continue;
        await sync.enqueue(
          SyncMutation.create(
            entity: sightingSyncEntity,
            key: e.key,
            op: SyncOp.upsert,
          ),
        );
      }
    }
    return merged;
  }
}
