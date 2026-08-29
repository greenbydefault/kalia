import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/community_providers.dart';
import '../domain/trail_image.dart';

/// Löscht ein Bild und invalidiert den Trail-Bilder-Katalog.
Future<bool> deleteTrailImage(
  WidgetRef ref, {
  required TrailImage image,
  required String trailId,
}) async {
  final repo = ref.read(imagesRepositoryProvider);
  if (repo == null) return false;
  try {
    await repo.deleteImage(image);
    ref.invalidate(trailImagesProvider(trailId));
    return true;
  } catch (_) {
    return false;
  }
}
