import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:latlong2/latlong.dart';

/// Liest den GPS-Ort aus dem EXIF eines JPEGs, rein im Speicher.
///
/// Das Ergebnis ist fluechtig: Aufrufer duerfen es nur fuer den lokalen
/// Vergleich mit der Trail-Geometrie nutzen und nie speichern, loggen oder
/// senden. `null` bei fehlendem/ungueltigem GPS und bei Nicht-JPEG.
///
/// `gpsLatitude`/`gpsLongitude` des image-Pakets lesen nur den ersten
/// Rational (Grad). Kameras schreiben aber Grad, Minuten, Sekunden — daher
/// werden alle drei Werte hier selbst ausgewertet.
LatLng? readExifGps(Uint8List bytes) {
  try {
    final exif = img.decodeJpgExif(bytes);
    if (exif == null) return null;
    final gps = exif.gpsIfd;
    final lat = _coordinate(gps[0x0002], gps[0x0001]?.toString(), 'S');
    final lon = _coordinate(gps[0x0004], gps[0x0003]?.toString(), 'W');
    if (lat == null || lon == null) return null;
    // 0/0 ist der typische "kein Fix"-Platzhalter.
    if (lat == 0 && lon == 0) return null;
    return LatLng(lat, lon);
  } catch (_) {
    return null;
  }
}

double? _coordinate(img.IfdValue? value, String? ref, String negativeRef) {
  if (value == null || value.length == 0) return null;
  final parts = <double>[
    for (var i = 0; i < value.length && i < 3; i++) value.toDouble(i),
  ];
  if (parts.any((p) => p.isNaN || p.isInfinite || p < 0)) return null;
  final degrees =
      parts[0] +
      (parts.length > 1 ? parts[1] / 60 : 0) +
      (parts.length > 2 ? parts[2] / 3600 : 0);
  final negative = (ref ?? '').trim().toUpperCase().startsWith(negativeRef);
  return negative ? -degrees : degrees;
}
