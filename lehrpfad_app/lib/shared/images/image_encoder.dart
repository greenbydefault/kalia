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
/// Baut auf [resizeVariants] (pure Dart) und encodiert über das native
/// flutter_avif-Plugin. Dateikonvention `{variant}.avif` — die Auslieferung
/// (Storage) ist Sache des Aufrufers.
///
/// Der Seed-Ingest nutzt dieselbe Resize-Logik, encodiert AVIF aber über
/// `sips` (siehe tool/ingest_images.dart), damit er ohne Xcode läuft.
class ImageVariants {
  /// Dekodiert [input], skaliert auf die drei Kantenlängen und encodiert
  /// AVIF. Wirft [ImageVariantsException] bei unlesbarem Format.
  static Future<EncodedVariants> encode(Uint8List input) async {
    final resized = await compute(resizeVariants, input);

    // encodeAvif arbeitet asynchron auf nativem Worker-Thread,
    // blockiert die UI also nicht.
    final bytes = <TrailImageVariant, Uint8List>{
      for (final entry in resized.pngBytes.entries)
        entry.key: await encodeAvif(entry.value),
    };

    return EncodedVariants(
      bytes: bytes,
      width: resized.width,
      height: resized.height,
    );
  }
}
