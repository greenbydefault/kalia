import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lehrpfad_app/features/community/domain/trail_image.dart';
import 'package:lehrpfad_app/shared/images/image_variants.dart';

import 'support/jpeg_fixtures.dart';

Uint8List _png({required int width, required int height}) {
  final im = img.Image(width: width, height: height);
  for (final px in im) {
    px
      ..r = 120
      ..g = 160
      ..b = 200;
  }
  return Uint8List.fromList(img.encodePng(im));
}

void main() {
  test('Varianten-Kantenlängen: 480 / 900 / 2000', () {
    expect(kVariantMaxEdge[TrailImageVariant.thumb], 480);
    expect(kVariantMaxEdge[TrailImageVariant.small], 900);
    expect(kVariantMaxEdge[TrailImageVariant.medium], 2000);
  });

  test('resizeVariants skaliert langes Querformat auf die drei Kanten', () {
    final out = resizeVariants(_png(width: 4000, height: 2000));

    expect(out.width, 4000);
    expect(out.height, 2000);
    expect(out.pngBytes.keys, containsAll(TrailImageVariant.values));

    final expected = {
      TrailImageVariant.thumb: 480,
      TrailImageVariant.small: 900,
      TrailImageVariant.medium: 2000,
    };
    for (final entry in expected.entries) {
      final decoded = img.decodeImage(out.pngBytes[entry.key]!);
      expect(decoded, isNotNull, reason: entry.key.name);
      expect(
        decoded!.width > decoded.height ? decoded.width : decoded.height,
        entry.value,
        reason: entry.key.name,
      );
      expect(decoded.width, entry.value);
      expect(decoded.height, entry.value ~/ 2);
    }
  });

  test('resizeVariants skaliert Hochformat über die Höhe', () {
    final out = resizeVariants(_png(width: 1000, height: 4000));
    final decoded = img.decodeImage(out.pngBytes[TrailImageVariant.medium]!);
    expect(decoded!.height, 2000);
    expect(decoded.width, 500);
  });

  test('resizeVariants lässt kleine Quelle unverändert', () {
    final out = resizeVariants(_png(width: 400, height: 256));
    for (final v in TrailImageVariant.values) {
      final decoded = img.decodeImage(out.pngBytes[v]!);
      expect(decoded!.width, 400, reason: v.name);
      expect(decoded.height, 256, reason: v.name);
    }
  });

  test('resizeVariantsJpeg liefert JPEG mit denselben Kanten', () {
    final out = resizeVariantsJpeg(_png(width: 4000, height: 2000));

    expect(out.width, 4000);
    expect(out.height, 2000);
    for (final entry in kVariantMaxEdge.entries) {
      final bytes = out.jpegBytes[entry.key]!;
      // JPEG-Magic FF D8
      expect(bytes[0], 0xFF, reason: entry.key.name);
      expect(bytes[1], 0xD8, reason: entry.key.name);
      final decoded = img.decodeImage(bytes);
      expect(decoded!.width, entry.value, reason: entry.key.name);
      expect(decoded.height, entry.value ~/ 2, reason: entry.key.name);
    }
  });

  test('resizeVariantsJpeg dreht Hochformat über die Höhe', () {
    final out = resizeVariantsJpeg(_png(width: 1000, height: 4000));
    final decoded = img.decodeImage(out.jpegBytes[TrailImageVariant.medium]!);
    expect(decoded!.height, 2000);
    expect(decoded.width, 500);
  });

  test('resizeVariantsJpeg wirft lesbaren Fehler bei unlesbarem Format', () {
    expect(
      () => resizeVariantsJpeg(Uint8List.fromList([1, 2, 3, 4])),
      throwsA(isA<ImageVariantsException>()),
    );
  });

  test('resizeVariants wirft lesbaren Fehler bei unlesbarem Format', () {
    expect(
      () => resizeVariants(Uint8List.fromList([1, 2, 3, 4])),
      throwsA(isA<ImageVariantsException>()),
    );
  });

  test('Zwischen-JPEGs enthalten kein EXIF (kein GPS, keine PII)', () {
    final input = jpegWithGps(
      lat: [(54, 1), (18, 1), (30, 1)],
      latRef: 'N',
      lon: [(10, 1), (6, 1), (0, 1)],
      lonRef: 'E',
    );
    // Vorbedingung: das Original traegt wirklich GPS
    expect(img.decodeJpgExif(input)?.gpsIfd.isEmpty, isFalse);

    final out = resizeVariantsJpeg(input);
    for (final entry in out.jpegBytes.entries) {
      final exif = img.decodeJpgExif(entry.value);
      expect(
        exif == null || exif.isEmpty,
        isTrue,
        reason: '${entry.key.name} traegt noch EXIF',
      );
    }
  });
}
