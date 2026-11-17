import 'dart:convert';

import '../../../core/cache/prefs_store.dart';
import '../domain/fund.dart';
import 'local_sightings_store.dart';

/// Persistenz für Funde (ID + Datum, Pfad, Wer).
abstract class FundeStore {
  Future<Map<String, Fund>> read();
  Future<void> write(Map<String, Fund> funde);
}

/// Funde als JSON-Map in SharedPreferences (Web + Native).
///
/// Beim ersten Lesen ohne eigenen Key wird der Altbestand (nur IDs, Key
/// `species_sightings`) übernommen; diese Funde haben kein Datum.
class LocalFundeStore implements FundeStore {
  LocalFundeStore({PrefsStore? prefs, SightingsStore? legacy})
    : _prefs = prefs ?? PrefsStore(),
      _legacy = legacy ?? LocalSightingsStore(prefs: prefs);

  static const _prefsKey = 'species_funde';

  final PrefsStore _prefs;
  final SightingsStore _legacy;

  @override
  Future<Map<String, Fund>> read() async {
    try {
      final raw = await _prefs.readString(_prefsKey);
      if (raw == null) {
        final ids = await _legacy.read();
        return {for (final id in ids) id: Fund(speciesId: id)};
      }
      if (raw.isEmpty) return {};
      final decoded = jsonDecode(raw) as Map;
      return {
        for (final e in decoded.entries)
          e.key as String: Fund.fromJson(
            e.key as String,
            Map<String, dynamic>.from(e.value as Map),
          ),
      };
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> write(Map<String, Fund> funde) async {
    final sorted = funde.keys.toList()..sort();
    await _prefs.writeString(
      _prefsKey,
      jsonEncode({for (final id in sorted) id: funde[id]!.toJson()}),
    );
  }
}
