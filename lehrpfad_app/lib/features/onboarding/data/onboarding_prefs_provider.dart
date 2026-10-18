import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../location/location_permission_controller.dart';
import '../../location/user_position_provider.dart';
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

  /// Gewählter Ort ersetzt den Gerätestandort: Standort aus, gespeicherte
  /// Position weg.
  Future<void> setPlace(UserPlace place) async {
    state = AsyncData(_current.copyWith(place: place));
    await _store.writePlace(place);
    await ref.read(userPositionProvider.notifier).clearStored();
  }

  /// Gerätestandort ersetzt den gewählten Ort. Ort und Standort schließen sich
  /// aus, darum läuft jeder Wechsel zum Standort hierüber.
  Future<void> useDevicePosition() async {
    state = AsyncData(_current.copyWith(clearPlace: true));
    await _store.writePlace(null);
    await ref.read(mapLocationEnabledProvider.notifier).setEnabled(true);
  }

  /// Kein Startpunkt mehr: Ort weg, Standort aus, gespeicherte Position weg.
  Future<void> clearStartpoint() async {
    state = AsyncData(_current.copyWith(clearPlace: true));
    await _store.writePlace(null);
    await ref.read(userPositionProvider.notifier).clearStored();
  }

  Future<void> complete() async {
    if (_current.completed) return;
    state = AsyncData(_current.copyWith(completed: true));
    await _store.writeCompleted();
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

/// Onboarding-Flag, `loading` bis die Prefs gelesen sind.
final onboardingCompletedProvider = Provider<AsyncValue<bool>>((ref) {
  return ref.watch(onboardingPrefsProvider).whenData((p) => p.completed);
});

/// True nur wenn Prefs geladen und Onboarding noch offen.
final onboardingActiveProvider = Provider<bool>((ref) {
  return ref.watch(onboardingCompletedProvider).asData?.value == false;
});
