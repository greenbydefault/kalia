import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/images/image_encoder.dart';
import '../../../shared/images/image_variants.dart';
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
    void Function(UploadPhase phase)? onPhase,
  });
}

/// Erzeugt drei AVIF-Varianten und laedt sie in den Bucket `trail-images`;
/// der Eintrag in `images` startet mit Status pending (Moderation).
/// Das Aufnehmen/Waehlen des Fotos liegt beim Aufrufer.
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
    void Function(UploadPhase phase)? onPhase,
  }) async {
    // Anonymer Test-Upload: ohne Session bleibt uploader_id null
    // (RLS: images insert anon pending).
    final uid = _client.auth.currentUser?.id;

    onPhase?.call(UploadPhase.verarbeiten);
    final EncodedVariants resized;
    try {
      resized = await ImageVariants.encode(bytes);
    } on ImageVariantsException catch (e) {
      throw ImageUploadException(e.message);
    }
    final variants = resized.bytes;

    onPhase?.call(UploadPhase.hochladen);
    final imageId = _uuid.v4();
    final paths = SupabaseImagesRepository.pathsFor(trailId, imageId);
    try {
      await Future.wait([
        for (final entry in variants.entries)
          _client.storage
              .from(SupabaseImagesRepository.bucket)
              .uploadBinary(
                '$trailId/$imageId/${entry.key.fileName}.avif',
                entry.value,
                fileOptions: FileOptions(
                  contentType: 'image/avif',
                  cacheControl: '31536000',
                ),
              ),
      ]);
    } catch (e) {
      throw ImageUploadException('Upload fehlgeschlagen: $e');
    }

    try {
      await _client.from('images').insert({
        'id': imageId,
        'trail_id': trailId,
        'station_id': stationId,
        'uploader_id': ?uid,
        'source': 'user',
        'status': 'pending',
        'credit': credit,
        'width': resized.width,
        'height': resized.height,
        'mime_type': 'image/avif',
        'thumb_bytes': variants[TrailImageVariant.thumb]!.length,
        'small_bytes': variants[TrailImageVariant.small]!.length,
        'medium_bytes': variants[TrailImageVariant.medium]!.length,
      });
    } catch (e) {
      // Dateien wieder aufraeumen, damit keine Waisen im Storage liegen
      await _client.storage
          .from(SupabaseImagesRepository.bucket)
          .remove(paths)
          .catchError((_) => const <FileObject>[]);
      throw ImageUploadException('Speichern fehlgeschlagen: $e');
    }
  }
}
