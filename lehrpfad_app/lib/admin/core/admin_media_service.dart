import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/media/media_url.dart';
import '../../features/community/domain/trail_image.dart';
import '../../shared/images/image_encoder.dart';

/// Metadaten eines offiziellen Trail-Bildes.
class HeroMeta {
  const HeroMeta({
    this.credit = '',
    this.caption = '',
    this.license = '',
    this.licenseUrl = '',
    this.sourceUrl = '',
  });

  final String credit;
  final String caption;
  final String license;
  final String licenseUrl;
  final String sourceUrl;

  Map<String, dynamic> toColumns() => {
    'credit': credit,
    'caption': caption,
    'license': license,
    'license_url': licenseUrl,
    'source_url': sourceUrl,
  };
}

/// Katalog-Medien: Trail-Hero (Bucket `trail-images`, Tabelle `images`
/// mit `source=official`) und Art-Bild/-Audio (Bucket `catalog-media`).
class AdminMediaService {
  AdminMediaService(this._client);

  final SupabaseClient _client;
  static const _uuid = Uuid();

  static const heroBucket = 'trail-images';
  static const mediaBucket = 'catalog-media';

  String heroUrl(String trailId, String imageId, TrailImageVariant v) => _client
      .storage
      .from(heroBucket)
      .getPublicUrl('$trailId/$imageId/${v.fileName}.avif');

  /// Encodiert drei AVIF-Varianten, lädt sie hoch und legt die Zeile an.
  Future<void> uploadTrailHero(
    String trailId,
    Uint8List bytes,
    HeroMeta meta, {
    void Function(double fraction)? onProgress,
  }) async {
    final encoded = await ImageVariants.encode(
      bytes,
      onStep: (f) => onProgress?.call(f * 0.6),
    );
    final id = _uuid.v4();
    final uploaded = <String>[];
    try {
      var done = 0;
      for (final e in encoded.bytes.entries) {
        final path = '$trailId/$id/${e.key.fileName}.avif';
        await _client.storage
            .from(heroBucket)
            .uploadBinary(
              path,
              e.value,
              fileOptions: const FileOptions(
                contentType: 'image/avif',
                cacheControl: '31536000',
              ),
            );
        uploaded.add(path);
        done++;
        onProgress?.call(0.6 + 0.35 * done / encoded.bytes.length);
      }
      final last = await _client
          .from('images')
          .select('sort')
          .eq('trail_id', trailId)
          .eq('source', 'official')
          .order('sort', ascending: false)
          .limit(1);
      final next = last.isEmpty
          ? 1
          : ((last.first['sort'] as num?) ?? 0).toInt() + 1;
      await _client.from('images').insert({
        'id': id,
        'trail_id': trailId,
        'source': 'official',
        'status': 'approved',
        ...meta.toColumns(),
        'sort': next,
        'width': encoded.width,
        'height': encoded.height,
        'mime_type': 'image/avif',
        'thumb_bytes': encoded.bytes[TrailImageVariant.thumb]!.length,
        'small_bytes': encoded.bytes[TrailImageVariant.small]!.length,
        'medium_bytes': encoded.bytes[TrailImageVariant.medium]!.length,
      });
      onProgress?.call(1);
    } catch (_) {
      if (uploaded.isNotEmpty) {
        await _client.storage
            .from(heroBucket)
            .remove(uploaded)
            .catchError((_) => <FileObject>[]);
      }
      rethrow;
    }
  }

  Future<void> updateHero(String imageId, HeroMeta meta) async {
    await _client.from('images').update(meta.toColumns()).eq('id', imageId);
  }

  /// Tauscht die Reihenfolge zweier Bilder.
  Future<void> swapHeroOrder(
    ({String id, int sort}) a,
    ({String id, int sort}) b,
  ) async {
    await _client.from('images').update({'sort': b.sort}).eq('id', a.id);
    await _client.from('images').update({'sort': a.sort}).eq('id', b.id);
  }

  Future<void> deleteHero(String trailId, String imageId) async {
    await _client.storage.from(heroBucket).remove([
      for (final v in TrailImageVariant.values)
        '$trailId/$imageId/${v.fileName}.avif',
    ]);
    await _client.from('images').delete().eq('id', imageId);
  }

  /// Art-Bild: eine AVIF-Variante (small, 900 px). Gibt den
  /// `storage:`-Pfad für `species.image_path` zurück.
  Future<String> uploadSpeciesImage(String speciesId, Uint8List bytes) async {
    final encoded = await ImageVariants.encode(bytes);
    final data = encoded.bytes[TrailImageVariant.small]!;
    final object =
        'species/$speciesId/image-${DateTime.now().millisecondsSinceEpoch}.avif';
    await _client.storage
        .from(mediaBucket)
        .uploadBinary(
          object,
          data,
          fileOptions: const FileOptions(
            contentType: 'image/avif',
            cacheControl: '31536000',
          ),
        );
    return MediaUrl.storagePath(mediaBucket, object);
  }

  /// Art-Audio (mp3/m4a). Gibt den `storage:`-Pfad zurück.
  Future<String> uploadSpeciesAudio(
    String speciesId,
    Uint8List bytes,
    String extension,
  ) async {
    final ext = extension.toLowerCase();
    final object =
        'species/$speciesId/audio-${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _client.storage
        .from(mediaBucket)
        .uploadBinary(
          object,
          bytes,
          fileOptions: FileOptions(
            contentType: ext == 'm4a' ? 'audio/mp4' : 'audio/mpeg',
            cacheControl: '31536000',
          ),
        );
    return MediaUrl.storagePath(mediaBucket, object);
  }

  /// Räumt ein ersetztes Storage-Objekt weg; fremde URLs/Assets bleiben.
  Future<void> removeStoragePath(String? path) async {
    if (path == null) return;
    final p = MediaUrl.parseStorage(path);
    if (p == null) return;
    await _client.storage
        .from(p.bucket)
        .remove([p.object])
        .catchError((_) => <FileObject>[]);
  }
}
