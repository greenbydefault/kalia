import 'dart:convert';

import '../../../core/cache/prefs_store.dart';
import '../domain/age_group.dart';
import '../domain/user_place.dart';

/// Lokaler Onboarding-Zustand (alles optional, alles ohne Konto).
class OnboardingPrefs {
  const OnboardingPrefs({
    this.ageGroups = const {},
    this.stroller = false,
    this.place,
    this.useLocation = false,
    this.coachMarkSeen = false,
    this.accountPromptSeen = false,
    this.saveToastSeen = false,
  });

  final Set<AgeGroup> ageGroups;
  final bool stroller;
  final UserPlace? place;
  final bool useLocation;
  final bool coachMarkSeen;
  final bool accountPromptSeen;

  /// Toast „Gemerkt. Ganz ohne Konto.“ wurde schon gezeigt.
  final bool saveToastSeen;

  /// Kürzeste empfohlene Länge in km, `null` wenn nichts gewählt.
  int? get maxLaengeKm => AgeGroup.minKm(ageGroups);

  OnboardingPrefs copyWith({
    Set<AgeGroup>? ageGroups,
    bool? stroller,
    UserPlace? place,
    bool clearPlace = false,
    bool? useLocation,
    bool? coachMarkSeen,
    bool? accountPromptSeen,
    bool? saveToastSeen,
  }) {
    return OnboardingPrefs(
      ageGroups: ageGroups ?? this.ageGroups,
      stroller: stroller ?? this.stroller,
      place: clearPlace ? null : (place ?? this.place),
      useLocation: useLocation ?? this.useLocation,
      coachMarkSeen: coachMarkSeen ?? this.coachMarkSeen,
      accountPromptSeen: accountPromptSeen ?? this.accountPromptSeen,
      saveToastSeen: saveToastSeen ?? this.saveToastSeen,
    );
  }
}

class OnboardingPrefsStore {
  OnboardingPrefsStore({PrefsStore? prefs}) : _prefs = prefs ?? PrefsStore();

  static const ageGroupsKey = 'onb_age_groups';
  static const strollerKey = 'onb_stroller';
  static const placeKey = 'onb_place';
  static const useLocationKey = 'onb_use_location';
  static const coachMarkSeenKey = 'onb_coach_mark_seen';
  static const accountPromptSeenKey = 'onb_account_prompt_seen';
  static const saveToastSeenKey = 'onb_save_toast_seen';

  final PrefsStore _prefs;

  Future<OnboardingPrefs> read() async {
    final groups = <AgeGroup>{};
    final rawGroups = await _prefs.readString(ageGroupsKey);
    if (rawGroups != null && rawGroups.isNotEmpty) {
      try {
        for (final name in (jsonDecode(rawGroups) as List).cast<String>()) {
          final g = AgeGroup.tryParse(name);
          if (g != null) groups.add(g);
        }
      } catch (_) {}
    }
    UserPlace? place;
    final rawPlace = await _prefs.readString(placeKey);
    if (rawPlace != null && rawPlace.isNotEmpty) {
      try {
        place = UserPlace.fromJson(
          jsonDecode(rawPlace) as Map<String, dynamic>,
        );
      } catch (_) {}
    }
    return OnboardingPrefs(
      ageGroups: groups,
      stroller: await _prefs.readBool(strollerKey),
      place: place,
      useLocation: await _prefs.readBool(useLocationKey),
      coachMarkSeen: await _prefs.readBool(coachMarkSeenKey),
      accountPromptSeen: await _prefs.readBool(accountPromptSeenKey),
      saveToastSeen: await _prefs.readBool(saveToastSeenKey),
    );
  }

  Future<void> writeGroups(
    Set<AgeGroup> groups, {
    required bool stroller,
  }) async {
    await _prefs.writeString(
      ageGroupsKey,
      jsonEncode([for (final g in groups) g.name]..sort()),
    );
    await _prefs.writeBool(strollerKey, stroller);
  }

  Future<void> writePlace(UserPlace? place) async {
    await _prefs.writeString(
      placeKey,
      place == null ? '' : jsonEncode(place.toJson()),
    );
  }

  Future<void> writeUseLocation(bool value) =>
      _prefs.writeBool(useLocationKey, value);

  Future<void> writeCoachMarkSeen() => _prefs.writeBool(coachMarkSeenKey, true);

  Future<void> writeAccountPromptSeen() =>
      _prefs.writeBool(accountPromptSeenKey, true);

  Future<void> writeSaveToastSeen() => _prefs.writeBool(saveToastSeenKey, true);
}
