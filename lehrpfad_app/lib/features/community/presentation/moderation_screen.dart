import 'package:flutter/material.dart';
import 'package:flutter_avif/flutter_avif.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../trail/data/providers.dart';
import '../../trail/domain/trail.dart';
import '../data/community_providers.dart';
import '../domain/trail_image.dart';

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
                      dataRowMinHeight: 72,
                      dataRowMaxHeight: 88,
                      columns: const [
                        DataColumn(label: Text('Bild')),
                        DataColumn(label: Text('Trail')),
                        DataColumn(label: Text('Zuordnung')),
                        DataColumn(label: Text('Credit')),
                        DataColumn(label: Text('Datum')),
                        DataColumn(label: Text('')),
                      ],
                      rows: [
                        for (final image in images)
                          DataRow(
                            cells: [
                              DataCell(
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: CachedNetworkAvifImage(
                                    image.thumbUrl,
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
                              DataCell(Text(_trailName(trails, image.trailId))),
                              DataCell(Text(_zuordnung(trails, image))),
                              DataCell(
                                Text(image.credit.isEmpty ? '—' : image.credit),
                              ),
                              DataCell(Text(_fmt(image.createdAt))),
                              DataCell(
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: () =>
                                          _reject(ref, context, image),
                                      child: const Text('Ablehnen'),
                                    ),
                                    FilledButton(
                                      onPressed: () => _approve(ref, image),
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
