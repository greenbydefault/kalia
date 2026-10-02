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
  ///
  /// [onStep] meldet den Anteil 0..1 an der Encode-Arbeit: nach dem Resize
  /// und nach jedem fertigen AVIF (Resize 3/8, je Encode 5/24).
  static Future<EncodedVariants> encode(
    Uint8List input, {
    void Function(double fraction)? onStep,
  }) async {
    final resized = await compute(resizeVariantsJpeg, input);
    const resizeShare = 0.375;
    onStep?.call(resizeShare);

    // Die drei Encodes laufen parallel; der native Encoder arbeitet auf
    // Worker-Threads und blockiert die UI nicht.
    final entries = resized.jpegBytes.entries.toList();
    final perEncode = (1 - resizeShare) / entries.length;
    var done = 0;
    final encoded = await Future.wait([
      for (final entry in entries)
        encodeAvif(entry.value).then((bytes) {
          done++;
          onStep?.call(resizeShare + perEncode * done);
          return bytes;
        }),
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
