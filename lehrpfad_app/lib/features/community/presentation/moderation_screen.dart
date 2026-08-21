import 'package:flutter/material.dart';
import 'package:flutter_avif/flutter_avif.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/community_providers.dart';
import '../domain/trail_image.dart';

/// Admin-Bereich: alle Bilder mit Status „pending" pruefen, freigeben
/// oder ablehnen. Ablehnen loescht Bild samt Dateien endgültig, damit
/// keine ungeprueften Inhalte im Storage liegen bleiben.
class ModerationScreen extends ConsumerWidget {
  const ModerationScreen({super.key});

  Future<void> _approve(WidgetRef ref, TrailImage image) async {
    final repo = ref.read(imagesRepositoryProvider);
    if (repo == null) return;
    await repo.setImageStatus(image.id, TrailImageStatus.approved);
    ref.invalidate(pendingImagesProvider);
    ref.invalidate(trailImagesProvider(image.trailId));
  }

  Future<void> _reject(
    WidgetRef ref,
    BuildContext context,
    TrailImage image,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bild ablehnen?'),
        content: const Text(
          'Das Bild und alle Dateien werden dauerhaft gelöscht.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ablehnen'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final repo = ref.read(imagesRepositoryProvider);
    if (repo == null) return;
    await repo.deleteImage(image);
    ref.invalidate(pendingImagesProvider);
    ref.invalidate(trailImagesProvider(image.trailId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingImagesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Moderation')),
      body: pendingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (images) {
          if (images.isEmpty) {
            return const Center(child: Text('Keine Bilder zur Prüfung.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: images.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final image = images[i];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: CachedNetworkAvifImage(
                        image.smallUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            image.stationId == null
                                ? 'Ganze Strecke (${image.trailId})'
                                : 'Station #${image.stationId} '
                                    '(${image.trailId})',
                            style: theme.textTheme.bodySmall,
                          ),
                          if (image.credit.isNotEmpty)
                            Text(
                              '© ${image.credit}',
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    OverflowBar(
                      alignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _reject(ref, context, image),
                          icon: const Icon(Icons.close),
                          label: const Text('Ablehnen'),
                        ),
                        FilledButton.icon(
                          onPressed: () => _approve(ref, image),
                          icon: const Icon(Icons.check),
                          label: const Text('Freigeben'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
