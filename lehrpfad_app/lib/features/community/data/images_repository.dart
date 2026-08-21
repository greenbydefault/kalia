import '../domain/trail_image.dart';

/// Datenzugriff auf Bilder (Trail- und Stations-Bilder).
abstract interface class ImagesRepository {
  /// Alle fuer den aktuellen User sichtbaren Bilder eines Trails.
  /// Anonym/ausgeloggt: nur freigegebene. Eingeloggt: zusaetzlich eigene
  /// (jeden Status), Admins: alle (RLS serverseitig).
  Future<List<TrailImage>> getImages(String trailId);

  /// Alle Bilder mit Status pending (nur Admins, sonst leer durch RLS).
  Future<List<TrailImage>> getPendingImages();

  /// Moderation: Status setzen (nur Admins).
  Future<void> setImageStatus(String imageId, TrailImageStatus status);

  /// Loescht DB-Eintrag und die drei Storage-Varianten
  /// (eigene Bilder oder Admin).
  Future<void> deleteImage(TrailImage image);
}
