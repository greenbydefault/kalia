import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../shared/widgets/content_carousel_style.dart';
import '../../../../../shared/widgets/content_tile_shell.dart';
import '../../../domain/station.dart';
import 'station_identity.dart';

/// Peek-Kachel einer Station im Content-Slider.
class StationTile extends StatelessWidget {
  const StationTile({
    super.key,
    required this.station,
    required this.onTap,
  });

  final Station station;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hook = station.thema;

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
                StationNumberAvatar(
                  reihenfolge: station.reihenfolge,
                  radius: ContentCarouselStyle.iconSize / 2,
                ),
                const SizedBox(height: 8),
                Text(
                  station.titel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                if (hook.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    hook,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.inkMuted,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (station.barrierefrei)
            const Padding(
              padding: EdgeInsets.only(top: 4, right: 8),
              child: StationAccessibleMark(color: AppColors.ink),
            ),
        ],
      ),
    );
  }
}
