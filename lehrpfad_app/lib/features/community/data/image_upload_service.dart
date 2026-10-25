import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/images/image_encoder.dart';
import '../../../shared/images/image_variants.dart';
import '../domain/photo_geo_check.dart';
import '../domain/trail_image.dart';
import 'supabase_images_repository.dart';

/// Fehler beim Verarbeiten oder Hochladen eines Bildes.
class ImageUploadException implements Exception {
  ImageUploadException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Phase eines laufenden Uploads, sichtbar fuer die UI.
enum UploadPhase { verarbeiten, hochladen }

/// Seam des Uploads: Bytes rein, pending-Eintrag raus. Prod ist
/// [ImageUploadService], Tests nutzen einen Fake.
abstract class ImageUploader {
  /// Wirft [ImageUploadException] bei lesbaren Fehlern.
  Future<void> upload({
    required String trailId,
    required int? stationId,
    required String credit,
    required Uint8List bytes,
    required PhotoGeoCheck geoCheck,
    void Function(UploadPhase phase, double fraction)? onProgress,
  });
}

/// Anteile am Gesamtfortschritt: Verarbeiten (Resize + AVIF) bis 40 %,
/// Upload bis 90 %, Eintrag in `images` bis 100 %.
const kProgressProcessed = 0.4;
const kProgressUploaded = 0.9;

/// Erzeugt drei AVIF- und drei WebP-Varianten und laedt sie in den Bucket
/// `trail-images`; der Eintrag in `images` startet mit Status pending.
/// Das Aufnehmen/Waehlen des Fotos liegt beim Aufrufer. Der EXIF-Ort wird
/// vorher lokal zu [PhotoGeoCheck] verdichtet; die Varianten tragen kein EXIF.
class ImageUploadService implements ImageUploader {
  ImageUploadService(this._client);

  final SupabaseClient _client;

  static final _uuid = Uuid();

  @override
  Future<void> upload({
    required String trailId,
    required int? stationId,
    required String credit,
    required Uint8List bytes,
    required PhotoGeoCheck geoCheck,
    void Function(UploadPhase phase, double fraction)? onProgress,
  }) async {
    // Anonymer Test-Upload: ohne Session bleibt uploader_id null
    // (RLS: images insert anon pending).
    final uid = _client.auth.currentUser?.id;

    onProgress?.call(UploadPhase.verarbeiten, 0);
    final EncodedVariants resized;
    try {
      resized = await ImageVariants.encode(
        bytes,
        onStep: (f) =>
            onProgress?.call(UploadPhase.verarbeiten, f * kProgressProcessed),
      );
    } on ImageVariantsException catch (e) {
      throw ImageUploadException(e.message);
    }
    final variants = resized.bytes;
    final webp = resized.webp;

    onProgress?.call(UploadPhase.hochladen, kProgressProcessed);
    final imageId = _uuid.v4();
    final paths = SupabaseImagesRepository.pathsFor(trailId, imageId);
    final files = [
      for (final entry in variants.entries)
        (
          path: '$trailId/$imageId/${entry.key.fileName}.avif',
          bytes: entry.value,
          type: 'image/avif',
        ),
      for (final entry in webp.entries)
        (
          path: '$trailId/$imageId/${entry.key.fileName}.webp',
          bytes: entry.value,
          type: 'image/webp',
        ),
    ];
    final totalBytes = files.fold<int>(0, (a, b) => a + b.bytes.length);
    var uploadedBytes = 0;
    try {
      await Future.wait([
        for (final file in files)
          _client.storage
              .from(SupabaseImagesRepository.bucket)
              .uploadBinary(
                file.path,
                file.bytes,
                fileOptions: FileOptions(
                  contentType: file.type,
                  cacheControl: '31536000',
                ),
              )
              .then((_) {
                uploadedBytes += file.bytes.length;
                onProgress?.call(
                  UploadPhase.hochladen,
                  kProgressProcessed +
                      (kProgressUploaded - kProgressProcessed) *
                          (totalBytes == 0 ? 1 : uploadedBytes / totalBytes),
                );
              }),
      ]);
    } catch (e) {
      throw ImageUploadException('Upload fehlgeschlagen: $e');
    }

    try {
      await _insertImage({
        'id': imageId,
        'trail_id': trailId,
        'station_id': stationId,
        'uploader_id': ?uid,
        'source': 'user',
        'status': 'pending',
        'credit': credit,
        'geo_check': geoCheck.dbValue,
        'width': resized.width,
        'height': resized.height,
        'mime_type': 'image/webp',
        'thumb_bytes': webp[TrailImageVariant.thumb]!.length,
        'small_bytes': webp[TrailImageVariant.small]!.length,
        'medium_bytes': webp[TrailImageVariant.medium]!.length,
        'thumbhash': resized.thumbhash,
        'dominant_color': resized.dominantColor,
      });
    } catch (e) {
      await _client.storage
          .from(SupabaseImagesRepository.bucket)
          .remove(paths)
          .catchError((_) => const <FileObject>[]);
      throw ImageUploadException('Speichern fehlgeschlagen: $e');
    }
    onProgress?.call(UploadPhase.hochladen, 1);
  }

  /// Migration 0037 kann auf dem Server noch fehlen: dann ohne die neuen
  /// Spalten erneut schreiben, der Upload selbst bleibt gültig.
  Future<void> _insertImage(Map<String, dynamic> row) async {
    try {
      await _client.from('images').insert(row);
    } on PostgrestException catch (e) {
      if (e.code != '42703') rethrow;
      row.remove('thumbhash');
      row.remove('dominant_color');
      await _client.from('images').insert(row);
    }
  }
}
