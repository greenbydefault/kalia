import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/catalogs/icon_catalog.dart';
import '../../../community/domain/trail_image.dart';
import '../../../nearby_trails/data/karte_state.dart';
import '../../../nearby_trails/domain/eintrag_mapper.dart';
import '../../../nearby_trails/domain/karte_logik.dart';
import '../../../nearby_trails/presentation/eintrag_karte.dart';
import '../../../trail_progress/presentation/trail_sheet_peek_actions.dart';
import '../../domain/trail.dart';
import 'trail_hero.dart';

/// Quick-Facts-Karte am unteren Rand der Karte (Zwischenschritt nach
/// Trail-Auswahl). Tap öffnet die Detailseite, X/Swipe-down deselektiert.
class TrailPeekCard extends StatelessWidget {
  const TrailPeekCard({
    super.key,
    required this.trail,
    required this.onOpen,
    required this.onClose,
    this.onTourStarted,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
  });

  final Trail trail;
  final VoidCallback onOpen;
  final VoidCallback onClose;
  final VoidCallback? onTourStarted;

  /// Swipe-down-to-dismiss; der Parent (MapScreen) fährt den Controller.
  final GestureDragUpdateCallback? onVerticalDragUpdate;
  final GestureDragEndCallback? onVerticalDragEnd;

  /// Feste Höhe, damit der LocateFab-Offset deterministisch ist.
  static const double height = 188;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typ = typEintrag(trail.typ);
    final bild = TrailHero.pagesFor(trail).first;

    return GestureDetector(
      onVerticalDragUpdate: onVerticalDragUpdate,
      onVerticalDragEnd: onVerticalDragEnd,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.x6),
          boxShadow: const [
            BoxShadow(blurRadius: 20, color: AppColors.scrim26),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onOpen,
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
                            IconButton(
                              tooltip: 'Schließen',
                              icon: const PhosphorIcon(
                                PhosphorIcons.x,
                                size: 18,
                              ),
                              onPressed: onClose,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          trail.name,
                          style: theme.textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        _QuickFacts(trail: trail),
                        const SizedBox(height: AppSpacing.x2),
                        TrailSheetPeekActions(
                          trail: trail,
                          onTourStarted: onTourStarted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dieselben Fakten wie die Eintragskarte: Anfahrt, Dauer, Länge, Kinder
/// bzw. Anfahrt, Saison, Eintritt.
class _QuickFacts extends ConsumerWidget {
  const _QuickFacts({required this.trail});

  final Trail trail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eintrag = eintragVon(trail);
    if (eintrag == null) return const SizedBox.shrink();
    final bezug = ref.watch(bezugCoordsProvider);
    final min = bezug == null
        ? null
        : schaetzeAnfahrtMin(bezug, eintrag.startpunkt);
    return FaktenRaster(treffer: Treffer(eintrag, min));
  }
}
