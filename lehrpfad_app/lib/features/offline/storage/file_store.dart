/// Dateiablage für Offline-Medien (Fotos, später Audio/Tiles).
///
/// Schlüssel sind relative Pfade (`images/<trail>/<id>/small.avif`).
/// Die UI liest nur über den Resolver, nie direkt aus dem Store.
abstract interface class FileStore {
  /// Absoluter Pfad, wenn die Datei existiert, sonst `null`. Synchron, damit
  /// der Resolver im `build` auflösen kann.
  String? pathIfExists(String key);

  /// Schreibt atomar (Temp-Datei + Rename), gibt den Zielpfad zurück.
  Future<String> write(String key, List<int> bytes);

  Future<void> delete(String key);

  /// Gesamtgröße aller Dateien im Store in Bytes.
  Future<int> usedBytes();
}

/// Web und Tests ohne Plattform: nichts lokal, Schreiben nicht unterstützt.
class NullFileStore implements FileStore {
  const NullFileStore();

  @override
  String? pathIfExists(String key) => null;

  @override
  Future<String> write(String key, List<int> bytes) =>
      throw UnsupportedError('Kein Dateispeicher auf dieser Plattform');

  @override
  Future<void> delete(String key) async {}

  @override
  Future<int> usedBytes() async => 0;
}
