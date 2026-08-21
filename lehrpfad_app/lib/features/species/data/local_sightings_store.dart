import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'legacy_sightings_file_stub.dart'
    if (dart.library.io) 'legacy_sightings_file_io.dart';

/// Persistenz fuer gesehene Species-IDs.
abstract class SightingsStore {
  Future<Set<String>> read();
  Future<void> write(Set<String> ids);
}

/// Gesehene Species-IDs in SharedPreferences (Web + Native).
class LocalSightingsStore implements SightingsStore {
  static const _prefsKey = 'species_sightings';

  SharedPreferences? _prefs;
  Future<void>? _migrateFuture;

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _ensureMigrated(SharedPreferences prefs) {
    return _migrateFuture ??= _migrateIfNeeded(prefs);
  }

  Future<void> _migrateIfNeeded(SharedPreferences prefs) async {
    if (prefs.containsKey(_prefsKey)) return;
    final legacy = await readLegacySightingsFile();
    if (legacy == null) return;
    await prefs.setString(
      _prefsKey,
      jsonEncode(legacy.toList()..sort()),
    );
  }

  @override
  Future<Set<String>> read() async {
    try {
      final prefs = await _getPrefs();
      await _ensureMigrated(prefs);
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return {};
      final list = jsonDecode(raw) as List;
      return list.cast<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> write(Set<String> ids) async {
    final prefs = await _getPrefs();
    await _ensureMigrated(prefs);
    await prefs.setString(
      _prefsKey,
      jsonEncode(ids.toList()..sort()),
    );
  }
}
