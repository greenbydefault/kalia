import 'dart:convert';

import '../../../core/cache/prefs_store.dart';

class GuestProfile {
  const GuestProfile({this.displayName = '', this.childNames = const []});

  final String displayName;
  final List<String> childNames;

  bool get isEmpty => displayName.isEmpty && childNames.isEmpty;
}

/// Lokales Gast-Profil und First-Run-Flag in SharedPreferences.
class LocalGuestProfileStore {
  LocalGuestProfileStore({PrefsStore? prefs}) : _prefs = prefs ?? PrefsStore();

  static const completedKey = 'onboarding_completed';
  static const nameKey = 'guest_display_name';
  static const childrenKey = 'guest_child_names';

  final PrefsStore _prefs;

  static List<String> trimChildren(Iterable<String> names) {
    return [
      for (final name in names)
        if (name.trim().isNotEmpty) name.trim(),
    ];
  }

  Future<bool> isCompleted() => _prefs.readBool(completedKey);

  Future<GuestProfile> readProfile() async {
    final raw = await _prefs.readString(childrenKey);
    List<String> children = const [];
    if (raw != null && raw.isNotEmpty) {
      try {
        children = trimChildren((jsonDecode(raw) as List).cast<String>());
      } catch (_) {
        children = const [];
      }
    }
    return GuestProfile(
      displayName: ((await _prefs.readString(nameKey)) ?? '').trim(),
      childNames: children,
    );
  }

  Future<void> complete({
    required String displayName,
    required List<String> childNames,
  }) async {
    await _prefs.writeString(nameKey, displayName.trim());
    await _prefs.writeString(childrenKey, jsonEncode(trimChildren(childNames)));
    await _prefs.writeBool(completedKey, true);
  }
}
