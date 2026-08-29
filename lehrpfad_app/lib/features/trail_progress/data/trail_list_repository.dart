import '../domain/trail_list.dart';

/// Persistenz für eigene Listen. Lokal immer; Remote optional nach Login.
abstract class TrailListRepository {
  Future<List<TrailList>> getLists();
  Future<TrailList> createList(String name);
  Future<void> renameList(String id, String name);
  Future<void> deleteList(String id);
  Future<void> setInList({
    required String listId,
    required String trailId,
    required bool inList,
  });
}
