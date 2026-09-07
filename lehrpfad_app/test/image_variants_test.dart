import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lehrpfad_app/features/community/domain/trail_image.dart';
import 'package:lehrpfad_app/shared/images/image_variants.dart';

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
  test('Varianten-Kantenlängen: 640 / 1600 / 2400', () {
    expect(kVariantMaxEdge[TrailImageVariant.thumb], 640);
    expect(kVariantMaxEdge[TrailImageVariant.small], 1600);
    expect(kVariantMaxEdge[TrailImageVariant.medium], 2400);
  });

  test('resizeVariants skaliert langes Querformat auf die drei Kanten', () {
    final out = resizeVariants(_png(width: 4000, height: 2000));

    expect(out.width, 4000);
    expect(out.height, 2000);
    expect(out.pngBytes.keys, containsAll(TrailImageVariant.values));

    final expected = {
      TrailImageVariant.thumb: 640,
      TrailImageVariant.small: 1600,
      TrailImageVariant.medium: 2400,
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
    expect(decoded!.height, 2400);
    expect(decoded.width, 600);
  });

  test('resizeVariants lässt kleine Quelle unverändert', () {
    final out = resizeVariants(_png(width: 500, height: 320));
    for (final v in TrailImageVariant.values) {
      final decoded = img.decodeImage(out.pngBytes[v]!);
      expect(decoded!.width, 500, reason: v.name);
      expect(decoded.height, 320, reason: v.name);
    }
  });

  test('resizeVariants wirft lesbaren Fehler bei unlesbarem Format', () {
    expect(
      () => resizeVariants(Uint8List.fromList([1, 2, 3, 4])),
      throwsA(isA<ImageVariantsException>()),
    );
  });
}
