import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/audio/audio_player_control.dart';
import '../../../shared/widgets/content_carousel_style.dart';
import '../../../shared/widgets/content_tile_shell.dart';
import '../data/species_providers.dart';
import '../domain/species.dart';

enum SpeciesTileLayout { peek, compact }

/// Eine Art-/Geräte-Kachel im Carousel.
class SpeciesTile extends ConsumerWidget {
  const SpeciesTile({
    super.key,
    required this.species,
    required this.seen,
    required this.onTap,
    this.layout = SpeciesTileLayout.peek,
  });

  final Species species;
  final bool seen;
  final VoidCallback onTap;
  final SpeciesTileLayout layout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (layout) {
      SpeciesTileLayout.peek => _PeekTile(
          species: species,
          seen: seen,
          onTap: onTap,
          onToggleSeen: () =>
              ref.read(sightingsProvider.notifier).setSeen(species.id, !seen),
        ),
      SpeciesTileLayout.compact => _CompactTile(
          species: species,
          seen: seen,
          onTap: onTap,
        ),
    };
  }
}

/// Flora/Fauna: Icon → Name → Hook links, Auge → Play rechts.
class _PeekTile extends StatelessWidget {
  const _PeekTile({
    required this.species,
    required this.seen,
    required this.onTap,
    required this.onToggleSeen,
  });

  final Species species;
  final bool seen;
  final VoidCallback onTap;
  final VoidCallback onToggleSeen;

  static const _actionSize = 44.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = species.displayIconEintrag.icon;
    final audioPath = species.audioPath;
    final hasAudio = audioPath != null && audioPath.isNotEmpty;
    final hook = species.displayHook;

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
                PhosphorIcon(
                  icon,
                  size: ContentCarouselStyle.iconSize,
                  color: AppColors.ink,
                ),
                const SizedBox(height: 8),
                Text(
                  species.nameDe,
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
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: ValueKey('species-seen-${species.id}'),
                tooltip: seen
                    ? 'Gesehen, Markierung aufheben'
                    : 'Als gesehen markieren',
                onPressed: onToggleSeen,
                constraints: const BoxConstraints(
                  minWidth: _actionSize,
                  minHeight: _actionSize,
                ),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                icon: PhosphorIcon(
                  seen ? PhosphorIcons.checkCircle : PhosphorIcons.eye,
                  size: 22,
                  color: AppColors.ink,
                ),
              ),
              if (hasAudio)
                AudioPlayerControl(
                  key: ValueKey('species-play-${species.id}'),
                  assetPath: audioPath,
                  iconOnly: true,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Geräte: zentriertes Icon + Name, optional Check-Badge.
class _CompactTile extends StatelessWidget {
  const _CompactTile({
    required this.species,
    required this.seen,
    required this.onTap,
  });

  final Species species;
  final bool seen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = species.displayIconEintrag.icon;

    return ContentTileShell(
      onTap: onTap,
      layout: ContentCarouselLayout.compact3,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              PhosphorIcon(
                icon,
                size: ContentCarouselStyle.iconSize,
                color: AppColors.ink,
              ),
              if (seen)
                const Positioned(
                  right: -6,
                  top: -6,
                  child: Icon(
                    Icons.check_circle,
                    size: 16,
                    color: AppColors.ink,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            species.nameDe,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.ink,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
