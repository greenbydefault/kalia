import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../features/community/domain/trail_image.dart';

/// Fehler beim Verarbeiten eines Bildes.
class ImageVariantsException implements Exception {
  ImageVariantsException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Längste Kante pro Variante in Pixeln. Kein Crop — das Seitenverhältnis
/// bleibt, die UI schneidet mit BoxFit.cover. ~3x Device plus Luft.
const kVariantMaxEdge = {
  TrailImageVariant.thumb: 640,
  TrailImageVariant.small: 1600,
  TrailImageVariant.medium: 2400,
};

/// Ergebnis des Resizings: PNG-Bytes der drei Varianten (Zwischenformat
/// für die AVIF-Enkodierung) plus Originalmaß.
class ResizedVariants {
  ResizedVariants({
    required this.pngBytes,
    required this.width,
    required this.height,
  });

  final Map<TrailImageVariant, Uint8List> pngBytes;
  final int width;
  final int height;
}

/// Pure Dart, kein Plugin-Zugriff: dekodiert das Original, dreht es gemäß
/// EXIF-Orientierung und erzeugt die drei Größen als PNG. Läuft in einem
/// Isolate (Upload) und im Seed-Ingest-CLI (`dart run`).
///
/// Wirft [ImageVariantsException] bei unlesbarem Format.
ResizedVariants resizeVariants(Uint8List input) {
  final img.Image? raw;
  try {
    raw = img.decodeImage(input);
  } catch (_) {
    throw ImageVariantsException(
      'Das Bildformat wird nicht unterstützt. Bitte ein JPEG-, PNG- oder '
      'WebP-Foto wählen.',
    );
  }
  if (raw == null) {
    throw ImageVariantsException(
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

  return ResizedVariants(
    pngBytes: {
      for (final v in TrailImageVariant.values)
        v: encodeVariant(kVariantMaxEdge[v]!),
    },
    width: decoded.width,
    height: decoded.height,
  );
}
