import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/photo_geo_check.dart';
import '../domain/trail_image.dart';
import 'images_repository.dart';

/// Bilder aus Supabase: Metadaten aus der Tabelle `images`, Dateien aus
/// dem oeffentlichen Bucket `trail-images`
/// (Pfad: {trailId}/{imageId}/{variant}.webp, AVIF daneben).
class SupabaseImagesRepository implements ImagesRepository {
  SupabaseImagesRepository(this._client);

  final SupabaseClient _client;

  static const bucket = 'trail-images';

  static const _columns =
      'id, trail_id, station_id, uploader_id, source, status, credit, '
      'width, height, mime_type, thumb_bytes, small_bytes, medium_bytes, '
      'created_at';

  /// Redaktionelle Zusatzspalten (Migration 0030). Fehlen sie noch in der
  /// Datenbank, laeuft die Abfrage ohne sie weiter.
  static const _cmsColumns =
      'caption, license, license_url, source_url, kind, sort';

  /// Platzhalter (Migration 0037). Fehlt die Spalte, bleibt die Abfrage
  /// bei den CMS-Spalten.
  static const _placeholderColumns = 'thumbhash, dominant_color';

  /// Die Geo-Ampel ist ein Moderations-Hinweis und wird nur fuer die
  /// pending-Queue geladen, nicht fuer die oeffentliche Anzeige.
  static const _pendingColumns = '$_columns, geo_check';

  @override
  Future<List<TrailImage>> getImages(String trailId) async {
    try {
      return await _select(
        '$_columns, $_cmsColumns, $_placeholderColumns',
        trailId: trailId,
      );
    } on PostgrestException catch (e) {
      if (e.code != '42703' && e.code != 'PGRST204') rethrow;
      try {
        return await _select('$_columns, $_cmsColumns', trailId: trailId);
      } on PostgrestException catch (e2) {
        if (e2.code != '42703' && e2.code != 'PGRST204') rethrow;
        return _select(_columns, trailId: trailId);
      }
    }
  }

  Future<List<TrailImage>> _select(
    String columns, {
    required String trailId,
  }) async {
    final rows = await _client
        .from('images')
        .select(columns)
        .eq('trail_id', trailId)
        // Abgelehnte bleiben in der DB (Konto zeigt Grund), gehoeren aber
        // nie in die Trail-Galerie, auch nicht fuer den Uploader.
        .neq('status', 'rejected')
        .order('created_at');
    return rows.map(_rowToImage).toList();
  }

  /// Entscheidungsspalten (Migration 0039).
  static const _decisionColumns = 'reject_reason, decided_at';

  @override
  Future<List<TrailImage>> getMyImages() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const <TrailImage>[];
    try {
      return await _mine(
        '$_columns, $_decisionColumns, $_placeholderColumns',
        uid,
      );
    } on PostgrestException catch (e) {
      if (e.code != '42703' && e.code != 'PGRST204') rethrow;
      return _mine(_columns, uid);
    }
  }

  Future<List<TrailImage>> _mine(String columns, String uid) async {
    final rows = await _client
        .from('images')
        .select(columns)
        .eq('uploader_id', uid)
        .eq('source', 'user')
        .order('created_at', ascending: false);
    return rows.map(_rowToImage).toList();
  }

  @override
  Future<List<TrailImage>> getRejectedBefore(DateTime before) async {
    final rows = await _client
        .from('images')
        .select('$_columns, $_decisionColumns')
        .eq('status', 'rejected')
        .lt('decided_at', before.toUtc().toIso8601String())
        .order('decided_at');
    return rows.map(_rowToImage).toList();
  }

  @override
  Future<List<TrailImage>> getPendingImages() async {
    try {
      return await _pending('$_pendingColumns, $_placeholderColumns');
    } on PostgrestException catch (e) {
      if (e.code != '42703' && e.code != 'PGRST204') rethrow;
      return _pending(_pendingColumns);
    }
  }

  Future<List<TrailImage>> _pending(String columns) async {
    final rows = await _client
        .from('images')
        .select(columns)
        .eq('status', 'pending')
        .order('created_at');
    return rows.map(_rowToImage).toList();
  }

  @override
  Future<void> setImageStatus(String imageId, TrailImageStatus status) {
    return _client
        .from('images')
        .update({
          'status': status.name,
          'decided_at': DateTime.now().toUtc().toIso8601String(),
          'reject_reason': null,
        })
        .eq('id', imageId);
  }

  @override
  Future<void> rejectImage(TrailImage image, RejectReason reason) async {
    await _client
        .from('images')
        .update({
          'status': TrailImageStatus.rejected.name,
          'reject_reason': reason.dbValue,
          'decided_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', image.id);
    // Grosse Varianten sofort weg; schlaegt das fehl, bleibt der Status
    // trotzdem gesetzt und die Aufraeum-Aktion loescht spaeter alles.
    try {
      await _client.storage.from(bucket).remove([
        for (final v in [TrailImageVariant.small, TrailImageVariant.medium])
          for (final ext in ['webp', 'avif'])
            '${image.trailId}/${image.id}/${v.fileName}.$ext',
      ]);
    } catch (_) {}
  }

  @override
  Future<void> deleteImage(TrailImage image) async {
    await _client.storage.from(bucket).remove(_paths(image));
    await _client.from('images').delete().eq('id', image.id);
  }

  static List<String> pathsFor(String trailId, String imageId) => [
    for (final v in TrailImageVariant.values) ...[
      '$trailId/$imageId/${v.fileName}.webp',
      '$trailId/$imageId/${v.fileName}.avif',
    ],
  ];

  List<String> _paths(TrailImage image) => pathsFor(image.trailId, image.id);

  @visibleForTesting
  TrailImage rowToImage(Map<String, dynamic> row) => _rowToImage(row);

  TrailImage _rowToImage(Map<String, dynamic> row) {
    final id = row['id'] as String;
    final trailId = row['trail_id'] as String;
    String url(TrailImageVariant v) => _client.storage
        .from(bucket)
        .getPublicUrl('$trailId/$id/${v.fileName}.webp');
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
      isMine:
          row['uploader_id'] != null &&
          row['uploader_id'] == _client.auth.currentUser?.id,
      thumbUrl: url(TrailImageVariant.thumb),
      smallUrl: url(TrailImageVariant.small),
      mediumUrl: url(TrailImageVariant.medium),
      geoCheck: PhotoGeoCheck.parse(row['geo_check'] as String?),
      caption: row['caption'] as String? ?? '',
      license: row['license'] as String? ?? '',
      licenseUrl: row['license_url'] as String? ?? '',
      sourceUrl: row['source_url'] as String? ?? '',
      kind: row['kind'] as String?,
      sort: (row['sort'] as num?)?.toInt() ?? 0,
      thumbhash: row['thumbhash'] as String? ?? '',
      dominantColor: row['dominant_color'] as String? ?? '',
      rejectReason: RejectReason.parse(row['reject_reason'] as String?),
      decidedAt: row['decided_at'] == null
          ? null
          : DateTime.parse(row['decided_at'] as String),
    );
  }
}
