import 'package:flutter/material.dart';
import 'package:flutter_avif/flutter_avif.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../trail/data/providers.dart';
import '../../trail/domain/trail.dart';
import '../data/community_providers.dart';
import '../domain/trail_image.dart';
import 'fullscreen_image_viewer.dart';

/// Admin-Bereich: pending-Bilder in einer Tabelle freigeben oder
/// ablehnen. Ablehnen loescht Bild samt Dateien.
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
    final trails = ref.watch(trailsProvider).value ?? const <Trail>[];
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
          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      headingRowHeight: 48,
                      dataRowMinHeight: 76,
                      dataRowMaxHeight: 96,
                      columns: const [
                        DataColumn(label: Text('Bild')),
                        DataColumn(label: Text('Trail')),
                        DataColumn(label: Text('Zuordnung')),
                        DataColumn(label: Text('Format')),
                        DataColumn(label: Text('Größe')),
                        DataColumn(label: Text('Credit')),
                        DataColumn(label: Text('Datum')),
                        DataColumn(label: Text('')),
                      ],
                      rows: [
                        for (var i = 0; i < images.length; i++)
                          DataRow(
                            cells: [
                              DataCell(
                                Tooltip(
                                  message: 'Vergrößern',
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: CachedNetworkAvifImage(
                                        images[i].thumbUrl,
                                        width: 64,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stack) =>
                                            Container(
                                              width: 64,
                                              height: 48,
                                              color: theme
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                              child: const Icon(
                                                Icons.broken_image_outlined,
                                                size: 20,
                                              ),
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                                onTap: () => FullscreenImageViewer.open(
                                  context,
                                  images,
                                  i,
                                ),
                              ),
                              DataCell(
                                Text(_trailName(trails, images[i].trailId)),
                              ),
                              DataCell(Text(_zuordnung(trails, images[i]))),
                              DataCell(Text(images[i].formatLabel)),
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(_pixelSize(images[i])),
                                    Text(
                                      _fileSizes(images[i]),
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Text(
                                  images[i].credit.isEmpty
                                      ? '—'
                                      : images[i].credit,
                                ),
                              ),
                              DataCell(Text(_fmt(images[i].createdAt))),
                              DataCell(
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: () =>
                                          _reject(ref, context, images[i]),
                                      child: const Text('Ablehnen'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          _approve(ref, images[i]),
                                      child: const Text('Freigeben'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

String _trailName(List<Trail> trails, String id) {
  for (final t in trails) {
    if (t.id == id) return t.name;
  }
  return id;
}

String _zuordnung(List<Trail> trails, TrailImage image) {
  if (image.stationId == null) return 'Ganze Strecke';
  for (final t in trails) {
    if (t.id != image.trailId) continue;
    for (final s in t.stationen) {
      if (s.id == image.stationId) {
        return 'Station ${s.reihenfolge}: ${s.titel}';
      }
    }
  }
  return 'Station #${image.stationId}';
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
