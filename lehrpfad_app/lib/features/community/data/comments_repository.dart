import '../domain/trail_comment.dart';

/// Datenzugriff auf Kommentare pro Trail.
abstract interface class CommentsRepository {
  Future<List<TrailComment>> getComments(String trailId);

  Future<void> addComment(String trailId, String text);

  /// Eigene Kommentare bzw. als Admin.
  Future<void> deleteComment(int commentId);
}
