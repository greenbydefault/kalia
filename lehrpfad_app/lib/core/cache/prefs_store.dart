import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Ein SharedPreferences-Handle plus String/Set-JSON.
class PrefsStore {
  SharedPreferences? _prefs;

  Future<SharedPreferences> instance() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<String?> readString(String key) async {
    return (await instance()).getString(key);
  }

  Future<void> writeString(String key, String value) async {
    await (await instance()).setString(key, value);
  }

  Future<Set<String>> readStringSet(String key) async {
    try {
      final raw = await readString(key);
      if (raw == null || raw.isEmpty) return {};
      return (jsonDecode(raw) as List).cast<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> writeStringSet(String key, Set<String> ids) async {
    await writeString(key, jsonEncode(ids.toList()..sort()));
  }

  Future<bool> readBool(String key, {bool fallback = false}) async {
    return (await instance()).getBool(key) ?? fallback;
  }

  Future<void> writeBool(String key, bool value) async {
    await (await instance()).setBool(key, value);
  }
}
