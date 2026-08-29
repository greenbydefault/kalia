import 'package:flutter/material.dart';
import 'package:flutter_avif/flutter_avif.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/overlay_badge.dart';
import '../data/community_providers.dart';
import '../domain/trail_image.dart';
import 'delete_trail_image.dart';
import 'fullscreen_image_viewer.dart';

/// Horizontale Thumbnail-Reihe der Bilder einer Station (innerhalb der
/// StationCard). Tippt man ein Bild an, oeffnet sich der Vollbild-Viewer.
class StationImageStrip extends ConsumerWidget {
  final String trailId;
  final int stationId;

  const StationImageStrip({
    super.key,
    required this.trailId,
    required this.stationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imagesAsync = ref.watch(trailImagesProvider(trailId));
    final isAdmin = ref.watch(isAdminProvider);
    final theme = Theme.of(context);

    final images = imagesAsync.value
            ?.where((img) => img.stationId == stationId)
            .toList() ??
        const <TrailImage>[];
    if (images.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final image = images[i];
          final canDelete = image.isMine || isAdmin;
          return GestureDetector(
            onTap: () => FullscreenImageViewer.open(
              context,
              images,
              i,
              onDelete: canDelete
                  ? (img) => deleteTrailImage(ref, image: img, trailId: trailId)
                  : null,
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkAvifImage(
                    image.thumbUrl,
                    width: 128,
                    height: 96,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      width: 128,
                      height: 96,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
                if (!image.isApproved)
                  const Positioned(
                    left: 4,
                    top: 4,
                    child: OverlayBadge(text: 'In Prüfung'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
