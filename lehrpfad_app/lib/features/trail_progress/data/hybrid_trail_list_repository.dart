import 'package:uuid/uuid.dart';

import '../../../core/sync/sync_engine.dart';
import '../../../core/sync/sync_mutation.dart';
import '../domain/trail_list.dart';
import 'local_trail_list_store.dart';
import 'supabase_trail_list_repository.dart';
import 'trail_list_repository.dart';

/// Sync-Queue-Entities für eigene Listen.
const trailListSyncEntity = 'trail_list';
const trailListItemSyncEntity = 'trail_list_item';

/// Lokal immer; Remote optional (Login). `setInList(true)` merkt den Trail mit.
/// Remote-Ausführung und Login-Merge laufen über die [SyncEngine].
class HybridTrailListRepository implements TrailListRepository {
  HybridTrailListRepository({
    TrailListStore? local,
    SupabaseTrailListRepository? remote,
    this.onAddedToList,
  }) : _local = local ?? LocalTrailListStore(),
       _remote = remote;

  final TrailListStore _local;
  final SupabaseTrailListRepository? _remote;
  SyncEngine? _engine;
  final Future<void> Function(String trailId)? onAddedToList;

  /// Registriert Executor/Merge an der Engine. Aufruf im Provider, vor flush.
  void attach(SyncEngine engine) {
    _engine = engine;
    final r = _remote;
    if (r == null) return;
    engine.registerExecutor(trailListSyncEntity, (m) async {
      if (m.op == SyncOp.delete.name) {
        await r.deleteList(m.key);
      } else {
        await r.upsertList(TrailList.fromMetaJson(m.payload));
      }
    });
    engine.registerExecutor(trailListItemSyncEntity, (m) async {
      if (m.op == SyncOp.delete.name) {
        await r.deleteItem(
          listId: m.payload['listId'] as String,
          trailId: m.payload['trailId'] as String,
        );
      } else {
        await r.upsertItem(TrailListItem.fromJson(m.payload));
      }
    });
    engine.registerMergeHandler(trailListSyncEntity, () async {
      await mergeWithRemote(await r.fetchLists());
    });
  }
  final _uuid = const Uuid();

  static const maxNameLength = 80;

  @override
  Future<List<TrailList>> getLists() => _joined();

  @override
  Future<TrailList> createList(String name) async {
    final trimmed = _requireName(name);
    final now = DateTime.now().toUtc();
    final list = TrailList(
      id: _uuid.v4(),
      name: trimmed,
      createdAt: now,
      updatedAt: now,
    );
    final lists = await _local.readLists();
    await _local.writeLists([...lists, list]);
    await _enqueueList(list, SyncOp.upsert);
    return list;
  }

  @override
  Future<void> renameList(String id, String name) async {
    final trimmed = _requireName(name);
    final lists = await _local.readLists();
    final index = lists.indexWhere((list) => list.id == id);
    if (index < 0) {
      throw StateError('Liste nicht gefunden.');
    }
    final now = DateTime.now().toUtc();
    final updated = lists[index].copyWith(name: trimmed, updatedAt: now);
    final next = [...lists];
    next[index] = updated;
    await _local.writeLists(next);
    await _enqueueList(updated, SyncOp.upsert);
  }

  @override
  Future<void> deleteList(String id) async {
    final lists = await _local.readLists();
    await _local.writeLists([
      for (final list in lists)
        if (list.id != id) list,
    ]);
    final items = await _local.readItems();
    await _local.writeItems([
      for (final item in items)
        if (item.listId != id) item,
    ]);
    await _engine?.enqueue(
      SyncMutation.create(
        entity: trailListSyncEntity,
        key: id,
        op: SyncOp.delete,
      ),
    );
  }

