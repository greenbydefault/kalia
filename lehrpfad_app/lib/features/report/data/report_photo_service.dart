import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../domain/report_models.dart';
import '../report_config.dart';
import 'draft_store.dart';
import 'report_providers.dart';

class PhotoSaveException implements Exception {
  PhotoSaveException(this.message);
  final String message;

  @override
  String toString() => message;
}

class CompressedPhoto {
  const CompressedPhoto(this.bytes, this.width, this.height);
  final Uint8List bytes;
  final int width;
  final int height;
}

/// Dreht nach EXIF, skaliert die längste Kante auf `photoMaxEdgePx` und
/// kodiert neu als JPEG. Das Neu-Kodieren verwirft EXIF und damit
/// GPS-Daten (Spec 7.3).
CompressedPhoto compressReportPhoto(Uint8List input) {
  final decoded = img.decodeImage(input);
  if (decoded == null) throw PhotoSaveException('Bild nicht lesbar.');
  var image = img.bakeOrientation(decoded);
  final longest = image.width > image.height ? image.width : image.height;
  if (longest > cfg.photoMaxEdgePx) {
    image = img.copyResize(
      image,
      width: image.width >= image.height ? cfg.photoMaxEdgePx : null,
      height: image.height > image.width ? cfg.photoMaxEdgePx : null,
      interpolation: img.Interpolation.average,
    );
  }
  final out = Uint8List.fromList(
    img.encodeJpg(image, quality: cfg.photoJpegQuality),
  );
  return CompressedPhoto(out, image.width, image.height);
}

/// Foto aufnehmen oder wählen, komprimieren, im Entwurf ablegen.
class ReportPhotoService {
  ReportPhotoService(this._store, {ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ReportDraftStore _store;
  final ImagePicker _picker;

  /// `null` bei Abbruch im Picker. Wirft [PhotoSaveException], wenn das Foto
  /// nicht abgelegt werden kann.
  Future<DraftPhoto?> add({
    required String draftId,
    String? pointId,
    ImageSource source = ImageSource.camera,
  }) async {
    final existing = await _store.photos(draftId);
    final forPoint = existing.where((p) => p.pointId == pointId).length;
    if (existing.length >= cfg.maxPhotosPerSubmission ||
        (pointId != null && forPoint >= cfg.maxPhotosPerMarker)) {
      throw PhotoSaveException('Mehr Fotos gehen nicht.');
    }
    final picked = await _picker.pickImage(source: source, imageQuality: 95);
    if (picked == null) return null;
    final raw = await picked.readAsBytes();
    final CompressedPhoto compressed;
    try {
      compressed = await compute(compressReportPhoto, raw);
    } catch (_) {
      throw PhotoSaveException('Bild nicht lesbar.');
    }
    final id = newReportId();
    try {
      final path = await _store.writePhotoBytes(draftId, id, compressed.bytes);
      final photo = DraftPhoto(
        id: id,
        draftId: draftId,
        pointId: pointId,
        localPath: path,
        width: compressed.width,
        height: compressed.height,
      );
      await _store.savePhoto(photo);
      return photo;
    } catch (_) {
      throw PhotoSaveException('Speicher voll.');
    }
  }

  Future<void> remove(DraftPhoto photo) =>
      _store.deletePhoto(photo.draftId, photo.id);
}
