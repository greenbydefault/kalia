import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../domain/species.dart';
import 'species_illustration.dart';

/// Zentrierte Illustration (sonst Icon) + Name, optional Gesehen-Check.
///
/// [silhouette]: noch nicht entdeckt. Dasselbe Icon, nur abgetönt, kein
/// Schloss und kein Check.
class SpeciesGlyph extends StatelessWidget {
  const SpeciesGlyph({
    super.key,
    required this.species,
    required this.seen,
    this.iconSize = 28,
    this.illustrationSize,
    this.silhouette = false,
    this.showCheck = true,
  });

  final Species species;
  final bool seen;
  final double iconSize;

  /// Kantenlänge der Illustration, Standard 1,5 x [iconSize].
  final double? illustrationSize;
  final bool silhouette;
  final bool showCheck;

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
            SpeciesIllustration(
              species: species,
              size: illustrationSize ?? iconSize * 1.5,
              iconSize: iconSize,
              silhouette: silhouette,
              iconColor: silhouette ? AppColors.n400 : AppColors.ink,
            ),
            if (seen && showCheck && !silhouette)
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
            color: silhouette ? AppColors.inkMuted : AppColors.ink,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}
