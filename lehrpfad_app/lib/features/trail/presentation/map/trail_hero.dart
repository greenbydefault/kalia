import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter_avif/flutter_avif.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../community/domain/trail_image.dart';
import '../../../offline/offline.dart';
import '../../domain/trail.dart';
import '../../domain/trail_bild.dart';

/// Eine Hero-Seite: redaktionelles Foto (Trail-Daten) oder Community-Foto.
class HeroSlide {
  const HeroSlide._({this.seed, this.community});

  const HeroSlide.seed(TrailBild bild) : this._(seed: bild);

  const HeroSlide.community(TrailImage image) : this._(community: image);

  final TrailBild? seed;
  final TrailImage? community;

  bool get isNetwork => community != null;

  /// Quelle/Lizenz anzeigen: Seed-Bilder und offizielle Bilder aus dem
  /// CMS. Nutzerfotos haben nur einen Urheber.
  bool get showsLicense => community == null || community!.isOfficial;

  bool get hasCreditBadge {
    final img = community;
    if (img != null) {
      if (img.isOfficial) {
        return img.credit.trim().isNotEmpty || img.license.trim().isNotEmpty;
      }
      return img.credit.trim().isNotEmpty;
    }
    return seed!.hasCreditBadge;
  }

  String get badgeText {
    final img = community;
    if (img != null) {
      if (!img.isOfficial) return '© ${img.credit}';
      final label = TrailBild.licenseLabelOf(img.license);
      final author = img.credit.trim();
      if (author.isEmpty) return label;
      return label.isEmpty ? author : '$author · $label';
    }
    return seed!.badgeText;
  }

  String get caption => community?.caption ?? seed?.caption ?? '';

  String get credit {
    final img = community;
    if (img != null) return img.credit;
    return seed?.credit ?? '';
  }

  String get sourceUrl => community?.sourceUrl ?? seed?.sourceUrl ?? '';

  String get licenseLabel {
    final img = community;
    if (img != null) return TrailBild.licenseLabelOf(img.license);
    return seed?.licenseLabel ?? '';
  }

  String get licenseUrl => community?.licenseUrl ?? seed?.licenseUrl ?? '';
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

  /// Offizielle Bilder aus der Datenbank (CMS) ersetzen die gebündelten
  /// Seed-Fotos; ohne DB-Bilder bleiben die Seed-Fotos. Danach freigegebene
  /// Trail-weite Community-Fotos. Leer → Platzhalter.
  static List<HeroSlide> slidesFor(
    Trail trail, [
    List<TrailImage> community = const [],
  ]) {
    final trailWide = [
      for (final img in community)
        if (img.stationId == null && img.isApproved) img,
    ];
    final official = trailWide.where((i) => i.isOfficial).toList()
      ..sort((a, b) => a.sort.compareTo(b.sort));
    final ugc = trailWide.where((i) => !i.isOfficial).toList();
    if (trail.bilder.isEmpty && official.isEmpty && ugc.isEmpty) {
      return const [HeroSlide.seed(placeholderBild)];
    }
    return [
      if (official.isNotEmpty)
        for (final img in official) HeroSlide.community(img)
      else
        for (final b in trail.bilder) HeroSlide.seed(b),
      for (final img in ugc) HeroSlide.community(img),
    ];
  }
}

/// Hero-Foto. Quelle und Reihenfolge entscheidet der [AssetResolver]
/// (lokal → Storage → Seed-Thumb → Platzhalter); bei Ladefehler wird die
/// nächste Quelle versucht.
class TrailHeroImage extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
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
    final resolver = ref.watch(assetResolverProvider);
    final id = seed.id;
    final sources = (seed.isPlaceholder || id == null)
        ? resolver.placeholder(variant)
        : resolver.image(
            ImageRef(trailId: trailId, imageId: id),
            variant,
            online: ref.watch(isOnlineProvider),
          );
    return _chain(sources, 0);
  }

  Widget _chain(List<ImageSource> sources, int i) {
    Widget next(BuildContext context, Object error, StackTrace? stack) =>
        i + 1 < sources.length ? _chain(sources, i + 1) : _broken;
    return switch (sources[i]) {
      ImageSourceFile(:final path) => AvifImage.file(
        File(path),
        fit: fit,
        width: width,
        height: height,
        alignment: alignment,
        errorBuilder: next,
      ),
      ImageSourceNetwork(:final url) => CachedNetworkAvifImage(
        url,
        fit: fit,
        width: width,
        height: height,
        alignment: alignment,
        errorBuilder: next,
      ),
      ImageSourceAsset(:final path) => AvifImage.asset(
        path,
        fit: fit,
        width: width,
        height: height,
        alignment: alignment,
        errorBuilder: next,
      ),
    };
  }
}
