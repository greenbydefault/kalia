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
/// Bilder, in dieser Reihenfolge, pro Slot:
/// 1. lokale Datei im [FileStore]
/// 2. WebP, dann AVIF (nur online)
/// 3. gebündelter Seed-Thumb, nur für den Slot thumb
/// Den nächstkleineren Slot und den Farbplatzhalter hängt das Widget an.
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
      'assets/images/trails/_placeholder.${v.fileName}.webp';

  static String seedThumbAsset(String trailId) =>
      '${OfflineConfig.seedDir}/thumbs/$trailId.webp';

  String storageUrl(ImageRef ref, TrailImageVariant v, {String ext = 'webp'}) =>
      '$_base/storage/v1/object/public/${OfflineConfig.imageBucket}/'
      '${ref.trailId}/${ref.imageId}/${v.fileName}.$ext';

  /// Quellen für genau diesen Slot, ohne den nächstkleineren.
  ///
  /// Online: lokale Datei, dann WebP, dann AVIF. Der Seed-Thumb kommt nur
  /// beim Slot thumb und erst nach dem Netz, damit small online nie darauf
  /// stehen bleibt. Offline entfällt das Netz; der Seed-Thumb ist dann der
  /// einzige Bildpfad ohne Verbindung.
  List<ImageSource> image(
    ImageRef ref,
    TrailImageVariant variant, {
    required bool online,
  }) {
    final local = _files.pathIfExists(ref.fileKey(variant));
    final seedThumb =
        variant == TrailImageVariant.thumb &&
        _seedThumbImages[ref.trailId] == ref.imageId;
    final network = online && _base.isNotEmpty;
    return [
      if (local != null) ImageSourceFile(local),
      if (network) ImageSourceNetwork(storageUrl(ref, variant)),
      if (network) ImageSourceNetwork(storageUrl(ref, variant, ext: 'avif')),
      if (seedThumb) ImageSourceAsset(seedThumbAsset(ref.trailId)),
    ];
  }

  /// Nur der grafische Platzhalter (Trail ohne Foto).
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
