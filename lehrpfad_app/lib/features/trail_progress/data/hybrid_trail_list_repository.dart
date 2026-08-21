import 'package:uuid/uuid.dart';

import '../domain/trail_list.dart';
import 'local_trail_list_store.dart';
import 'supabase_trail_list_repository.dart';
import 'trail_list_repository.dart';

/// Lokal immer; Remote optional (Login). `setInList(true)` merkt den Trail mit.
class HybridTrailListRepository implements TrailListRepository {
  HybridTrailListRepository({
    TrailListStore? local,
    this.remote,
    this.onAddedToList,
  }) : _local = local ?? LocalTrailListStore();

  final TrailListStore _local;
  final SupabaseTrailListRepository? remote;
  final Future<void> Function(String trailId)? onAddedToList;
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
    await _tryRemote(() async {
      await remote?.upsertList(list);
    });
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
    await _tryRemote(() => remote?.upsertList(updated));
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
    await _tryRemote(() => remote?.deleteList(id));
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
      await _tryRemote(() => remote?.upsertItem(item));
      await onAddedToList?.call(trailId);
      return;
    }

    await _local.writeItems([
      for (final item in items)
        if (!(item.listId == listId && item.trailId == trailId)) item,
    ]);
    await _touchList(listId, now);
    await _tryRemote(
      () => remote?.deleteItem(listId: listId, trailId: trailId),
    );
  }

  @override
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

    final remoteListIds = {for (final list in remoteLists) list.id};
    final remoteItemKeys = {
      for (final item in remoteItems) '${item.listId}|${item.trailId}',
    };
    final missingLists = [
      for (final list in mergedLists)
        if (!remoteListIds.contains(list.id)) list,
    ];
    final missingItems = [
      for (final item in mergedItems)
        if (!remoteItemKeys.contains('${item.listId}|${item.trailId}')) item,
    ];
    if (missingLists.isEmpty && missingItems.isEmpty) return;
    await _tryRemote(() async {
      if (missingLists.isNotEmpty) {
        await remote?.upsertLists(missingLists);
      }
      for (final item in missingItems) {
        await remote?.upsertItem(item);
      }
    });
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
    await _tryRemote(
      () => remote?.upsertList(updated.first.copyWith(updatedAt: now)),
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

  Future<void> _tryRemote(Future<void>? Function() action) async {
    if (remote == null) return;
    try {
      await action();
    } catch (_) {
      // Local ist Source of Truth; Merge beim Login heilt Divergenz.
    }
  }
}
