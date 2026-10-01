import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:lehrpfad_app/features/community/domain/photo_geo_check.dart';
import 'package:lehrpfad_app/features/trail/domain/trail.dart';

Trail _trail({
  String form = 'linie',
  List<LatLng> route = const [],
  List<LatLng> area = const [],
}) => Trail(
  id: 't',
  name: 'T',
  typ: 'lehrpfad',
  form: form,
  kurzbeschreibung: 'k',
  beschreibung: 'b',
  laengeKm: 1,
  dauerMin: 60,
  rundkurs: false,
  markierung: 'm',
  betreiber: 'b',
  region: 'r',
  anreise: 'a',
  startName: 's',
  arten: const [],
  route: route,
  area: area,
  stationen: const [],
  amenities: const [],
);

// Ein Grad Breite sind ~111 km; 0.001 Grad ~ 111 m.
final _linie = _trail(route: const [LatLng(54.0, 10.0), LatLng(54.0, 10.02)]);
final _flaeche = _trail(
  form: 'flaeche',
  area: const [
    LatLng(54.0, 10.0),
    LatLng(54.0, 10.002),
    LatLng(54.002, 10.002),
    LatLng(54.002, 10.0),
  ],
);

void main() {
  group('evaluate', () {
    test('kein GPS ergibt none', () {
      expect(PhotoGeoCheck.evaluate(_linie, null), PhotoGeoCheck.none);
    });

    test('Trail ohne Geometrie ergibt none', () {
      expect(
        PhotoGeoCheck.evaluate(_trail(), const LatLng(54, 10)),
        PhotoGeoCheck.none,
      );
    });

    test('Linie: auf dem Weg und im 250-m-Puffer ist match', () {
      expect(
        PhotoGeoCheck.evaluate(_linie, const LatLng(54.0, 10.01)),
        PhotoGeoCheck.match,
      );
      // ~111 m neben dem Weg
      expect(
        PhotoGeoCheck.evaluate(_linie, const LatLng(54.001, 10.01)),
        PhotoGeoCheck.match,
      );
    });

    test('Linie: ~1 km daneben ist near, ~5 km daneben ist far', () {
      expect(
        PhotoGeoCheck.evaluate(_linie, const LatLng(54.009, 10.01)),
        PhotoGeoCheck.near,
      );
      expect(
        PhotoGeoCheck.evaluate(_linie, const LatLng(54.045, 10.01)),
        PhotoGeoCheck.far,
      );
    });

    test('Flaeche: im Polygon ist match, 150-m-Puffer, danach near/far', () {
      expect(
        PhotoGeoCheck.evaluate(_flaeche, const LatLng(54.001, 10.001)),
        PhotoGeoCheck.match,
      );
      // ~111 m ausserhalb (Puffer 150 m)
      expect(
        PhotoGeoCheck.evaluate(_flaeche, const LatLng(54.003, 10.001)),
        PhotoGeoCheck.match,
      );
      // ~330 m ausserhalb
      expect(
        PhotoGeoCheck.evaluate(_flaeche, const LatLng(54.005, 10.001)),
        PhotoGeoCheck.near,
      );
      expect(
        PhotoGeoCheck.evaluate(_flaeche, const LatLng(55.0, 10.001)),
        PhotoGeoCheck.far,
      );
    });
  });

  group('parse', () {
    test('null bleibt null, bekannte Werte werden gemappt', () {
      expect(PhotoGeoCheck.parse(null), isNull);
      for (final c in PhotoGeoCheck.values) {
        expect(PhotoGeoCheck.parse(c.dbValue), c);
      }
    });

    test('unbekannter Wert faellt auf none', () {
      expect(PhotoGeoCheck.parse('???'), PhotoGeoCheck.none);
    });
  });
}
