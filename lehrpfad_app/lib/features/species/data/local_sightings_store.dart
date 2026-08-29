import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/cache/prefs_store.dart';
import 'legacy_sightings_file_stub.dart'
    if (dart.library.io) 'legacy_sightings_file_io.dart';

/// Persistenz fuer gesehene Species-IDs.
abstract class SightingsStore {
  Future<Set<String>> read();
  Future<void> write(Set<String> ids);
}

/// Gesehene Species-IDs in SharedPreferences (Web + Native).
class LocalSightingsStore implements SightingsStore {
  LocalSightingsStore({PrefsStore? prefs}) : _prefs = prefs ?? PrefsStore();

  static const _prefsKey = 'species_sightings';

  final PrefsStore _prefs;
  Future<void>? _migrateFuture;

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
      final prefs = await _prefs.instance();
      await _ensureMigrated(prefs);
      return _prefs.readStringSet(_prefsKey);
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> write(Set<String> ids) async {
    final prefs = await _prefs.instance();
    await _ensureMigrated(prefs);
    await _prefs.writeStringSet(_prefsKey, ids);
  }
}
