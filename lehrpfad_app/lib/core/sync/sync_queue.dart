import 'dart:convert';

import '../cache/prefs_store.dart';
import 'sync_mutation.dart';

/// Persistente FIFO-Queue für fehlgeschlagene Remote-Mutationen.
///
/// Zwei Schutzmechanismen:
/// - Coalescing: pro (entity, key) nur die neueste Mutation, damit
///   z. B. das 20-Sekunden-Walk-Tracking die Queue bei Offline-Touren
///   nicht flutet.
/// - Cap: bei [maxEntries] werden die ältesten Einträge verworfen,
///   als Schutz vor SharedPreferences-Überlauf.
class SyncQueue {
  SyncQueue({PrefsStore? prefs}) : _prefs = prefs ?? PrefsStore();

  static const _prefsKey = 'sync_queue_v1';
  static const maxEntries = 500;

  final PrefsStore _prefs;

  Future<List<SyncMutation>> readAll() async {
    try {
      final raw = await _prefs.readString(_prefsKey);
      if (raw == null || raw.isEmpty) return [];
      return (jsonDecode(raw) as List)
          .map((e) => SyncMutation.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<SyncMutation?> peek() async {
    final all = await readAll();
    return all.isEmpty ? null : all.first;
  }

  /// Hängt [mutation] an; eine vorhandene Mutation mit gleichem
  /// (entity, key) wird dabei ersetzt (Coalescing).
  Future<void> enqueue(SyncMutation mutation) async {
    final all = await readAll();
    all.removeWhere(
      (m) => m.entity == mutation.entity && m.key == mutation.key,
    );
    all.add(mutation);
    while (all.length > maxEntries) {
      all.removeAt(0);
    }
    await _write(all);
  }

  Future<void> remove(String id) async {
    final all = await readAll();
    all.removeWhere((m) => m.id == id);
    await _write(all);
  }

  Future<void> clear() => _write(const []);

  Future<void> _write(List<SyncMutation> all) async {
    await _prefs.writeString(
      _prefsKey,
      jsonEncode([for (final m in all) m.toJson()]),
    );
  }
}
