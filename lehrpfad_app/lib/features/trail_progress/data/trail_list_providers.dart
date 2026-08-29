import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/supabase_client_provider.dart';
import '../../../core/sync/sync_providers.dart';
import '../domain/trail_list.dart';
import 'hybrid_trail_list_repository.dart';
import 'supabase_trail_list_repository.dart';
import 'trail_list_repository.dart';
import 'trail_progress_providers.dart';

final trailListRepositoryProvider = Provider<TrailListRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final remote = client == null ? null : SupabaseTrailListRepository(client);
  final repo = HybridTrailListRepository(
    remote: remote,
    onAddedToList: (trailId) {
      return ref
          .read(trailBookmarksProvider.notifier)
          .setBookmarked(trailId, true);
    },
  );
  final engine = ref.watch(syncEngineProvider);
  if (remote != null) repo.attach(engine);
  return repo;
});

final trailListsProvider =
    NotifierProvider<TrailListsNotifier, AsyncValue<List<TrailList>>>(
      TrailListsNotifier.new,
    );

class TrailListsNotifier extends Notifier<AsyncValue<List<TrailList>>> {
  @override
  AsyncValue<List<TrailList>> build() {
    _load();
    return const AsyncLoading();
  }

  TrailListRepository get _repo => ref.read(trailListRepositoryProvider);

  Future<void> _load() async {
    try {
      state = AsyncData(await _repo.getLists());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<TrailList> createList(String name) async {
    final list = await _repo.createList(name);
    state = AsyncData(await _repo.getLists());
    return list;
  }

  Future<void> renameList(String id, String name) async {
    await _repo.renameList(id, name);
    state = AsyncData(await _repo.getLists());
  }

  Future<void> deleteList(String id) async {
    await _repo.deleteList(id);
    state = AsyncData(await _repo.getLists());
  }

  Future<void> setInList({
    required String listId,
    required String trailId,
    required bool inList,
  }) async {
    await _repo.setInList(listId: listId, trailId: trailId, inList: inList);
    state = AsyncData(await _repo.getLists());
  }

  bool containsTrail(String trailId) {
    final lists = state.asData?.value ?? const [];
    return lists.any((list) => list.containsTrail(trailId));
  }
}
