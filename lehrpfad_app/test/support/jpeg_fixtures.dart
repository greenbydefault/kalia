import 'dart:typed_data';

import 'package:image/image.dart' as img;
// Rational ist nicht oeffentlich exportiert, wird fuers Testbild gebraucht.
// ignore: implementation_imports
import 'package:image/src/util/rational.dart';

/// JPEG mit GPS im Kamera-Format: Grad, Minuten, Sekunden als drei Rationals.
Uint8List jpegWithGps({
  required List<(int, int)> lat,
  required String latRef,
  required List<(int, int)> lon,
  required String lonRef,
}) {
  final im = img.Image(width: 16, height: 16);
  final gps = im.exif.gpsIfd;
  gps.data[0x0001] = img.IfdValueAscii(latRef);
  gps.data[0x0002] = img.IfdValueRational.list([
    for (final r in lat) Rational(r.$1, r.$2),
  ]);
  gps.data[0x0003] = img.IfdValueAscii(lonRef);
  gps.data[0x0004] = img.IfdValueRational.list([
    for (final r in lon) Rational(r.$1, r.$2),
  ]);
  return Uint8List.fromList(img.encodeJpg(im));
}
