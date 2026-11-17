import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/trail_image.dart';
import 'community_providers.dart';

const _key = 'photos_seen_at';

/// Zeitpunkt, bis zu dem der Nutzer Freigaben/Ablehnungen seiner Fotos
/// gesehen hat. `null` = noch nie.
final photosSeenAtProvider =
    AsyncNotifierProvider<PhotosSeenAtNotifier, DateTime?>(
      PhotosSeenAtNotifier.new,
    );

class PhotosSeenAtNotifier extends AsyncNotifier<DateTime?> {
  @override
  Future<DateTime?> build() async {
    final ms = (await SharedPreferences.getInstance()).getInt(_key);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> markSeen() async {
    final now = DateTime.now();
    state = AsyncData(now);
    await (await SharedPreferences.getInstance()).setInt(
      _key,
      now.millisecondsSinceEpoch,
    );
  }
}

/// Fotos mit Entscheidung (freigegeben/abgelehnt), die der Nutzer noch
/// nicht gesehen hat. Leer, solange der Zeitstempel noch lädt.
final unseenDecisionImagesProvider = Provider<List<TrailImage>>((ref) {
  final seenAsync = ref.watch(photosSeenAtProvider);
  if (!seenAsync.hasValue) return const <TrailImage>[];
  final seen = seenAsync.value;
  final images = ref.watch(myImagesProvider).value ?? const <TrailImage>[];
  return [
    for (final i in images)
      if (i.decidedAt != null && (seen == null || i.decidedAt!.isAfter(seen)))
        i,
  ];
});

final hasUnseenDecisionProvider = Provider<bool>(
  (ref) => ref.watch(unseenDecisionImagesProvider).isNotEmpty,
);
