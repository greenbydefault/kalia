import '../../community/domain/trail_image.dart';

/// Verweis auf eine Mediendatei. Der Resolver macht daraus Datei, URL oder
/// Seed-Asset; die UI kennt weder Pfade noch Buckets.
sealed class AssetRef {
  const AssetRef();

  /// Schlüssel im [FileStore] (relativer Pfad, ohne `..`).
  String fileKey([TrailImageVariant? variant]);
}

/// Hero-/Trail-Foto aus dem Bucket `trail-images`.
class ImageRef extends AssetRef {
  const ImageRef({required this.trailId, required this.imageId});

  final String trailId;
  final String imageId;

  @override
  String fileKey([TrailImageVariant? variant]) =>
      'images/$trailId/$imageId/${(variant ?? TrailImageVariant.small).fileName}.avif';

  @override
  bool operator ==(Object other) =>
      other is ImageRef && other.trailId == trailId && other.imageId == imageId;

  @override
  int get hashCode => Object.hash(trailId, imageId);
}

/// Audio: `assets/…`, `http(s)://…` oder `storage:<bucket>/<objekt>`
/// (Format von `MediaUrl`).
class AudioRef extends AssetRef {
  const AudioRef(this.path);

  final String path;

  @override
  String fileKey([TrailImageVariant? variant]) =>
      'audio/${path.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')}';

  @override
  bool operator ==(Object other) => other is AudioRef && other.path == path;

  @override
  int get hashCode => path.hashCode;
}
