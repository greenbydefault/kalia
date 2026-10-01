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
/// bleibt, die UI schneidet mit BoxFit.cover. Mobile-first: Peek/Strip,
/// Header-Slider, Fullscreen.
const kVariantMaxEdge = {
  TrailImageVariant.thumb: 480,
  TrailImageVariant.small: 900,
  TrailImageVariant.medium: 2000,
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

/// Wie [ResizedVariants], aber JPEG-Zwischenformat. Für den User-Upload:
/// JPEG-Encoding ist ein Vielfaches schneller als PNG bei 2000 px und der
/// native AVIF-Encoder dekodiert JPEG problemlos.
class ResizedJpegVariants {
  ResizedJpegVariants({
    required this.jpegBytes,
    required this.width,
    required this.height,
  });

  final Map<TrailImageVariant, Uint8List> jpegBytes;
  final int width;
  final int height;
}

/// JPEG-Qualität des Zwischenformats. Hoch genug, dass erst der
/// AVIF-Encoder (Quantizer 25–40) die sichtbare Kompression setzt.
const kJpegIntermediateQuality = 92;

/// Pure Dart, kein Plugin-Zugriff: dekodiert das Original, dreht es gemäß
/// EXIF-Orientierung und erzeugt die drei Größen als PNG. Läuft im
/// Seed-Ingest-CLI (`dart run`).
///
/// Wirft [ImageVariantsException] bei unlesbarem Format.
ResizedVariants resizeVariants(Uint8List input) {
  final r = _resizeWith(input, (im) => img.encodePng(im));
  return ResizedVariants(pngBytes: r.bytes, width: r.width, height: r.height);
}

/// Wie [resizeVariants], Zwischenformat JPEG. Läuft in einem Isolate
/// (User-Upload).
ResizedJpegVariants resizeVariantsJpeg(Uint8List input) {
  final r = _resizeWith(
    input,
    (im) => img.encodeJpg(im, quality: kJpegIntermediateQuality),
  );
  return ResizedJpegVariants(
    jpegBytes: r.bytes,
    width: r.width,
    height: r.height,
  );
}

({Map<TrailImageVariant, Uint8List> bytes, int width, int height})
_resizeWith(Uint8List input, List<int> Function(img.Image) encode) {
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
    if (longest <= maxEdge) return Uint8List.fromList(encode(decoded));
    final work = img.copyResize(
      decoded,
      width: decoded.width >= decoded.height ? maxEdge : null,
      height: decoded.height > decoded.width ? maxEdge : null,
    );
    return Uint8List.fromList(encode(work));
  }

  return (
    bytes: {
      for (final v in TrailImageVariant.values)
        v: encodeVariant(kVariantMaxEdge[v]!),
    },
    width: decoded.width,
    height: decoded.height,
  );
}
