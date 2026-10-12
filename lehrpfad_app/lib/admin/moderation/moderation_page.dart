import 'package:flutter/material.dart';
import 'package:flutter_avif/flutter_avif.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../features/community/data/community_providers.dart';
import '../../features/community/domain/photo_geo_check.dart';
import '../../features/community/domain/trail_image.dart';
import '../../features/community/presentation/fullscreen_image_viewer.dart';
import '../collections/trails_collection.dart';
import '../core/admin_repository.dart';
import '../core/field_spec.dart';

/// Stationstitel zu den Bildern in der Queue (`Station 3: Kranichwiese`).
final moderationStationsProvider =
    FutureProvider.family<Map<int, String>, String>((ref, ids) async {
      final list = ids
          .split(',')
          .where((s) => s.isNotEmpty)
          .map(int.parse)
          .toList();
      if (list.isEmpty) return const <int, String>{};
      final rows = await ref
          .watch(adminClientProvider)
          .from('stations')
          .select('id,reihenfolge,titel')
          .inFilter('id', list);
      return {
        for (final r in rows)
          r['id'] as int: 'Station ${r['reihenfolge']}: ${r['titel']}',
      };
    });

/// Freigabe-Queue für Nutzerfotos: Freigeben oder Ablehnen (löscht Bild
/// samt Dateien). Eintrag in der Admin-Sidebar unter „Moderation“.
class ModerationPage extends ConsumerWidget {
  const ModerationPage({super.key});

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
    final theme = Theme.of(context);
    final pending = ref.watch(pendingImagesProvider);
    final trailRows = ref.watch(collectionRowsProvider(trailsCollection)).value;
    final trailNames = <String, String>{
      for (final r in trailRows ?? const <DbRow>[])
        r['id'] as String: (r['name'] as String?) ?? r['id'] as String,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 20, 24, 12),
          child: Text('Moderation', style: theme.textTheme.headlineSmall),
        ),
        const Divider(height: 1, color: AppColors.n200),
        Expanded(
          child: pending.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Fehler: $e')),
            data: (images) {
              if (images.isEmpty) {
                return const Center(child: Text('Keine Bilder zur Prüfung.'));
              }
              final stationIds = {
                for (final i in images)
                  if (i.stationId != null) i.stationId!,
              }.toList()..sort();
              final stations =
                  ref
                      .watch(moderationStationsProvider(stationIds.join(',')))
                      .value ??
                  const <int, String>{};
              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                itemCount: images.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 24, color: AppColors.n200),
                itemBuilder: (context, i) {
                  final image = images[i];
                  return _PendingRow(
                    image: image,
                    trail: trailNames[image.trailId] ?? image.trailId,
                    zuordnung: image.stationId == null
                        ? 'Ganze Strecke'
                        : (stations[image.stationId] ??
                              'Station #${image.stationId}'),
                    onOpen: () =>
                        FullscreenImageViewer.open(context, images, i),
                    onApprove: () => _approve(ref, image),
                    onReject: () => _reject(ref, context, image),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PendingRow extends StatelessWidget {
  const _PendingRow({
    required this.image,
    required this.trail,
    required this.zuordnung,
    required this.onOpen,
    required this.onApprove,
    required this.onReject,
  });

  final TrailImage image;
  final String trail;
  final String zuordnung;
  final VoidCallback onOpen;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: AppColors.inkMuted,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Tooltip(
          message: 'Vergrößern',
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onOpen,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkAvifImage(
                  image.thumbUrl,
                  width: 96,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    width: 96,
                    height: 72,
                    color: AppColors.n100,
                    child: const Icon(Icons.broken_image_outlined, size: 20),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(trail, style: theme.textTheme.titleSmall),
              Text(zuordnung, style: muted),
              const SizedBox(height: 6),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _GeoCheck(image.geoCheck),
                  Text(image.formatLabel, style: muted),
                  Text(_pixelSize(image), style: muted),
                  Text(_fileSizes(image), style: muted),
                  Text(image.credit.isEmpty ? '—' : image.credit, style: muted),
                  Text(_fmt(image.createdAt), style: muted),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        TextButton(onPressed: onReject, child: const Text('Ablehnen')),
        const SizedBox(width: 4),
        FilledButton(onPressed: onApprove, child: const Text('Freigeben')),
      ],
    );
  }
}

String _fmt(DateTime d) {
  final local = d.toLocal();
  final dd = local.day.toString().padLeft(2, '0');
  final mm = local.month.toString().padLeft(2, '0');
  return '$dd.$mm.${local.year}';
}

String _pixelSize(TrailImage image) {
  final w = image.width;
  final h = image.height;
  if (w == null || h == null) return '—';
  return '$w × $h';
}

String _fileSizes(TrailImage image) {
  final parts = [
    _fmtBytes(image.thumbBytes),
    _fmtBytes(image.smallBytes),
    _fmtBytes(image.mediumBytes),
  ];
  if (parts.every((p) => p == '—')) return '—';
  return parts.join(' · ');
}

String _fmtBytes(int? n) {
  if (n == null) return '—';
  if (n < 1024) return '$n B';
  final kb = n / 1024;
  if (kb < 1024) {
    if (kb >= 10) return '${kb.round()} KB';
    return '${kb.toStringAsFixed(1)} KB';
  }
  return '${(kb / 1024).toStringAsFixed(1)} MB';
}

/// Ampel aus der lokalen Foto-Ort-Prüfung des Uploaders. Nur ein Hinweis
/// für die Moderation, keine Freigabe.
class _GeoCheck extends StatelessWidget {
  const _GeoCheck(this.check);

  final PhotoGeoCheck? check;

  @override
  Widget build(BuildContext context) {
    final c = check;
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted);
    if (c == null) return Text('Ort: —', style: style);
    final (color, label) = switch (c) {
      PhotoGeoCheck.match => (const Color(0xFF2E9E5B), 'Passt zum Trail'),
      PhotoGeoCheck.near => (const Color(0xFFF2A100), 'Grob in der Nähe'),
      PhotoGeoCheck.far => (const Color(0xFFD64545), 'Weit entfernt'),
      PhotoGeoCheck.none => (const Color(0xFF9E9E9E), 'Kein GPS'),
    };
    return Tooltip(
      message: 'Hinweis aus dem Foto-Ort, keine Freigabe',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: style),
        ],
      ),
    );
  }
}
