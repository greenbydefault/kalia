import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/catalogs/icon_catalog.dart';
import '../domain/nearby.dart';
import 'nearby_actions.dart';
import 'oeffnungs_badge.dart';

/// Kompakte Info-Karte über einem ausgewählten Ort in der Nähe.
class NearbyPeekCard extends StatelessWidget {
  const NearbyPeekCard({
    super.key,
    required this.treffer,
    required this.onClose,
  });

  final NearbyTreffer treffer;
  final VoidCallback onClose;

  static const double height = 108;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final place = treffer.place;
    final kat = poiKategorieEintrag(place.kategorie);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.x6),
        boxShadow: const [BoxShadow(blurRadius: 16, color: AppColors.scrim26)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x3,
          AppSpacing.x2,
          AppSpacing.x1,
          AppSpacing.x2,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.n100,
              child: kat.buildIcon(size: 18, color: AppColors.ink),
            ),
            const SizedBox(width: AppSpacing.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                '${kat.label} · ${formatDistanzKm(treffer.distanzKm)}',
                                style: theme.textTheme.labelSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            OeffnungsBadge(openingHours: place.openingHours),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Schließen',
                        icon: const PhosphorIcon(PhosphorIcons.x, size: 18),
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
                    place.name,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      if (place.website != null && place.website!.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => openNearbyWebsite(place.website!),
                          icon: const PhosphorIcon(
                            PhosphorIcons.globe,
                            size: 16,
                          ),
                          label: const Text('Website'),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      if (place.telefon != null && place.telefon!.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => callNearbyPlace(place.telefon!),
                          icon: const PhosphorIcon(
                            PhosphorIcons.phone,
                            size: 16,
                          ),
                          label: const Text('Anrufen'),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
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
    );
  }
}
