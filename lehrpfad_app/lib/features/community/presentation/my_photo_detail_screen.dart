import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/widgets/kalia_image.dart';
import '../data/community_providers.dart';
import '../domain/trail_image.dart';
import 'delete_trail_image.dart';
import 'my_contributions_support.dart';

/// Ein eigenes Foto mit Status, Grund (bei Ablehnung), Pfad und den zwei
/// Aktionen „Zum Pfad“ und „Entfernen“.
class MyPhotoDetailScreen extends ConsumerWidget {
  const MyPhotoDetailScreen({super.key, required this.image});

  final TrailImage image;

  static Future<void> open(BuildContext context, TrailImage image) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MyPhotoDetailScreen(image: image),
      ),
    );
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Foto entfernen?'),
        content: const Text('Das Foto wird dauerhaft gelöscht.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final deleted = await deleteTrailImage(
      ref,
      image: image,
      trailId: image.trailId,
    );
    if (!context.mounted) return;
    if (deleted) {
      ref.invalidate(myImagesProvider);
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Entfernen hat nicht geklappt. Bitte später nochmal.'),
        ),
      );
    }
  }

  String _statusText() {
    switch (image.status) {
      case TrailImageStatus.pending:
        return 'Wir schauen uns das Foto an. Bis dahin seht nur ihr es.';
      case TrailImageStatus.approved:
        final at = image.decidedAt;
        return at == null
            ? 'Das Foto ist für alle sichtbar.'
            : 'Seit ${formatDay(at)} für alle sichtbar.';
      case TrailImageStatus.rejected:
        final reason = image.rejectReason?.label;
        return reason == null
            ? 'Das Foto passt leider nicht in die Galerie.'
            : 'Grund: $reason. Ihr könnt gern ein neues Foto hochladen.';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final names = ref.watch(trailNamesProvider);
    final trailName = names[image.trailId] ?? image.trailId;
    final rejected = image.isRejected;
    final ratio = (image.width != null && image.height != null)
        ? image.width! / image.height!
        : 4 / 3;

    return Scaffold(
      appBar: AppBar(title: Text(trailName)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ColoredBox(
                color: AppColors.n950,
                child: AspectRatio(
                  aspectRatio: ratio.clamp(0.75, 1.8),
                  child: KaliaImage(
                    trailId: image.trailId,
                    imageId: image.id,
                    // Bei Ablehnung gibt es nur noch das Thumb.
                    slot: rejected
                        ? TrailImageVariant.thumb
                        : TrailImageVariant.medium,
                    thumbhash: image.thumbhash,
                    dominantColor: image.dominantColor,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.stack),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor(image.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel(image.status),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.n50,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.x3),
                Text(
                  'Hochgeladen am ${formatDay(image.createdAt)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x3),
            Text(_statusText(), style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.x2),
            Text(
              image.stationId == null ? 'Ganze Strecke' : 'An einer Station',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.section),
            if (rejected) ...[
              FilledButton.icon(
                onPressed: () => _remove(context, ref),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Entfernen'),
              ),
              const SizedBox(height: AppSpacing.x2),
              OutlinedButton.icon(
                onPressed: () =>
                    openContributionTrail(context, ref, image.trailId),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Zum Pfad'),
              ),
            ] else ...[
              FilledButton.icon(
                onPressed: () =>
                    openContributionTrail(context, ref, image.trailId),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Zum Pfad'),
              ),
              const SizedBox(height: AppSpacing.x2),
              OutlinedButton.icon(
                onPressed: () => _remove(context, ref),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Entfernen'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
