import '../domain/completion_source.dart';
import '../domain/trail_completion.dart';
import '../domain/trail_walk.dart';

/// Persistenz für Merken, Gelaufen und Touren.
abstract class TrailProgressRepository {
  Future<Set<String>> getBookmarkIds();
  Future<void> setBookmarked(String trailId, bool bookmarked);

  Future<Map<String, TrailCompletion>> getCompletions();
  Future<void> setCompleted(
    String trailId, {
    required bool completed,
    CompletionSource source = CompletionSource.manual,
  });

  Future<TrailWalk?> getActiveWalk();
  Future<List<TrailWalk>> getWalks();
  Future<void> saveWalk(TrailWalk walk);
  Future<void> clearActiveWalk();

  Future<void> mergeWithRemote({
    required Set<String> remoteBookmarks,
    required Map<String, TrailCompletion> remoteCompletions,
    required List<TrailWalk> remoteWalks,
  });
}
