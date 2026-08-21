import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class GuestProfile {
  const GuestProfile({this.displayName = '', this.childNames = const []});

  final String displayName;
  final List<String> childNames;

  bool get isEmpty => displayName.isEmpty && childNames.isEmpty;
}

/// Lokales Gast-Profil und First-Run-Flag in SharedPreferences.
class LocalGuestProfileStore {
  static const completedKey = 'onboarding_completed';
  static const nameKey = 'guest_display_name';
  static const childrenKey = 'guest_child_names';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  static List<String> trimChildren(Iterable<String> names) {
    return [
      for (final name in names)
        if (name.trim().isNotEmpty) name.trim(),
    ];
  }

  Future<bool> isCompleted() async {
    final prefs = await _getPrefs();
    return prefs.getBool(completedKey) ?? false;
  }

  Future<GuestProfile> readProfile() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(childrenKey);
    List<String> children = const [];
    if (raw != null && raw.isNotEmpty) {
      try {
        children = trimChildren((jsonDecode(raw) as List).cast<String>());
      } catch (_) {
        children = const [];
      }
    }
    return GuestProfile(
      displayName: (prefs.getString(nameKey) ?? '').trim(),
      childNames: children,
    );
  }

  Future<void> complete({
    required String displayName,
    required List<String> childNames,
  }) async {
    final prefs = await _getPrefs();
    await prefs.setString(nameKey, displayName.trim());
    await prefs.setString(childrenKey, jsonEncode(trimChildren(childNames)));
    await prefs.setBool(completedKey, true);
  }
}
