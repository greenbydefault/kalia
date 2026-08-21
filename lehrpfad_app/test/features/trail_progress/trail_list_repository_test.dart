import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/features/trail_progress/data/hybrid_trail_list_repository.dart';
import 'package:lehrpfad_app/features/trail_progress/data/local_trail_list_store.dart';
import 'package:lehrpfad_app/features/trail_progress/domain/trail_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryStore implements TrailListStore {
  List<TrailList> lists = [];
  List<TrailListItem> items = [];

  @override
  Future<List<TrailList>> readLists() async => [
    for (final list in lists) list.copyWith(items: const []),
  ];

  @override
  Future<void> writeLists(List<TrailList> next) async {
    lists = [for (final list in next) list.copyWith(items: const [])];
  }

  @override
  Future<List<TrailListItem>> readItems() async => [...items];

  @override
  Future<void> writeItems(List<TrailListItem> next) async {
    items = [...next];
  }
}

void main() {
  late _MemoryStore store;
  late Set<String> bookmarked;
  late HybridTrailListRepository repo;

  setUp(() {
    store = _MemoryStore();
    bookmarked = {};
    repo = HybridTrailListRepository(
      local: store,
      onAddedToList: (id) async {
        bookmarked.add(id);
      },
    );
  });

  test('createList trims name and rejects empty', () async {
    final list = await repo.createList('  Wasserspielplätze  ');
    expect(list.name, 'Wasserspielplätze');
    expect(await repo.getLists(), hasLength(1));
    expect(() => repo.createList('   '), throwsA(isA<ArgumentError>()));
  });

  test('setInList true merkt den Trail mit', () async {
    final list = await repo.createList('MV');
    await repo.setInList(listId: list.id, trailId: 'pfad-a', inList: true);
    final lists = await repo.getLists();
    expect(lists.single.containsTrail('pfad-a'), isTrue);
    expect(bookmarked, {'pfad-a'});
  });

  test('setInList false entfernt Membership, Bookmark bleibt', () async {
    final list = await repo.createList('MV');
    await repo.setInList(listId: list.id, trailId: 'pfad-a', inList: true);
    await repo.setInList(listId: list.id, trailId: 'pfad-a', inList: false);
    expect((await repo.getLists()).single.containsTrail('pfad-a'), isFalse);
    expect(bookmarked, {'pfad-a'});
  });

  test('deleteList entfernt Items, ruft onAddedToList nicht zurück', () async {
    final list = await repo.createList('MV');
    await repo.setInList(listId: list.id, trailId: 'pfad-a', inList: true);
    await repo.deleteList(list.id);
    expect(await repo.getLists(), isEmpty);
    expect(store.items, isEmpty);
    expect(bookmarked, {'pfad-a'});
  });

  test('renameList and missing list throw', () async {
    final list = await repo.createList('Alt');
    await repo.renameList(list.id, 'Neu');
    expect((await repo.getLists()).single.name, 'Neu');
    expect(() => repo.renameList('missing', 'X'), throwsA(isA<StateError>()));
  });

  test('mergeWithRemote unions lists by id and items', () async {
    final local = await repo.createList('Lokal');
    await repo.setInList(
      listId: local.id,
      trailId: 'lokal-trail',
      inList: true,
    );

    final remoteId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
    final remoteCreated = DateTime.utc(2024, 1, 1);
    await repo.mergeWithRemote([
      TrailList(
        id: remoteId,
        name: 'Remote',
        createdAt: remoteCreated,
        updatedAt: remoteCreated,
        items: [
          TrailListItem(
            listId: remoteId,
            trailId: 'remote-trail',
            addedAt: remoteCreated,
          ),
        ],
      ),
      TrailList(
        id: local.id,
        name: 'Lokal-Remote',
        createdAt: DateTime.utc(2020, 1, 1),
        updatedAt: DateTime.utc(2020, 1, 1),
        items: [
          TrailListItem(
            listId: local.id,
            trailId: 'shared-trail',
            addedAt: DateTime.utc(2024, 6, 1),
          ),
        ],
      ),
    ]);

    final lists = await repo.getLists();
    expect(lists.map((l) => l.id), containsAll([local.id, remoteId]));
    final mergedLocal = lists.firstWhere((l) => l.id == local.id);
    expect(mergedLocal.name, 'Lokal');
    expect(mergedLocal.trailIds.toSet(), {'lokal-trail', 'shared-trail'});
    expect(lists.firstWhere((l) => l.id == remoteId).trailIds, [
      'remote-trail',
    ]);
  });

  test('LocalTrailListStore roundtrips via SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({});
    final local = LocalTrailListStore();
    final now = DateTime.utc(2026, 8, 13);
    await local.writeLists([
      TrailList(id: 'list-1', name: 'MV', createdAt: now, updatedAt: now),
    ]);
    await local.writeItems([
      TrailListItem(listId: 'list-1', trailId: 'pfad-a', addedAt: now),
    ]);
    expect((await local.readLists()).single.name, 'MV');
    expect((await local.readItems()).single.trailId, 'pfad-a');
  });
}
