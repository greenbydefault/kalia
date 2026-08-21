import 'package:flutter/foundation.dart';
import 'package:flutter_avif/flutter_avif.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../domain/trail_image.dart';
import 'supabase_images_repository.dart';

/// Fehler beim Verarbeiten oder Hochladen eines Bildes.
class ImageUploadException implements Exception {
  ImageUploadException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Ergebnis des Resizings: PNG-Bytes der drei Varianten (Zwischenformat
/// fuer die AVIF-Enkodierung) plus Originalmass.
class _ResizedVariants {
  _ResizedVariants({
    required this.thumbPng,
    required this.smallPng,
    required this.mediumPng,
    required this.width,
    required this.height,
  });

  final Uint8List thumbPng;
  final Uint8List smallPng;
  final Uint8List mediumPng;
  final int width;
  final int height;
}

/// Laengste Kante pro Variante in Pixeln.
const _variantSizes = {
  TrailImageVariant.thumb: 200,
  TrailImageVariant.small: 600,
  TrailImageVariant.medium: 1600,
};

/// Laeuft in einem Hintergrund-Isolate (pure Dart, kein Plugin-Zugriff):
/// dekodiert das Original, dreht es gemaess EXIF-Orientierung und erzeugt
/// die drei Groessen als PNG.
_ResizedVariants _resizeVariants(Uint8List input) {
  final raw = img.decodeImage(input);
  if (raw == null) {
    throw ImageUploadException(
      'Das Bildformat wird nicht unterstützt. Bitte ein JPEG-, PNG- oder '
      'WebP-Foto wählen.',
    );
  }
  final decoded = img.bakeOrientation(raw);

  Uint8List encodeVariant(int maxEdge) {
    final longest =
        decoded.width > decoded.height ? decoded.width : decoded.height;
    if (longest <= maxEdge) return img.encodePng(decoded);
    final work = img.copyResize(
      decoded,
      width: decoded.width >= decoded.height ? maxEdge : null,
      height: decoded.height > decoded.width ? maxEdge : null,
    );
    return img.encodePng(work);
  }

  return _ResizedVariants(
    thumbPng: encodeVariant(_variantSizes[TrailImageVariant.thumb]!),
    smallPng: encodeVariant(_variantSizes[TrailImageVariant.small]!),
    mediumPng: encodeVariant(_variantSizes[TrailImageVariant.medium]!),
    width: decoded.width,
    height: decoded.height,
  );
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
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw ImageUploadException('Bitte zuerst anmelden.');
    }

    // imageQuality < 100 zwingt iOS zu JPEG- statt HEIF-Ausgabe,
    // damit das Dekodieren garantiert klappt.
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 95,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final resized = await compute(_resizeVariants, bytes);

    // encodeAvif arbeitet asynchron auf nativem Worker-Thread,
    // blockiert die UI also nicht.
    final variants = <TrailImageVariant, Uint8List>{
      TrailImageVariant.thumb: await encodeAvif(resized.thumbPng),
      TrailImageVariant.small: await encodeAvif(resized.smallPng),
      TrailImageVariant.medium: await encodeAvif(resized.mediumPng),
    };

    final imageId = _uuid.v4();
    final paths = SupabaseImagesRepository.pathsFor(trailId, imageId);
    try {
      await Future.wait([
        for (final entry in variants.entries)
          _client.storage.from(SupabaseImagesRepository.bucket).uploadBinary(
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
        'uploader_id': uid,
        'source': 'user',
        'status': 'pending',
        'credit': credit,
        'width': resized.width,
        'height': resized.height,
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
