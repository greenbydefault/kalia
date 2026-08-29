import 'catalog_cache.dart';

/// Remote → Cache write; bei Fehler Cache-Decode, sonst Seed.
Future<T> loadCatalog<T>({
  required CatalogCache cache,
  required String key,
  required Future<T> Function() remote,
  required Future<T> Function(String raw) decode,
  required String Function(T value) encode,
  required Future<T> Function() seed,
  bool skipWrite = false,
}) async {
  try {
    final value = await remote();
    if (!skipWrite) {
      await cache.write(key, encode(value));
    }
    return value;
  } catch (_) {
    try {
      final raw = await cache.read(key);
      if (raw != null && raw.isNotEmpty) {
        return await decode(raw);
      }
    } catch (_) {
      // Korrupter Cache → Seed
    }
    return seed();
  }
}
