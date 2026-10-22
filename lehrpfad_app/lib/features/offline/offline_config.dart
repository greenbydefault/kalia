/// Konstanten des Offline-Moduls (Phase 1: Fundament).
abstract final class OfflineConfig {
  /// Mindestabstand zwischen zwei Katalog-Syncs (Start, Resume, Netz zurück).
  static const syncMinInterval = Duration(minutes: 15);

  /// Reachability-Ping: länger als das gilt das Netz als nicht nutzbar.
  static const pingTimeout = Duration(seconds: 8);

  static const dbName = 'kalia_offline';

  /// Gebündelter Katalog (erzeugt von `tools/export_catalog.py`).
  static const seedIndexAsset = 'assets/seed/index.json';
  static const seedSpeciesAsset = 'assets/seed/species.json';
  static const seedDir = 'assets/seed';

  /// Öffentlicher Bucket der Hero-Fotos: `{trailId}/{imageId}/{variant}.avif`.
  static const imageBucket = 'trail-images';

  /// Ordner der Dateien (Fotos, später Audio/Tiles) unter Application Support.
  static const fileStoreDir = 'offline';

  static const trailFetchChunk = 15;
  static const speciesFetchChunk = 60;
}
