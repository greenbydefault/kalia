import 'eignung_score.dart';
import 'trail.dart';

/// Kinderwagen-Näherung aus Tags und Barrierefreiheit (kein eigenes Feld).
bool isStrollerFriendly(Trail t) {
  final tags = t.alleTags;
  if (tags.contains('kinderwagentauglich') ||
      tags.contains('rollstuhltauglich')) {
    return true;
  }
  return scoreEignungen(t).barriere.level >= 4;
}
