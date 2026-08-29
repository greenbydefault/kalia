import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Load + optimistic add/remove + Rollback für ein Id-Set (Gesehen, Merken).
abstract class OptimisticIdSetNotifier
    extends Notifier<AsyncValue<Set<String>>> {
  Future<Set<String>> loadIds();

  Future<void> persistChange({
    required String id,
    required bool included,
    required Set<String> next,
  });

  @override
  AsyncValue<Set<String>> build() {
    _load();
    return const AsyncLoading();
  }

  Future<void> _load() async {
    try {
      state = AsyncData(await loadIds());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> setIncluded(String id, bool included) async {
    final previous = state.asData?.value ?? {};
    final next = {...previous};
    if (included) {
      next.add(id);
    } else {
      next.remove(id);
    }
    state = AsyncData(next);
    try {
      await persistChange(id: id, included: included, next: next);
    } catch (_) {
      state = AsyncData(previous);
    }
  }

  bool containsId(String id) => state.asData?.value.contains(id) ?? false;
}
