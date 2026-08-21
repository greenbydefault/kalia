import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/trail_completion.dart';
import '../domain/trail_walk.dart';
import '../domain/walk_status.dart';

/// Lokale Persistenz (SharedPreferences) für Trail-Progress.
class LocalTrailProgressStore {
  static const _bookmarksKey = 'trail_bookmarks';
  static const _completionsKey = 'trail_completions';
  static const _walksKey = 'trail_walks';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<Set<String>> readBookmarks() async {
    try {
      final raw = (await _getPrefs()).getString(_bookmarksKey);
      if (raw == null || raw.isEmpty) return {};
      return (jsonDecode(raw) as List).cast<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> writeBookmarks(Set<String> ids) async {
    await (await _getPrefs()).setString(
      _bookmarksKey,
      jsonEncode(ids.toList()..sort()),
    );
  }

  Future<Map<String, TrailCompletion>> readCompletions() async {
    try {
      final raw = (await _getPrefs()).getString(_completionsKey);
      if (raw == null || raw.isEmpty) return {};
      final list = jsonDecode(raw) as List;
      final map = <String, TrailCompletion>{};
      for (final item in list) {
        final c = TrailCompletion.fromJson(item as Map<String, dynamic>);
        map[c.trailId] = c;
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  Future<void> writeCompletions(Map<String, TrailCompletion> map) async {
    final list = map.values.map((c) => c.toJson()).toList()
      ..sort(
        (a, b) => (a['trailId'] as String).compareTo(b['trailId'] as String),
      );
    await (await _getPrefs()).setString(_completionsKey, jsonEncode(list));
  }

  Future<List<TrailWalk>> readWalks() async {
    try {
      final raw = (await _getPrefs()).getString(_walksKey);
      if (raw == null || raw.isEmpty) return [];
      return (jsonDecode(raw) as List)
          .map((e) => TrailWalk.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> writeWalks(List<TrailWalk> walks) async {
    await (await _getPrefs()).setString(
      _walksKey,
      jsonEncode(walks.map((w) => w.toJson()).toList()),
    );
  }

  Future<TrailWalk?> readActiveWalk() async {
    final walks = await readWalks();
    for (final w in walks) {
      if (w.status == WalkStatus.active) return w;
    }
    return null;
  }
}
