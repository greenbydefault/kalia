import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/supabase_config.dart';
import '../../auth/data/auth_providers.dart';
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
  if (SupabaseConfig.isConfigured) {
    return HybridTrailProgressRepository(
      remote: SupabaseTrailProgressRepository(Supabase.instance.client),
    );
  }
  return HybridTrailProgressRepository();
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

class TrailBookmarksNotifier extends Notifier<AsyncValue<Set<String>>> {
  @override
  AsyncValue<Set<String>> build() {
    _listenAuth();
    _load();
    return const AsyncLoading();
  }

  TrailProgressRepository get _repo =>
      ref.read(trailProgressRepositoryProvider);

  void _listenAuth() {
    if (!SupabaseConfig.isConfigured) return;
    ref.listen(authStateProvider, (prev, next) {
      final user = next.asData?.value;
      final hadUser = prev?.asData?.value != null;
      if (user != null && !hadUser) {
        ref.read(trailCompletionsProvider.notifier).mergeOnLogin();
        ref.read(activeWalkProvider.notifier).mergeOnLogin();
        _mergeOnLogin();
      }
    });
  }

  Future<void> _load() async {
    try {
      state = AsyncData(await _repo.getBookmarkIds());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> _mergeOnLogin() async {
    final remote = SupabaseTrailProgressRepository(Supabase.instance.client);
    try {
      final remoteIds = await remote.fetchBookmarkIds();
      final local = await _repo.getBookmarkIds();
      await _repo.mergeWithRemote(
        remoteBookmarks: remoteIds,
        remoteCompletions: const {},
        remoteWalks: const [],
      );
      state = AsyncData({...local, ...remoteIds});
    } catch (_) {}
  }

  Future<void> setBookmarked(String trailId, bool bookmarked) async {
    final previous = state.asData?.value ?? {};
    final next = {...previous};
    if (bookmarked) {
      next.add(trailId);
    } else {
      next.remove(trailId);
    }
    state = AsyncData(next);
    try {
      await _repo.setBookmarked(trailId, bookmarked);
    } catch (_) {
      state = AsyncData(previous);
    }
  }

  bool isBookmarked(String trailId) =>
      state.asData?.value.contains(trailId) ?? false;
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

  Future<void> mergeOnLogin() async {
    if (!SupabaseConfig.isConfigured) return;
    final remote = SupabaseTrailProgressRepository(Supabase.instance.client);
    try {
      final remoteMap = await remote.fetchCompletions();
      await _repo.mergeWithRemote(
        remoteBookmarks: const {},
        remoteCompletions: remoteMap,
        remoteWalks: const [],
      );
      state = AsyncData(await _repo.getCompletions());
    } catch (_) {}
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

  Future<void> mergeOnLogin() async {
    if (!SupabaseConfig.isConfigured) return;
    final remote = SupabaseTrailProgressRepository(Supabase.instance.client);
    try {
      final remoteWalks = await remote.fetchWalks();
      await _repo.mergeWithRemote(
        remoteBookmarks: const {},
        remoteCompletions: const {},
        remoteWalks: remoteWalks,
      );
      state = AsyncData(await _repo.getActiveWalk());
    } catch (_) {}
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
