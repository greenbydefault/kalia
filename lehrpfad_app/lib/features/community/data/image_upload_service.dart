import 'package:image_picker/image_picker.dart';
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

/// Nimmt ein Foto auf / waehlt eines aus, erzeugt drei AVIF-Varianten
/// und laedt sie in den Bucket `trail-images`; der Eintrag in `images`
/// startet mit Status pending (Moderation).
class ImageUploadService {
  ImageUploadService(this._client);

  final SupabaseClient _client;

  static final _uuid = Uuid();

  /// Gibt null zurueck, wenn der User die Auswahl abbricht.
  /// Wirft [ImageUploadException] bei lesbaren Fehlern.
  Future<void> pickAndUpload({
    required String trailId,
    required int? stationId,
    required String credit,
    required ImageSource source,
  }) async {
    // Anonymer Test-Upload: ohne Session bleibt uploader_id null
    // (RLS: images insert anon pending).
    final uid = _client.auth.currentUser?.id;

    // imageQuality < 100 zwingt iOS zu JPEG- statt HEIF-Ausgabe,
    // damit das Dekodieren garantiert klappt.
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 95,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final EncodedVariants resized;
    try {
      resized = await ImageVariants.encode(bytes);
    } on ImageVariantsException catch (e) {
      throw ImageUploadException(e.message);
    }
    final variants = resized.bytes;

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
