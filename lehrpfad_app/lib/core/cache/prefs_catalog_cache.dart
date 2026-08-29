import 'package:shared_preferences/shared_preferences.dart';

import 'catalog_cache.dart';

/// Web: SharedPreferences / localStorage. Nur für den Fallback-Pfad,
/// wenn `dart:io` fehlt — nicht für wachsende Trail-Geometrie gedacht.
class PrefsCatalogCache implements CatalogCache {
  static const _prefix = 'catalog_cache_';

  @override
  Future<String?> read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_prefix$key');
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefix$key', value);
    } catch (_) {
      // Quota / Schreibfehler ignorieren.
    }
  }
}
