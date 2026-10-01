import 'package:flutter/foundation.dart';
import 'package:flutter_avif/flutter_avif.dart';

import '../../features/community/domain/trail_image.dart';
import 'image_variants.dart';

/// Ergebnis: AVIF-Bytes der drei Varianten plus Originalmaß.
class EncodedVariants {
  EncodedVariants({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Map<TrailImageVariant, Uint8List> bytes;
  final int width;
  final int height;
}

/// On-Device-Encoder für den User-Upload: EXIF, längste Kante, AVIF.
/// Baut auf [resizeVariantsJpeg] (pure Dart, JPEG-Zwischenformat) und
/// encodiert über das native flutter_avif-Plugin. Dateikonvention `{variant}.avif` — die Auslieferung
/// (Storage) ist Sache des Aufrufers.
///
/// Der Seed-Ingest nutzt dieselbe Resize-Logik, encodiert AVIF aber über
/// `sips` (siehe tool/ingest_images.dart), damit er ohne Xcode läuft.
class ImageVariants {
  /// Dekodiert [input], skaliert auf die drei Kantenlängen und encodiert
  /// AVIF. Wirft [ImageVariantsException] bei unlesbarem Format.
  static Future<EncodedVariants> encode(Uint8List input) async {
    final resized = await compute(resizeVariantsJpeg, input);

    // Die drei Encodes laufen parallel; der native Encoder arbeitet auf
    // Worker-Threads und blockiert die UI nicht.
    final entries = resized.jpegBytes.entries.toList();
    final encoded = await Future.wait([
      for (final entry in entries) encodeAvif(entry.value),
    ]);
    final bytes = <TrailImageVariant, Uint8List>{
      for (var i = 0; i < entries.length; i++) entries[i].key: encoded[i],
    };

    return EncodedVariants(
      bytes: bytes,
      width: resized.width,
      height: resized.height,
    );
  }
}
