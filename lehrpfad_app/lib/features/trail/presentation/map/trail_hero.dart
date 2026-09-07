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

  /// AVIF-Variante des Platzhalters (`_placeholder.{variant}.avif`).
  static String placeholderVariant(TrailImageVariant variant) =>
      'assets/images/trails/_placeholder.${variant.fileName}.avif';

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
    this.variant = TrailImageVariant.small,
    this.width,
    this.height,
    this.alignment = Alignment.center,
  });

  final String trailId;
  final HeroSlide slide;
  final BoxFit fit;

  /// Welche AVIF-Größe geladen wird: thumb (Karten-Peek/Strip),
  /// small (Header-Slider), medium (Fullscreen). Seed wie Community.
  final TrailImageVariant variant;
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

  /// Test-Hook: Der native AVIF-Decoder steht in Widget-Tests nicht zur
  /// Verfügung. Tests setzen das auf ein einfaches Platzhalter-Widget.
  @visibleForTesting
  static Widget Function(BoxFit fit)? debugSeedImageBuilder;

  String _communityUrl(TrailImage img) => switch (variant) {
    TrailImageVariant.thumb => img.thumbUrl,
    TrailImageVariant.small => img.smallUrl,
    TrailImageVariant.medium => img.mediumUrl,
  };

  @override
  Widget build(BuildContext context) {
    final community = slide.community;
    if (community != null) {
      return CachedNetworkAvifImage(
        _communityUrl(community),
        fit: fit,
        width: width,
        height: height,
        alignment: alignment,
        errorBuilder: (context, error, stack) => _broken,
      );
    }
    final seed = slide.seed!;
    final debugBuilder = debugSeedImageBuilder;
    if (debugBuilder != null) return debugBuilder(fit);
    final path = seed.isPlaceholder
        ? TrailHero.placeholderVariant(variant)
        : seed.variantAssetPath(trailId, variant);
    return AvifImage.asset(
      path,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      errorBuilder: (context, error, stack) {
        if (seed.isPlaceholder) return _broken;
        return AvifImage.asset(
          TrailHero.placeholderVariant(variant),
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