  @override
  Future<void> setInList({
    required String listId,
    required String trailId,
    required bool inList,
  }) async {
    final lists = await _local.readLists();
    if (!lists.any((list) => list.id == listId)) {
      throw StateError('Liste nicht gefunden.');
    }
    final items = await _local.readItems();
    final exists = items.any(
      (item) => item.listId == listId && item.trailId == trailId,
    );
    if (inList && exists) return;
    if (!inList && !exists) return;

    final now = DateTime.now().toUtc();
    if (inList) {
      final item = TrailListItem(
        listId: listId,
        trailId: trailId,
        addedAt: now,
      );
      await _local.writeItems([...items, item]);
      await _touchList(listId, now);
      await _engine?.enqueue(
        SyncMutation.create(
          entity: trailListItemSyncEntity,
          key: '$listId|$trailId',
          op: SyncOp.upsert,
          payload: item.toJson(),
        ),
      );
      await onAddedToList?.call(trailId);
      return;
    }

    await _local.writeItems([
      for (final item in items)
        if (!(item.listId == listId && item.trailId == trailId)) item,
    ]);
    await _touchList(listId, now);
    await _engine?.enqueue(
      SyncMutation.create(
        entity: trailListItemSyncEntity,
        key: '$listId|$trailId',
        op: SyncOp.delete,
        payload: {'listId': listId, 'trailId': trailId},
      ),
    );
  }

  Future<void> mergeWithRemote(List<TrailList> remoteLists) async {
    final localLists = await _local.readLists();
    final localItems = await _local.readItems();
    final remoteItems = [for (final list in remoteLists) ...list.items];

    final listsById = <String, TrailList>{
      for (final list in remoteLists) list.id: list.copyWith(items: const []),
    };
    for (final local in localLists) {
      final existing = listsById[local.id];
      if (existing == null) {
        listsById[local.id] = local.copyWith(items: const []);
        continue;
      }
      final localNewer = !existing.updatedAt.isAfter(local.updatedAt);
      listsById[local.id] = TrailList(
        id: local.id,
        name: localNewer ? local.name : existing.name,
        createdAt: local.createdAt.isBefore(existing.createdAt)
            ? local.createdAt
            : existing.createdAt,
        updatedAt: localNewer ? local.updatedAt : existing.updatedAt,
      );
    }

    final itemsByKey = <String, TrailListItem>{};
    for (final item in [...remoteItems, ...localItems]) {
      final key = '${item.listId}|${item.trailId}';
      final existing = itemsByKey[key];
      if (existing == null || item.addedAt.isBefore(existing.addedAt)) {
        itemsByKey[key] = item;
      }
    }

    final mergedLists = listsById.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final mergedItems = itemsByKey.values.toList();
    await _local.writeLists(mergedLists);
    await _local.writeItems(mergedItems);

    final engine = _engine;
    if (engine == null) return;
    final remoteListIds = {for (final list in remoteLists) list.id};
    final remoteItemKeys = {
      for (final item in remoteItems) '${item.listId}|${item.trailId}',
    };
    for (final list in mergedLists) {
      if (!remoteListIds.contains(list.id)) {
        await _enqueueList(list, SyncOp.upsert);
      }
    }
    for (final item in mergedItems) {
      if (!remoteItemKeys.contains('${item.listId}|${item.trailId}')) {
        await engine.enqueue(
          SyncMutation.create(
            entity: trailListItemSyncEntity,
            key: '${item.listId}|${item.trailId}',
            op: SyncOp.upsert,
            payload: item.toJson(),
          ),
        );
      }
    }
  }

  Future<List<TrailList>> _joined() async {
    final lists = await _local.readLists();
    final items = await _local.readItems();
    final byList = <String, List<TrailListItem>>{};
    for (final item in items) {
      byList.putIfAbsent(item.listId, () => []).add(item);
    }
    final joined = [
      for (final list in lists)
        list.copyWith(items: List.unmodifiable(byList[list.id] ?? const [])),
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return joined;
  }

  Future<void> _touchList(String id, DateTime now) async {
    final lists = await _local.readLists();
    await _local.writeLists([
      for (final list in lists)
        if (list.id == id) list.copyWith(updatedAt: now) else list,
    ]);
    final updated = lists.where((list) => list.id == id);
    if (updated.isEmpty) return;
    await _enqueueList(updated.first.copyWith(updatedAt: now), SyncOp.upsert);
  }

  Future<void> _enqueueList(TrailList list, SyncOp op) async {
    await _engine?.enqueue(
      SyncMutation.create(
        entity: trailListSyncEntity,
        key: list.id,
        op: op,
        payload: list.toMetaJson(),
      ),
    );
  }

  String _requireName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Listenname darf nicht leer sein.');
    }
    if (trimmed.length > maxNameLength) {
      throw ArgumentError('Listenname ist zu lang.');
    }
    return trimmed;
  }
}
