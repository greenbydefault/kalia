import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import '../../onboarding/data/onboarding_prefs_provider.dart';
import '../../trail/domain/trail.dart';
import '../data/trail_list_providers.dart';
import '../data/trail_progress_providers.dart';

const savedWithoutAccountToast = 'Gemerkt. Ganz ohne Konto.';

/// Anzahl gemerkter Pfade (Bookmarks plus Listeneinträge). `null`, solange
/// geladen wird.
final savedTrailCountProvider = Provider<int?>((ref) {
  final bookmarks = ref.watch(trailBookmarksProvider).asData?.value;
  final lists = ref.watch(trailListsProvider).asData?.value;
  if (bookmarks == null || lists == null) return null;
  return {
    ...bookmarks,
    for (final l in lists)
      for (final i in l.items) i.trailId,
  }.length;
});

/// Trail ist gemerkt (Bookmark) oder liegt in einer Liste.
bool isTrailSaved(WidgetRef ref, String trailId) {
  final bookmarked =
      ref.watch(trailBookmarksProvider).asData?.value.contains(trailId) ??
      false;
  final inList =
      ref
          .watch(trailListsProvider)
          .asData
          ?.value
          .any((list) => list.containsTrail(trailId)) ??
      false;
  return bookmarked || inList;
}

/// Herz-Tap: Bookmark direkt lokal setzen, ohne Konto. Das allererste
/// Merken zeigt einmal den Toast.
Future<void> quickToggleMerken(
  BuildContext context,
  WidgetRef ref,
  Trail trail,
) async {
  final was =
      ref.read(trailBookmarksProvider).asData?.value.contains(trail.id) ??
      false;
  await ref.read(trailBookmarksProvider.notifier).setBookmarked(trail.id, !was);
  if (was) return;

  final loggedIn = ref.read(authStateProvider).value != null;
  final prefs = ref.read(onboardingPrefsValueProvider);
  if (loggedIn || prefs.saveToastSeen) return;
  await ref.read(onboardingPrefsProvider.notifier).markSaveToastSeen();
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(savedWithoutAccountToast),
      ),
    );
}
