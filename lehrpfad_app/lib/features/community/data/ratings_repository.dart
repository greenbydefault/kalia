import '../domain/trail_rating.dart';

/// Datenzugriff auf Sterne-Bewertungen (pro Trail und User genau eine).
abstract interface class RatingsRepository {
  Future<TrailRating> getRating(String trailId);

  /// Legt die eigene Bewertung an oder aktualisiert sie (Upsert).
  Future<void> setRating(String trailId, int stars);

  /// Entfernt die eigene Bewertung.
  Future<void> removeRating(String trailId);
}
