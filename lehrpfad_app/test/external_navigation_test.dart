import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:lehrpfad_app/features/trail/domain/amenity.dart';
import 'package:lehrpfad_app/features/trail/domain/external_navigation.dart';
import 'package:lehrpfad_app/features/trail/domain/trail.dart';

Trail _trail({
  List<LatLng> route = const [LatLng(53.0, 13.0), LatLng(53.01, 13.0)],
  List<Amenity> amenities = const [],
  String startName = 'Parkplatz Start',
  String region = 'Ostprignitz-Ruppin',
}) {
  return Trail(
    id: 't',
    name: 'Test',
    typ: 'wald',
    kurzbeschreibung: '',
    beschreibung: '',
    laengeKm: 1,
    dauerMin: 30,
    rundkurs: true,
    markierung: '',
    betreiber: '',
    region: region,
    anreise: '',
    startName: startName,
    arten: const [],
    route: route,
    stationen: const [],
    amenities: amenities,
  );
}

Amenity _parking(int osmId, LatLng position, {String? name}) {
  return Amenity(
    osmId: osmId,
    position: position,
    kategorie: 'parking',
    name: name,
  );
}

void main() {
  test('ohne Geometrie: kein Ziel', () {
    final trail = _trail(route: const []);
    expect(trail.startOrNull, isNull);
    expect(navigationDestinationFor(trail), isNull);
  });

  test('ohne Parkplatz: Trail-Start', () {
    final dest = navigationDestinationFor(_trail());
    expect(dest, isNotNull);
    expect(dest!.isParking, isFalse);
    expect(dest.position, const LatLng(53.0, 13.0));
    expect(dest.label, 'Parkplatz Start');
  });

  test('nächster Parkplatz schlägt den Start', () {
    final dest = navigationDestinationFor(
      _trail(
        amenities: [
          _parking(1, const LatLng(53.05, 13.0), name: 'Weit weg'),
          _parking(2, const LatLng(53.001, 13.0), name: 'Nah'),
          const Amenity(
            osmId: 3,
            position: LatLng(53.0001, 13.0),
            kategorie: 'wc',
            name: 'Kein Parkplatz',
          ),
        ],
      ),
    );
    expect(dest, isNotNull);
    expect(dest!.isParking, isTrue);
    expect(dest.position, const LatLng(53.001, 13.0));
    expect(dest.label, 'Nah');
  });

  test('Parkplatz ohne Namen fällt auf startName zurück', () {
    final dest = navigationDestinationFor(
      _trail(
        startName: 'Eingang Nord',
        amenities: [_parking(1, const LatLng(53.001, 13.0))],
      ),
    );
    expect(dest!.isParking, isTrue);
    expect(dest.label, 'Eingang Nord');
  });

  test('copyAddressLabel: startName und Region', () {
    expect(
      copyAddressLabel(_trail()),
      'Parkplatz Start, Ostprignitz-Ruppin',
    );
    expect(
      copyAddressLabel(_trail(startName: '', region: 'Berlin')),
      'Berlin',
    );
    expect(copyAddressLabel(_trail(startName: '  ', region: '  ')), '');
  });

  test('Google-Maps-URL ohne origin, driving', () {
    final uri = directionsUri(
      MapProvider.googleMaps,
      const LatLng(52.52, 13.405),
    );
    expect(uri.host, 'www.google.com');
    expect(uri.path, '/maps/dir/');
    expect(uri.queryParameters['api'], '1');
    expect(uri.queryParameters['destination'], '52.52,13.405');
    expect(uri.queryParameters['travelmode'], 'driving');
    expect(uri.queryParameters.containsKey('origin'), isFalse);
  });

  test('Apple-Karten-URL mit daddr', () {
    final uri = directionsUri(
      MapProvider.appleMaps,
      const LatLng(52.52, 13.405),
    );
    expect(uri.host, 'maps.apple.com');
    expect(uri.queryParameters['daddr'], '52.52,13.405');
    expect(uri.queryParameters['dirflg'], 'd');
  });

  test('OSM-Directions-URL mit leerem Start', () {
    final uri = directionsUri(
      MapProvider.openStreetMap,
      const LatLng(52.52, 13.405),
    );
    expect(uri.host, 'www.openstreetmap.org');
    expect(uri.path, '/directions');
    expect(uri.queryParameters['engine'], 'fossgis_osrm_car');
    expect(uri.queryParameters['route'], ';52.52,13.405');
  });

  test('formatLatLng: 5 Nachkommastellen', () {
    expect(formatLatLng(const LatLng(53.1, 13.0)), '53.10000, 13.00000');
  });
}
