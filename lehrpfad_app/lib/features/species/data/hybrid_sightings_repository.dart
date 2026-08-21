import 'local_sightings_store.dart';
import 'sightings_repository.dart';
import 'supabase_sightings_repository.dart';

/// Lokal immer; Remote optional (wenn [remote] gesetzt und User eingeloggt).
class HybridSightingsRepository implements SightingsRepository {
  HybridSightingsRepository({
    SightingsStore? local,
    this.remote,
  }) : _local = local ?? LocalSightingsStore();

  final SightingsStore _local;
  final SupabaseSightingsRepository? remote;

  @override
  Future<Set<String>> getSeenIds() => _local.read();

  @override
  Future<void> persistSeenIds(Set<String> ids) => _local.write(ids);

  @override
  Future<void> applySeenChange({
    required Set<String> ids,
    required String speciesId,
    required bool seen,
  }) async {
    await persistSeenIds(ids);
    await _syncRemoteId(speciesId, seen);
  }

  @override
  Future<void> setSeen(String speciesId, bool seen) async {
    final previous = await _local.read();
    final next = {...previous};
    if (seen) {
      next.add(speciesId);
    } else {
      next.remove(speciesId);
    }
    await applySeenChange(ids: next, speciesId: speciesId, seen: seen);
  }

  Future<void> _syncRemoteId(String speciesId, bool seen) async {
    final r = remote;
    if (r == null) return;
    try {
      if (seen) {
        await r.markSeen(speciesId);
      } else {
        await r.markUnseen(speciesId);
      }
    } catch (_) {
      // Local ist Source of Truth; Merge beim Login heilt Divergenz.
    }
  }

  @override
  Future<Set<String>> mergeWithRemote(Set<String> remoteIds) async {
    final local = await _local.read();
    final merged = {...local, ...remoteIds};
    await persistSeenIds(merged);
    final r = remote;
    if (r != null) {
      final missingRemote = merged.difference(remoteIds);
      if (missingRemote.isNotEmpty) {
        try {
          await r.upsertAll(missingRemote);
        } catch (_) {
          // Offline nach Merge: lokal behalten
        }
      }
    }
    return merged;
  }
}
