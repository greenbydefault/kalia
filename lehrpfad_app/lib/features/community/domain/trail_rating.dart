/// Aggregierte Sterne-Bewertung eines Trails plus der eigenen Bewertung
/// (falls eingeloggt und bereits abgegeben).
class TrailRating {
  final double average;
  final int count;
  final int? myStars;

  const TrailRating({
    required this.average,
    required this.count,
    required this.myStars,
  });

  static const empty = TrailRating(average: 0, count: 0, myStars: null);
}
