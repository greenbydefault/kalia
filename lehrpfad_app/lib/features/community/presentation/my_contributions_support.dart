import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/kalia_image.dart';
import '../../trail/data/providers.dart';
import '../../trail_progress/presentation/open_trail_on_map.dart';
import '../domain/trail_image.dart';

/// Trailname je Trail-ID für „Meine Beiträge“. Fehlt der Trail (noch nicht
/// geladen, nicht mehr sichtbar), steht die ID als Fallback in der UI.
final trailNamesProvider = Provider<Map<String, String>>((ref) {
  final trails = ref.watch(trailsProvider).value ?? const [];
  return {for (final t in trails) t.id: t.name};
});

/// Öffnet den Pfad auf der Karte. Aus Unterseiten wird vorher bis zur
/// Shell zurückgegangen.
Future<void> openContributionTrail(
  BuildContext context,
  WidgetRef ref,
  String trailId,
) async {
  final trails = ref.read(trailsProvider).value ?? const [];
  final trail = trails.where((t) => t.id == trailId).firstOrNull;
  if (trail == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Der Pfad ist gerade nicht verfügbar.'),
      ),
    );
    return;
  }
  Navigator.of(context).popUntil((r) => r.isFirst);
  await openTrailOnMap(context, ref, trail);
}

String formatDay(DateTime date) {
  final d = date.toLocal();
  return '${d.day}.${d.month}.${d.year}';
}

/// Kurzlabel des Moderationsstatus aus Nutzersicht.
String statusLabel(TrailImageStatus s) => switch (s) {
  TrailImageStatus.pending => 'In Prüfung',
  TrailImageStatus.approved => 'Freigegeben',
  TrailImageStatus.rejected => 'Abgelehnt',
};

Color statusColor(TrailImageStatus s) => switch (s) {
  TrailImageStatus.pending => AppColors.scrim54,
  TrailImageStatus.approved => AppColors.statusOk,
  TrailImageStatus.rejected => AppColors.statusError,
};

/// Offene und abgelehnte Fotos zuerst (da ist etwas zu tun oder zu lesen),
/// dann die übrigen. Die Reihenfolge innerhalb bleibt „neueste zuerst“.
List<TrailImage> prioritized(List<TrailImage> images) {
  int rank(TrailImage i) => switch (i.status) {
    TrailImageStatus.rejected => 0,
    TrailImageStatus.pending => 1,
    TrailImageStatus.approved => 2,
  };
  final indexed = images.indexed.toList()
    ..sort((a, b) {
      final r = rank(a.$2).compareTo(rank(b.$2));
      return r != 0 ? r : a.$1.compareTo(b.$1);
    });
  return [for (final e in indexed) e.$2];
}

/// Quadratische Vorschau eines eigenen Fotos mit Status-Badge unten links
/// und „Neu“-Punkt oben rechts, wenn die Entscheidung ungesehen war.
class MyPhotoTile extends StatelessWidget {
  const MyPhotoTile({
    super.key,
    required this.image,
    required this.onTap,
    this.isNew = false,
  });

  final TrailImage image;
  final VoidCallback onTap;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'Foto, ${statusLabel(image.status)}',
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              KaliaImage(
                trailId: image.trailId,
                imageId: image.id,
                slot: TrailImageVariant.thumb,
                thumbhash: image.thumbhash,
                dominantColor: image.dominantColor,
                fit: BoxFit.cover,
              ),
              Positioned(
                left: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor(image.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel(image.status),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.n50,
                    ),
                  ),
                ),
              ),
              if (isNew)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    key: const ValueKey('photo-new'),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.n50,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.n950, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
