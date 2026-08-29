import 'sync_engine.dart';
import 'sync_mutation.dart';

/// Local-first Id-Set (Merken, Gesehen): write, enqueue, union-merge.
class SyncedIdSet {
  SyncedIdSet({
    required this.entity,
    required this.read,
    required this.write,
    required this.engine,
  });

  final String entity;
  final Future<Set<String>> Function() read;
  final Future<void> Function(Set<String> ids) write;
  final SyncEngine? Function() engine;

  Future<void> writeAndEnqueue({
    required Set<String> next,
    required String key,
    required bool present,
  }) async {
    await write(next);
    await engine()?.enqueue(
      SyncMutation.create(
        entity: entity,
        key: key,
        op: present ? SyncOp.upsert : SyncOp.delete,
      ),
    );
  }

  Future<Set<String>> mergeUnion(Set<String> remote) async {
    final local = await read();
    final merged = {...local, ...remote};
    await write(merged);
    final sync = engine();
    if (sync != null) {
      for (final id in merged.difference(remote)) {
        await sync.enqueue(
          SyncMutation.create(
            entity: entity,
            key: id,
            op: SyncOp.upsert,
          ),
        );
      }
    }
    return merged;
  }
}
