import '../domain/trail_image.dart';

/// Datenzugriff auf Bilder (Trail- und Stations-Bilder).
abstract interface class ImagesRepository {
  /// Alle fuer den aktuellen User sichtbaren Bilder eines Trails.
  /// Anonym/ausgeloggt: nur freigegebene. Eingeloggt: zusaetzlich eigene
  /// (jeden Status), Admins: alle (RLS serverseitig).
  Future<List<TrailImage>> getImages(String trailId);

  /// Alle Bilder mit Status pending (nur Admins, sonst leer durch RLS).
  Future<List<TrailImage>> getPendingImages();

  /// Alle eigenen Uploads (jeder Status), neueste zuerst. Ausgeloggt leer.
  Future<List<TrailImage>> getMyImages();

  /// Moderation: Status setzen (nur Admins). Setzt `decided_at`.
  Future<void> setImageStatus(String imageId, TrailImageStatus status);

  /// Moderation: Bild ablehnen (nur Admins). Die Zeile bleibt mit Grund
  /// erhalten, `small`/`medium` werden aus dem Storage entfernt, das
  /// Thumb bleibt bis [deleteImage].
  Future<void> rejectImage(TrailImage image, RejectReason reason);

  /// Abgelehnte Bilder, deren Entscheidung vor [before] liegt (nur Admins).
  Future<List<TrailImage>> getRejectedBefore(DateTime before);

  /// Loescht DB-Eintrag und die drei Storage-Varianten
  /// (eigene Bilder oder Admin).
  Future<void> deleteImage(TrailImage image);
}
