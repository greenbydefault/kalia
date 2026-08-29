import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../domain/species.dart';

/// Zentriertes Icon + Name, optional Gesehen-Check und Schloss.
class SpeciesGlyph extends StatelessWidget {
  const SpeciesGlyph({
    super.key,
    required this.species,
    required this.seen,
    this.iconSize = 28,
    this.showLock = false,
  });

  final Species species;
  final bool seen;
  final double iconSize;
  final bool showLock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            PhosphorIcon(
              species.displayIconEintrag.icon,
              size: iconSize,
              color: AppColors.ink,
            ),
            if (showLock && !seen)
              const Positioned(
                right: -4,
                bottom: -4,
                child: Icon(Icons.lock, size: 16, color: AppColors.ink),
              ),
            if (seen)
              const Positioned(
                right: -6,
                top: -6,
                child: Icon(Icons.check_circle, size: 16, color: AppColors.ink),
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
    );
  }
}
