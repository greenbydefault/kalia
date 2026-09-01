import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/catalogs/icon_catalog.dart';
import '../../../shared/widgets/content_carousel_style.dart';
import '../../../shared/widgets/content_tile_shell.dart';
import '../domain/nearby.dart';
import 'nearby_actions.dart';
import 'oeffnungs_badge.dart';

/// Peek-Kachel eines Orts im Content-Slider.
class NearbyTile extends StatelessWidget {
  const NearbyTile({super.key, required this.treffer, required this.onTap});

  final NearbyTreffer treffer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final place = treffer.place;
    final kat = poiKategorieEintrag(place.kategorie);
    final distanz = formatDistanzKm(treffer.distanzKm);
    final hasWebsite = place.website != null && place.website!.isNotEmpty;
    final hasTelefon = place.telefon != null && place.telefon!.isNotEmpty;

    return ContentTileShell(
      onTap: onTap,
      layout: ContentCarouselLayout.peek,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                kat.buildIcon(
                  size: ContentCarouselStyle.iconSize,
                  color: AppColors.ink,
                ),
                const SizedBox(height: 8),
                Text(
                  place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  place.kurztext.isEmpty
                      ? distanz
                      : '$distanz · ${place.kurztext}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.inkMuted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OeffnungsBadge(openingHours: place.openingHours),
              if (hasWebsite)
                IconButton(
                  tooltip: 'Website',
                  onPressed: () => openNearbyWebsite(place.website!),
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  icon: const PhosphorIcon(
                    PhosphorIcons.globe,
                    size: 22,
                    color: AppColors.ink,
                  ),
                ),
              if (hasTelefon)
                IconButton(
                  tooltip: 'Anrufen',
                  onPressed: () => callNearbyPlace(place.telefon!),
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  icon: const PhosphorIcon(
                    PhosphorIcons.phone,
                    size: 22,
                    color: AppColors.ink,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
