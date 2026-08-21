import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../auth/data/auth_providers.dart';
import '../domain/trail_list.dart';
import 'hybrid_trail_list_repository.dart';
import 'supabase_trail_list_repository.dart';
import 'trail_list_repository.dart';
import 'trail_progress_providers.dart';

final trailListRepositoryProvider = Provider<TrailListRepository>((ref) {
  return HybridTrailListRepository(
    remote: SupabaseConfig.isConfigured
        ? SupabaseTrailListRepository(Supabase.instance.client)
        : null,
    onAddedToList: (trailId) {
      return ref
          .read(trailBookmarksProvider.notifier)
          .setBookmarked(trailId, true);
    },
  );
});

final trailListsProvider =
    NotifierProvider<TrailListsNotifier, AsyncValue<List<TrailList>>>(
      TrailListsNotifier.new,
    );

class TrailListsNotifier extends Notifier<AsyncValue<List<TrailList>>> {
  @override
  AsyncValue<List<TrailList>> build() {
    _listenAuth();
    _load();
    return const AsyncLoading();
  }

  TrailListRepository get _repo => ref.read(trailListRepositoryProvider);

  void _listenAuth() {
    if (!SupabaseConfig.isConfigured) return;
    ref.listen(authStateProvider, (prev, next) {
      final user = next.asData?.value;
      final hadUser = prev?.asData?.value != null;
      if (user != null && !hadUser) {
        _mergeOnLogin();
      }
    });
  }

  Future<void> _load() async {
    try {
      state = AsyncData(await _repo.getLists());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> _mergeOnLogin() async {
    if (!SupabaseConfig.isConfigured) return;
    final remote = SupabaseTrailListRepository(Supabase.instance.client);
    try {
      final remoteLists = await remote.fetchLists();
      await _repo.mergeWithRemote(remoteLists);
      state = AsyncData(await _repo.getLists());
    } catch (_) {}
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
