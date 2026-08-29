import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/trail.dart';
import '../../domain/trail_bild.dart';

/// Zentraler Hero-Fallback: echte Seed-Fotos oder ein gemeinsames Platzhalter-Asset.
class TrailHero {
  static const placeholderAsset = 'assets/images/trails/_placeholder.jpg';

  static const placeholderBild = TrailBild(
    file: placeholderAsset,
    caption: '',
    credit: '',
    license: '',
    licenseUrl: '',
    sourceUrl: '',
    kind: 'placeholder',
  );

  static List<TrailBild> pagesFor(Trail trail) =>
      trail.bilder.isNotEmpty ? trail.bilder : const [placeholderBild];
}

/// Hero-Foto; bei Ladefehler derselbe zentrale Platzhalter (kein Recursion-Loop).
class TrailHeroImage extends StatelessWidget {
  const TrailHeroImage({
    super.key,
    required this.trailId,
    required this.bild,
    required this.fit,
    this.width,
    this.height,
    this.alignment = Alignment.center,
  });

  final String trailId;
  final TrailBild bild;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Alignment alignment;

  static const _broken = ColoredBox(
    color: AppColors.n900,
    child: Icon(
      Icons.broken_image_outlined,
      color: AppColors.onImage54,
      size: 48,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final path = bild.assetPath(trailId);
    return Image.asset(
      path,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      errorBuilder: (context, error, stack) {
        if (path == TrailHero.placeholderAsset) return _broken;
        return Image.asset(
          TrailHero.placeholderAsset,
          fit: fit,
          width: width,
          height: height,
          alignment: alignment,
          errorBuilder: (_, __, ___) => _broken,
        );
      },
    );
  }
}
