import 'package:flutter/material.dart';
import 'package:flutter_avif/flutter_avif.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../community/domain/trail_image.dart';
import '../../domain/trail.dart';
import '../../domain/trail_bild.dart';

/// Eine Hero-Seite: Seed-Asset oder freigegebenes Community-Foto.
class HeroSlide {
  const HeroSlide._({this.seed, this.community});

  const HeroSlide.seed(TrailBild bild) : this._(seed: bild);

  const HeroSlide.community(TrailImage image) : this._(community: image);

  final TrailBild? seed;
  final TrailImage? community;

  bool get isNetwork => community != null;

  bool get hasCreditBadge {
    final img = community;
    if (img != null) return img.credit.trim().isNotEmpty;
    return seed!.hasCreditBadge;
  }

  String get badgeText {
    final img = community;
    if (img != null) return '© ${img.credit}';
    return seed!.badgeText;
  }

  String get caption => seed?.caption ?? '';

  String get credit {
    final img = community;
    if (img != null) return img.credit;
    return seed?.credit ?? '';
  }

  String get sourceUrl => seed?.sourceUrl ?? '';

  String get licenseLabel => seed?.licenseLabel ?? '';

  String get licenseUrl => seed?.licenseUrl ?? '';
}

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

  /// Seed-Fotos zuerst, danach freigegebene Trail-weite Community-Fotos.
  /// Leer → Platzhalter.
  static List<HeroSlide> slidesFor(
    Trail trail, [
    List<TrailImage> community = const [],
  ]) {
    final ugc = [
      for (final img in community)
        if (img.stationId == null && img.isApproved) img,
    ];
    if (trail.bilder.isEmpty && ugc.isEmpty) {
      return const [HeroSlide.seed(placeholderBild)];
    }
    return [
      for (final b in trail.bilder) HeroSlide.seed(b),
      for (final img in ugc) HeroSlide.community(img),
    ];
  }
}

/// Hero-Foto; bei Ladefehler derselbe zentrale Platzhalter (kein Recursion-Loop).
class TrailHeroImage extends StatelessWidget {
  const TrailHeroImage({
    super.key,
    required this.trailId,
    required this.slide,
    required this.fit,
    this.width,
    this.height,
    this.alignment = Alignment.center,
  });

  final String trailId;
  final HeroSlide slide;
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
    final community = slide.community;
    if (community != null) {
      return CachedNetworkAvifImage(
        community.mediumUrl,
        fit: fit,
        width: width,
        height: height,
        alignment: alignment,
        errorBuilder: (context, error, stack) => _broken,
      );
    }
    final path = slide.seed!.assetPath(trailId);
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
          errorBuilder: (_, _, _) => _broken,
        );
      },
    );
  }
}
