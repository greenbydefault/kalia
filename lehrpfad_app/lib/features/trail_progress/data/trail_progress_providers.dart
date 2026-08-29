import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/supabase_client_provider.dart';
import '../../../core/sync/optimistic_id_set_notifier.dart';
import '../../../core/sync/sync_providers.dart';
import '../domain/completion_source.dart';
import '../domain/trail_completion.dart';
import '../domain/trail_walk.dart';
import '../domain/walk_status.dart';
import 'hybrid_trail_progress_repository.dart';
import 'supabase_trail_progress_repository.dart';
import 'trail_progress_repository.dart';

final trailProgressRepositoryProvider = Provider<TrailProgressRepository>((
  ref,
) {
  final client = ref.watch(supabaseClientProvider);
  final remote = client == null
      ? null
      : SupabaseTrailProgressRepository(client);
  final repo = HybridTrailProgressRepository(remote: remote);
  final engine = ref.watch(syncEngineProvider);
  if (remote != null) repo.attach(engine);
  return repo;
});

final trailBookmarksProvider =
    NotifierProvider<TrailBookmarksNotifier, AsyncValue<Set<String>>>(
      TrailBookmarksNotifier.new,
    );

final trailCompletionsProvider =
    NotifierProvider<
      TrailCompletionsNotifier,
      AsyncValue<Map<String, TrailCompletion>>
    >(TrailCompletionsNotifier.new);

final activeWalkProvider =
    NotifierProvider<ActiveWalkNotifier, AsyncValue<TrailWalk?>>(
      ActiveWalkNotifier.new,
    );

class TrailBookmarksNotifier extends OptimisticIdSetNotifier {
  TrailProgressRepository get _repo =>
      ref.read(trailProgressRepositoryProvider);

  @override
  Future<Set<String>> loadIds() => _repo.getBookmarkIds();

  @override
  Future<void> persistChange({
    required String id,
    required bool included,
    required Set<String> next,
  }) {
    return _repo.setBookmarked(id, included);
  }

  Future<void> setBookmarked(String trailId, bool bookmarked) =>
      setIncluded(trailId, bookmarked);

  bool isBookmarked(String trailId) => containsId(trailId);
}

class TrailCompletionsNotifier
    extends Notifier<AsyncValue<Map<String, TrailCompletion>>> {
  @override
  AsyncValue<Map<String, TrailCompletion>> build() {
    _load();
    return const AsyncLoading();
  }

  TrailProgressRepository get _repo =>
      ref.read(trailProgressRepositoryProvider);

  Future<void> _load() async {
    try {
      state = AsyncData(await _repo.getCompletions());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> setCompleted(
    String trailId, {
    required bool completed,
    CompletionSource source = CompletionSource.manual,
  }) async {
    final previous = state.asData?.value ?? {};
    final next = {...previous};
    if (completed) {
      next[trailId] = TrailCompletion(
        trailId: trailId,
        completedAt: DateTime.now().toUtc(),
        source: source,
      );
    } else {
      next.remove(trailId);
    }
    state = AsyncData(next);
    try {
      await _repo.setCompleted(trailId, completed: completed, source: source);
    } catch (_) {
      state = AsyncData(previous);
    }
  }

  bool isCompleted(String trailId) =>
      state.asData?.value.containsKey(trailId) ?? false;
}

class ActiveWalkNotifier extends Notifier<AsyncValue<TrailWalk?>> {
  @override
  AsyncValue<TrailWalk?> build() {
    _load();
    return const AsyncLoading();
  }

  TrailProgressRepository get _repo =>
      ref.read(trailProgressRepositoryProvider);

  Future<void> _load() async {
    try {
      state = AsyncData(await _repo.getActiveWalk());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<TrailWalk> startWalk(String trailId) async {
    final now = DateTime.now().toUtc();
    final walk = TrailWalk(
      id: const Uuid().v4(),
      trailId: trailId,
      status: WalkStatus.active,
      startedAt: now,
      updatedAt: now,
    );
    await _repo.saveWalk(walk);
    state = AsyncData(walk);
    return walk;
  }

  Future<void> updateWalk(TrailWalk walk) async {
    state = AsyncData(walk);
    await _repo.saveWalk(walk);
  }

  Future<void> completeWalk(
    TrailWalk walk, {
    CompletionSource source = CompletionSource.gps,
  }) async {
    final now = DateTime.now().toUtc();
    final done = walk.copyWith(
      status: WalkStatus.completed,
      completedAt: now,
      updatedAt: now,
      progressRatio: 1,
      clearLastPosition: true,
    );
    await _repo.saveWalk(done);
    await ref
        .read(trailCompletionsProvider.notifier)
        .setCompleted(walk.trailId, completed: true, source: source);
    state = const AsyncData(null);
  }

  Future<void> abandonWalk() async {
    final current = state.asData?.value;
    if (current == null) return;
    final now = DateTime.now().toUtc();
    await _repo.saveWalk(
      current.copyWith(
        status: WalkStatus.abandoned,
        updatedAt: now,
        clearLastPosition: true,
      ),
    );
    state = const AsyncData(null);
  }
}
