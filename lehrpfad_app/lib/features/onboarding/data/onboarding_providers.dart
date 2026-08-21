import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_guest_profile_store.dart';

final guestProfileStoreProvider = Provider<LocalGuestProfileStore>(
  (ref) => LocalGuestProfileStore(),
);

final onboardingCompletedProvider =
    AsyncNotifierProvider<OnboardingCompletedNotifier, bool>(
      OnboardingCompletedNotifier.new,
    );

class OnboardingCompletedNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() {
    return ref.watch(guestProfileStoreProvider).isCompleted();
  }

  Future<void> complete({
    required String displayName,
    required List<String> childNames,
  }) async {
    await ref
        .read(guestProfileStoreProvider)
        .complete(displayName: displayName, childNames: childNames);
    state = const AsyncData(true);
    ref.invalidate(guestProfileProvider);
  }
}

final guestProfileProvider =
    AsyncNotifierProvider<GuestProfileNotifier, GuestProfile>(
      GuestProfileNotifier.new,
    );

class GuestProfileNotifier extends AsyncNotifier<GuestProfile> {
  @override
  Future<GuestProfile> build() {
    return ref.watch(guestProfileStoreProvider).readProfile();
  }
}

/// True nur wenn Prefs geladen und Onboarding noch offen.
final onboardingActiveProvider = Provider<bool>((ref) {
  return ref.watch(onboardingCompletedProvider).asData?.value == false;
});
