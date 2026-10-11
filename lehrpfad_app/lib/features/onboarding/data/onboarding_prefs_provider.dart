import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/age_group.dart';
import '../domain/user_place.dart';
import 'onboarding_prefs_store.dart';

final onboardingPrefsStoreProvider = Provider<OnboardingPrefsStore>(
  (ref) => OnboardingPrefsStore(),
);

final onboardingPrefsProvider =
    AsyncNotifierProvider<OnboardingPrefsNotifier, OnboardingPrefs>(
      OnboardingPrefsNotifier.new,
    );

/// Synchroner Zugriff: Default, solange Prefs noch laden.
final onboardingPrefsValueProvider = Provider<OnboardingPrefs>((ref) {
  return ref.watch(onboardingPrefsProvider).asData?.value ??
      const OnboardingPrefs();
});

class OnboardingPrefsNotifier extends AsyncNotifier<OnboardingPrefs> {
  OnboardingPrefsStore get _store => ref.read(onboardingPrefsStoreProvider);

  @override
  Future<OnboardingPrefs> build() =>
      ref.read(onboardingPrefsStoreProvider).read();

  OnboardingPrefs get _current =>
      state.asData?.value ?? const OnboardingPrefs();

  Future<void> setGroups(Set<AgeGroup> groups, {required bool stroller}) async {
    state = AsyncData(_current.copyWith(ageGroups: groups, stroller: stroller));
    await _store.writeGroups(groups, stroller: stroller);
  }

  Future<void> setPlace(UserPlace place) async {
    state = AsyncData(_current.copyWith(place: place, useLocation: false));
    await _store.writePlace(place);
    await _store.writeUseLocation(false);
  }

  Future<void> setUseLocation(bool value) async {
    state = AsyncData(
      value
          ? _current.copyWith(useLocation: true, clearPlace: true)
          : _current.copyWith(useLocation: false),
    );
    await _store.writeUseLocation(value);
    if (value) await _store.writePlace(null);
  }

  Future<void> markCoachMarkSeen() async {
    if (_current.coachMarkSeen) return;
    state = AsyncData(_current.copyWith(coachMarkSeen: true));
    await _store.writeCoachMarkSeen();
  }

  Future<void> markAccountPromptSeen() async {
    if (_current.accountPromptSeen) return;
    state = AsyncData(_current.copyWith(accountPromptSeen: true));
    await _store.writeAccountPromptSeen();
  }

  Future<void> markSaveToastSeen() async {
    if (_current.saveToastSeen) return;
    state = AsyncData(_current.copyWith(saveToastSeen: true));
    await _store.writeSaveToastSeen();
  }
}
