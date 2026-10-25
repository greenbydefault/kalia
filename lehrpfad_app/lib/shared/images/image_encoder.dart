import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_avif/flutter_avif.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:thumbhash/thumbhash.dart' as thumbhash;

import '../../features/community/domain/trail_image.dart';
import 'image_variants.dart';

/// WebP-Qualität je Slot, festgezogen an der 20er-Stichprobe
/// (`tools/webp_quality.json`): thumb 55, small 25, medium 18.
const kWebpQuality = {
  TrailImageVariant.thumb: 55,
  TrailImageVariant.small: 25,
  TrailImageVariant.medium: 18,
};

/// Ergebnis: AVIF- und WebP-Bytes der drei Varianten, Originalmaß,
/// ThumbHash und Dominanzfarbe.
class EncodedVariants {
  EncodedVariants({
    required this.bytes,
    required this.webp,
    required this.width,
    required this.height,
    required this.thumbhash,
    required this.dominantColor,
  });

  /// AVIF, für bereits installierte App-Stände.
  final Map<TrailImageVariant, Uint8List> bytes;

  /// WebP, das die App ausliefert.
  final Map<TrailImageVariant, Uint8List> webp;
  final int width;
  final int height;
  final String thumbhash;
  final String dominantColor;
}

/// On-Device-Encoder für den User-Upload: EXIF, längste Kante, AVIF und WebP.
/// Baut auf [resizeVariantsJpeg] (pure Dart, JPEG-Zwischenformat).
/// AVIF über flutter_avif, WebP über den Plattform-Encoder.
///
/// Der Seed-Ingest encodiert AVIF über `sips` (tool/ingest_images.dart).
/// Die Katalog-WebPs erzeugt `tools/webp_variants.py`.
class ImageVariants {
  /// Dekodiert [input], skaliert auf die drei Kantenlängen und encodiert
  /// AVIF sowie, wenn [webp] gesetzt ist, WebP. Wirft
  /// [ImageVariantsException] bei unlesbarem Format.
  static Future<EncodedVariants> encode(
    Uint8List input, {
    void Function(double fraction)? onStep,
    bool webp = true,
  }) async {
    final resized = await compute(resizeVariantsJpeg, input);
    const resizeShare = 0.375;
    onStep?.call(resizeShare);

    final entries = resized.jpegBytes.entries.toList();
    final jobs = entries.length * (webp ? 2 : 1);
    final perEncode = (1 - resizeShare) / jobs;
    var done = 0;

    void step() {
      done++;
      onStep?.call(resizeShare + perEncode * done);
    }

    final avif = await Future.wait([
      for (final entry in entries)
        encodeAvif(entry.value).then((bytes) {
          step();
          return MapEntry(entry.key, bytes);
        }),
    ]);
    final webpBytes = webp
        ? await Future.wait([
            for (final entry in entries)
              _encodeWebp(entry.value, kWebpQuality[entry.key]!).then((bytes) {
                step();
                return MapEntry(entry.key, bytes);
              }),
          ])
        : const <MapEntry<TrailImageVariant, Uint8List>>[];

    final placeholder = await compute(
      placeholderFromThumbJpeg,
      resized.jpegBytes[TrailImageVariant.thumb]!,
    );

    return EncodedVariants(
      bytes: Map.fromEntries(avif),
      webp: Map.fromEntries(webpBytes),
      width: resized.width,
      height: resized.height,
      thumbhash: placeholder.thumbhash,
      dominantColor: placeholder.dominantColor,
    );
  }
}

Future<Uint8List> _encodeWebp(Uint8List jpeg, int quality) async {
  final bytes = await FlutterImageCompress.compressWithList(
    jpeg,
    quality: quality,
    format: CompressFormat.webp,
    minWidth: 4096,
    minHeight: 4096,
  );
  if (bytes.isEmpty) {
    throw ImageVariantsException('WebP-Encoding fehlgeschlagen.');
  }
  return bytes;
}

/// ThumbHash und Durchschnittsfarbe aus dem Thumb-JPEG. Läuft im Isolate.
({String thumbhash, String dominantColor}) placeholderFromThumbJpeg(
  Uint8List jpeg,
) {
  final decoded = img.decodeJpg(jpeg);
  if (decoded == null) {
    return (thumbhash: '', dominantColor: '');
  }
  final longest = decoded.width > decoded.height
      ? decoded.width
      : decoded.height;
  final work = longest <= 100
      ? decoded
      : img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? 100 : null,
          height: decoded.height > decoded.width ? 100 : null,
        );
  final rgba = Uint8List(work.width * work.height * 4);
  var i = 0;
  var rSum = 0;
  var gSum = 0;
  var bSum = 0;
  for (final p in work) {
    final r = p.r.toInt();
    final g = p.g.toInt();
    final b = p.b.toInt();
    rgba[i++] = r;
    rgba[i++] = g;
    rgba[i++] = b;
    rgba[i++] = 255;
    rSum += r;
    gSum += g;
    bSum += b;
  }
  final n = work.width * work.height;
  final hash = thumbhash.rgbaToThumbHash(work.width, work.height, rgba);
  String hex(int value) => (value ~/ n).toRadixString(16).padLeft(2, '0');
  return (
    thumbhash: base64Encode(hash),
    dominantColor: '#${hex(rSum)}${hex(gSum)}${hex(bSum)}'.toUpperCase(),
  );
}
