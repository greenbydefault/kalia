/// Ein Kommentar zu einem Trail.
class TrailComment {
  final int id;
  final String trailId;
  final String authorName;
  final String text;
  final DateTime createdAt;
  final bool isMine;

  const TrailComment({
    required this.id,
    required this.trailId,
    required this.authorName,
    required this.text,
    required this.createdAt,
    required this.isMine,
  });
}
