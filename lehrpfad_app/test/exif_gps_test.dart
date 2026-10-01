import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lehrpfad_app/shared/images/exif_gps.dart';

import 'support/jpeg_fixtures.dart';

void main() {
  test('liest Grad/Minuten/Sekunden und rechnet in Dezimalgrad', () {
    final bytes = jpegWithGps(
      lat: [(54, 1), (18, 1), (3000, 100)], // 54° 18' 30"
      latRef: 'N',
      lon: [(10, 1), (6, 1), (0, 1)], // 10° 6' 0"
      lonRef: 'E',
    );
    final p = readExifGps(bytes)!;
    expect(p.latitude, closeTo(54.308333, 1e-5));
    expect(p.longitude, closeTo(10.1, 1e-5));
  });

  test('Sued und West werden negativ', () {
    final bytes = jpegWithGps(
      lat: [(33, 1), (30, 1), (0, 1)],
      latRef: 'S',
      lon: [(70, 1), (0, 1), (0, 1)],
      lonRef: 'W',
    );
    final p = readExifGps(bytes)!;
    expect(p.latitude, closeTo(-33.5, 1e-9));
    expect(p.longitude, closeTo(-70, 1e-9));
  });

  test('0/0 gilt als kein GPS', () {
    final bytes = jpegWithGps(
      lat: [(0, 1), (0, 1), (0, 1)],
      latRef: 'N',
      lon: [(0, 1), (0, 1), (0, 1)],
      lonRef: 'E',
    );
    expect(readExifGps(bytes), isNull);
  });

  test('JPEG ohne EXIF, kaputte Bytes und leere Bytes ergeben null', () {
    final plain = Uint8List.fromList(
      img.encodeJpg(img.Image(width: 8, height: 8)),
    );
    expect(readExifGps(plain), isNull);
    expect(readExifGps(Uint8List.fromList([1, 2, 3])), isNull);
    expect(readExifGps(Uint8List(0)), isNull);
  });
}
