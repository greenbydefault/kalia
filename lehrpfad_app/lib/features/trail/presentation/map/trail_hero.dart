import 'package:flutter/material.dart';

import '../../../community/domain/trail_image.dart';
import '../../../trail/domain/trail.dart';
import '../../../trail/domain/trail_bild.dart';
import '../../../../shared/widgets/kalia_image.dart';

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

  /// AVIF bleibt für alte Stände. Die App zeigt die WebP-Variante
  /// (`_placeholder.{variant}.webp`).
  static String placeholderVariant(TrailImageVariant variant) =>
      'assets/images/trails/_placeholder.${variant.fileName}.webp';

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

/// Hero-Foto. Slot kommt vom Aufrufer. Community- und Seed-Bilder laufen
/// beide über [KaliaImage].
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

  /// thumb in Listen, small im Hero, medium nur im Zoom.
  final TrailImageVariant variant;
  final double? width;
  final double? height;
  final Alignment alignment;

  /// Test-Hook: Widget-Tests haben keinen Bild-Decoder fürs Netz.
  @visibleForTesting
  static Widget Function(BoxFit fit)? debugSeedImageBuilder;

  @override
  Widget build(BuildContext context) {
    final debugBuilder = debugSeedImageBuilder;
    if (debugBuilder != null) return debugBuilder(fit);
    final community = slide.community;
    final seed = slide.seed;
    final id = community?.id ?? seed?.id;
    final empty = seed?.isPlaceholder == true || id == null;
    return KaliaImage(
      trailId: empty ? null : trailId,
      imageId: empty ? null : id,
      slot: variant,
      thumbhash: community?.thumbhash ?? seed?.thumbhash ?? '',
      dominantColor: community?.dominantColor ?? seed?.dominantColor ?? '',
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
    );
  }
}
