/// Persistierte „gesehen“-Markierungen (Species-IDs).
abstract class SightingsRepository {
  Future<Set<String>> getSeenIds();

  /// Schreibt das komplette Seen-Set (last-wins, kein Local-Re-Read).
  Future<void> persistSeenIds(Set<String> ids);

  /// Persistiert [ids] und synced die geaenderte [speciesId] remote (soft-fail).
  Future<void> applySeenChange({
    required Set<String> ids,
    required String speciesId,
    required bool seen,
  });

  /// Toggle einer ID via Local-Read (Tests / Legacy); Prefer [applySeenChange].
  Future<void> setSeen(String speciesId, bool seen);
}
