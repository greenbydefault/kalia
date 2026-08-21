import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/trail_list.dart';

/// Zwei Keys analog SQL: `trail_lists` + `trail_list_items`.
abstract class TrailListStore {
  Future<List<TrailList>> readLists();
  Future<void> writeLists(List<TrailList> lists);
  Future<List<TrailListItem>> readItems();
  Future<void> writeItems(List<TrailListItem> items);
}

class LocalTrailListStore implements TrailListStore {
  static const listsKey = 'trail_lists';
  static const itemsKey = 'trail_list_items';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  @override
  Future<List<TrailList>> readLists() async {
    try {
      final raw = (await _getPrefs()).getString(listsKey);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List;
      return [
        for (final item in list)
          TrailList.fromMetaJson(item as Map<String, dynamic>),
      ];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> writeLists(List<TrailList> lists) async {
    final encoded = jsonEncode([for (final list in lists) list.toMetaJson()]);
    await (await _getPrefs()).setString(listsKey, encoded);
  }

  @override
  Future<List<TrailListItem>> readItems() async {
    try {
      final raw = (await _getPrefs()).getString(itemsKey);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List;
      return [
        for (final item in list)
          TrailListItem.fromJson(item as Map<String, dynamic>),
      ];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> writeItems(List<TrailListItem> items) async {
    final encoded = jsonEncode([for (final item in items) item.toJson()]);
    await (await _getPrefs()).setString(itemsKey, encoded);
  }
}
