import '../../../core/media/media_url.dart';
import '../../community/domain/trail_image.dart';
import '../models/asset_ref.dart';
import '../offline_config.dart';
import '../storage/file_store.dart';

/// Eine Bildquelle, die der Resolver vorschlägt.
sealed class ImageSource {
  const ImageSource();
}

class ImageSourceFile extends ImageSource {
  const ImageSourceFile(this.path);
  final String path;
}

class ImageSourceNetwork extends ImageSource {
  const ImageSourceNetwork(this.url);
  final String url;
}

class ImageSourceAsset extends ImageSource {
  const ImageSourceAsset(this.path);
  final String path;
}

sealed class ResolvedAudio {
  const ResolvedAudio();
}

class AudioFileSource extends ResolvedAudio {
  const AudioFileSource(this.path);
  final String path;
}

class AudioUrlSource extends ResolvedAudio {
  const AudioUrlSource(this.url);
  final String url;
}

class AudioAssetSource extends ResolvedAudio {
  const AudioAssetSource(this.path);
  final String path;
}

/// Einziger Ort, der entscheidet, woher ein Medium kommt. Die UI fragt nach
/// einem [AssetRef], nie nach Pfaden oder Buckets.
///
/// Bilder, in dieser Reihenfolge:
/// 1. lokale Datei im [FileStore]
/// 2. Storage-URL (nur online)
/// 3. gebündelter Seed-Thumb des Orts (nur wenn es genau dieses Bild ist)
/// 4. Platzhalter
class AssetResolver {
  AssetResolver({
    required this._files,
    required String storageBaseUrl,
    this._seedThumbImages = const {},
  }) : _base = storageBaseUrl.replaceAll(RegExp(r'/+$'), '');

  final FileStore _files;
  final String _base;
  final Map<String, String> _seedThumbImages;

  static String placeholderAsset(TrailImageVariant v) =>
      'assets/images/trails/_placeholder.${v.fileName}.avif';

  static String seedThumbAsset(String trailId) =>
      '${OfflineConfig.seedDir}/thumbs/$trailId.avif';

  String storageUrl(ImageRef ref, TrailImageVariant v) =>
      '$_base/storage/v1/object/public/${OfflineConfig.imageBucket}/'
      '${ref.trailId}/${ref.imageId}/${v.fileName}.avif';

  /// Quellen in Prioritätsreihenfolge; die letzte ist immer ein Asset.
  List<ImageSource> image(
    ImageRef ref,
    TrailImageVariant variant, {
    required bool online,
  }) {
    final local = _files.pathIfExists(ref.fileKey(variant));
    return [
      if (local != null) ImageSourceFile(local),
      if (online && _base.isNotEmpty)
        ImageSourceNetwork(storageUrl(ref, variant)),
      if (_seedThumbImages[ref.trailId] == ref.imageId)
        ImageSourceAsset(seedThumbAsset(ref.trailId)),
      ImageSourceAsset(placeholderAsset(variant)),
    ];
  }

  /// Nur Platzhalter (Trail ohne Foto).
  List<ImageSource> placeholder(TrailImageVariant variant) => [
    ImageSourceAsset(placeholderAsset(variant)),
  ];

  /// Audio: lokale Datei → Netz (online) → gebündeltes Asset. `null`, wenn
  /// die Quelle nur im Netz liegt und das Gerät offline ist.
  ResolvedAudio? audio(AudioRef ref, {required bool online}) {
    final local = _files.pathIfExists(ref.fileKey());
    if (local != null) return AudioFileSource(local);
    final url = MediaUrl.resolve(ref.path, supabaseUrl: _base);
    if (url != null) return online ? AudioUrlSource(url) : null;
    return AudioAssetSource(ref.path);
  }
}
