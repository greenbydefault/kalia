import 'package:flutter/material.dart';
import 'package:flutter_avif/flutter_avif.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/overlay_badge.dart';
import '../../../shared/widgets/page_dots.dart';
import '../data/community_providers.dart';
import '../domain/trail_image.dart';
import 'delete_trail_image.dart';
import 'fullscreen_image_viewer.dart';

/// Bilder-Karussell im Trail-Sheet: alle freigegebenen Bilder, die zum
/// ganzen Trail gehoeren (nicht zu einer Station). Eigene noch nicht
/// freigegebene Bilder erscheinen mit „In Prüfung"-Badge.
class TrailImageCarousel extends ConsumerStatefulWidget {
  final String trailId;

  const TrailImageCarousel({super.key, required this.trailId});

  @override
  ConsumerState<TrailImageCarousel> createState() =>
      _TrailImageCarouselState();
}

class _TrailImageCarouselState extends ConsumerState<TrailImageCarousel> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<bool> _deleteImage(TrailImage image) {
    return deleteTrailImage(ref, image: image, trailId: widget.trailId);
  }

  @override
  Widget build(BuildContext context) {
    final imagesAsync = ref.watch(trailImagesProvider(widget.trailId));
    final isAdmin = ref.watch(isAdminProvider);
    final theme = Theme.of(context);

    final images = imagesAsync.value
            ?.where((img) => img.stationId == null)
            .toList() ??
        const <TrailImage>[];
    if (images.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _controller,
              itemCount: images.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final image = images[i];
                final canDelete = image.isMine || isAdmin;
                return GestureDetector(
                  onTap: () => FullscreenImageViewer.open(
                    context,
                    images,
                    i,
                    onDelete: canDelete ? _deleteImage : null,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkAvifImage(
                        image.smallUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                      if (image.credit.isNotEmpty)
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: OverlayBadge(text: '© ${image.credit}'),
                        ),
                      if (!image.isApproved)
                        const Positioned(
                          left: 8,
                          top: 8,
                          child: OverlayBadge(text: 'In Prüfung'),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        if (images.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: PageDots(count: images.length, index: _index),
          ),
      ],
    );
  }
}
