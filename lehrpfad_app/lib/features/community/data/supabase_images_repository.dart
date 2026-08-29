import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/trail_image.dart';
import 'images_repository.dart';

/// Bilder aus Supabase: Metadaten aus der Tabelle `images`, Dateien aus
/// dem oeffentlichen Bucket `trail-images`
/// (Pfad: {trailId}/{imageId}/{variant}.avif).
class SupabaseImagesRepository implements ImagesRepository {
  SupabaseImagesRepository(this._client);

  final SupabaseClient _client;

  static const bucket = 'trail-images';

  static const _columns =
      'id, trail_id, station_id, uploader_id, source, status, credit, '
      'width, height, mime_type, thumb_bytes, small_bytes, medium_bytes, '
      'created_at';

  @override
  Future<List<TrailImage>> getImages(String trailId) async {
    final rows = await _client
        .from('images')
        .select(_columns)
        .eq('trail_id', trailId)
        .order('created_at');
    return rows.map(_rowToImage).toList();
  }

  @override
  Future<List<TrailImage>> getPendingImages() async {
    final rows = await _client
        .from('images')
        .select(_columns)
        .eq('status', 'pending')
        .order('created_at');
    return rows.map(_rowToImage).toList();
  }

  @override
  Future<void> setImageStatus(String imageId, TrailImageStatus status) {
    return _client
        .from('images')
        .update({'status': status.name})
        .eq('id', imageId);
  }

  @override
  Future<void> deleteImage(TrailImage image) async {
    await _client.storage.from(bucket).remove(_paths(image));
    await _client.from('images').delete().eq('id', image.id);
  }

  static List<String> pathsFor(String trailId, String imageId) => [
    for (final v in TrailImageVariant.values)
      '$trailId/$imageId/${v.fileName}.avif',
  ];

  List<String> _paths(TrailImage image) => pathsFor(image.trailId, image.id);

  TrailImage _rowToImage(Map<String, dynamic> row) {
    final id = row['id'] as String;
    final trailId = row['trail_id'] as String;
    String url(TrailImageVariant v) => _client.storage
        .from(bucket)
        .getPublicUrl('$trailId/$id/${v.fileName}.avif');
    return TrailImage(
      id: id,
      trailId: trailId,
      stationId: row['station_id'] as int?,
      uploaderId: row['uploader_id'] as String?,
      source: TrailImageSource.parse(row['source'] as String),
      status: TrailImageStatus.parse(row['status'] as String),
      credit: row['credit'] as String? ?? '',
      width: row['width'] as int?,
      height: row['height'] as int?,
      mimeType: row['mime_type'] as String?,
      thumbBytes: row['thumb_bytes'] as int?,
      smallBytes: row['small_bytes'] as int?,
      mediumBytes: row['medium_bytes'] as int?,
      createdAt: DateTime.parse(row['created_at'] as String),
      isMine: row['uploader_id'] != null &&
          row['uploader_id'] == _client.auth.currentUser?.id,
      thumbUrl: url(TrailImageVariant.thumb),
      smallUrl: url(TrailImageVariant.small),
      mediumUrl: url(TrailImageVariant.medium),
    );
  }
}
