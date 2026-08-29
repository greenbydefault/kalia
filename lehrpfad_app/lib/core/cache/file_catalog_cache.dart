import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'catalog_cache.dart';

/// Native: JSON-Dateien im App-Support-Verzeichnis.
class FileCatalogCache implements CatalogCache {
  @override
  Future<String?> read(String key) async {
    try {
      final file = await _file(key);
      if (!file.existsSync()) return null;
      return file.readAsString();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      final file = await _file(key);
      await file.writeAsString(value);
    } catch (_) {
      // Schreibfehler ignorieren – frische Daten sind bereits da.
    }
  }

  Future<File> _file(String key) async {
    final dir = await getApplicationSupportDirectory();
    final safe = key.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return File('${dir.path}/$safe.json');
  }
}
