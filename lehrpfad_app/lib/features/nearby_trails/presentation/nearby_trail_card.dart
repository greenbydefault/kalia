import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/catalogs/icon_catalog.dart';
import '../../community/domain/trail_image.dart';
import '../../player/data/mini_player_provider.dart';
import '../../player/presentation/equalizer_bars.dart';
import '../../location/proximity.dart';
import '../../trail/presentation/map/trail_hero.dart';
import '../../trail_progress/presentation/open_trail_on_map.dart';
import '../../trail_progress/presentation/quick_merken.dart';
import '../data/nearby_trails_provider.dart';
import '../domain/anfahrt.dart';

/// Pfad-Karte der Nähe-Liste: Thumbnail, Tag, Name, Fakten, Hören + Merken.
class NearbyTrailCard extends ConsumerWidget {
  const NearbyTrailCard({super.key, required this.entry, this.hoerenKey});

  final NearbyTrailEntry entry;

  /// Ziel für den Coach-Mark (nur erste Karte).
  final GlobalKey? hoerenKey;

  static const double height = 220;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final trail = entry.trail;
    final typ = typEintrag(trail.typ);
    final bild = TrailHero.pagesFor(trail).first;
    final saved = isTrailSaved(ref, trail.id);
    final playing = ref.watch(
      miniPlayerProvider.select(
        (s) => s != null && s.trail.id == trail.id && s.playing,
      ),
    );
    final distance = entry.distanceM;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.x5),
        border: Border.all(color: AppColors.n200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => openTrailOnMap(context, ref, trail),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x3),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.x4),
                  child: TrailHeroImage(
                    trailId: trail.id,
                    slide: HeroSlide.seed(bild),
                    fit: BoxFit.cover,
                    variant: TrailImageVariant.thumb,
                    width: 96,
                    height: double.infinity,
                  ),
                ),
                const SizedBox(width: AppSpacing.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          typ.buildIcon(size: 14),
                          const SizedBox(width: AppSpacing.x1),
                          Expanded(
                            child: Text(
                              typ.label,
                              style: theme.textTheme.labelSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.x1),
                      Text(
                        trail.name,
                        style: theme.textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.x1),
                      Text(
                        distance == null
                            ? 'Entfernung folgt'
                            : '${formatDistanceM(distance)} entfernt · ${anfahrtLabel(distance)}',
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        trail.isFlaeche ? 'Platz' : 'Weg ${trail.laengeLabel}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.inkMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (entry.hints.isNotEmpty)
                        Text(
                          entry.hints.join(' · '),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.inkMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const Spacer(),
                      Row(
                        children: [
                          KeyedSubtree(
                            key: hoerenKey,
                            child: HoerenPill(
                              playing: playing,
                              onPressed: () => ref
                                  .read(miniPlayerProvider.notifier)
                                  .play(trail),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: saved ? 'Gemerkt' : 'Merken',
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            onPressed: () =>
                                quickToggleMerken(context, ref, trail),
                            icon: PhosphorIcon(
                              saved
                                  ? PhosphorIconsFill.heart
                                  : PhosphorIcons.heart,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// „Hören“-Pille. Während der Wiedergabe „Läuft“ mit Equalizer.
class HoerenPill extends StatelessWidget {
  const HoerenPill({super.key, required this.playing, required this.onPressed});

  final bool playing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
        shape: const StadiumBorder(),
      ),
      onPressed: onPressed,
      icon: playing
          ? const EqualizerBars(playing: true, color: AppColors.paper)
          : const PhosphorIcon(PhosphorIcons.headphones, size: 18),
      label: Text(playing ? 'Läuft' : 'Hören'),
    );
  }
}
