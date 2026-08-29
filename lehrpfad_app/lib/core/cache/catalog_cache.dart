/// Persistenter String-Store für Katalog-JSON (Trails, Species, Merkmale, Orte).
///
/// Zwei Adapter: File (native) und Prefs (Web). Tests nutzen [MemoryCatalogCache].
abstract class CatalogCache {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

/// In-Memory-Adapter für Tests am öffentlichen Seam.
class MemoryCatalogCache implements CatalogCache {
  final Map<String, String> _store = {};

  @override
  Future<String?> read(String key) async => _store[key];

  @override
  Future<void> write(String key, String value) async {
    _store[key] = value;
  }
}
