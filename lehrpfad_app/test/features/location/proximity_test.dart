import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:lehrpfad_app/features/location/map_radius.dart';
import 'package:lehrpfad_app/features/location/proximity.dart';
import 'package:lehrpfad_app/features/trail/domain/trail.dart';
import 'package:lehrpfad_app/features/trail_progress/tracking/location_service.dart';

Trail _linie() {
  return Trail(
    id: 'linie',
    name: 'Linie',
    typ: 'wald',
    kurzbeschreibung: '',
    beschreibung: '',
    laengeKm: 1,
    dauerMin: 30,
    rundkurs: false,
    markierung: '',
    betreiber: '',
    region: '',
    anreise: '',
    startName: '',
    arten: const [],
    route: const [LatLng(53.0, 13.0), LatLng(53.01, 13.0)],
    stationen: const [],
    amenities: const [],
  );
}

Trail _flaeche() {
  return Trail(
    id: 'flaeche',
    name: 'Platz',
    typ: 'waldspielplatz',
    form: 'flaeche',
    kurzbeschreibung: '',
    beschreibung: '',
    laengeKm: 0,
    dauerMin: 30,
    rundkurs: false,
    markierung: '',
    betreiber: '',
    region: '',
    anreise: '',
    startName: '',
    arten: const [],
    area: const [
      LatLng(53.0, 13.0),
      LatLng(53.0, 13.01),
      LatLng(53.01, 13.01),
      LatLng(53.01, 13.0),
    ],
    stationen: const [],
    amenities: const [],
  );
}

void main() {
  test('Linie: Distanz zur Polyline, nicht nur Start', () {
    final trail = _linie();
    final mid = const LatLng(53.005, 13.0);
    expect(distanceToTrailM(trail, mid), lessThan(5));
    final far = const LatLng(53.005, 13.05);
    expect(distanceToTrailM(trail, far)!, greaterThan(1000));
  });

  test('Fläche: 0 im Polygon, Kante außerhalb', () {
    final trail = _flaeche();
    expect(distanceToTrailM(trail, const LatLng(53.005, 13.005)), 0);
    final outside = distanceToTrailM(trail, const LatLng(53.005, 13.02));
    expect(outside, greaterThan(100));
    expect(outside, lessThan(2000));
  });

  test('Vor Ort: Linie 250 m, Fläche 150 m', () {
    final linie = _linie();
    final flaeche = _flaeche();
    final now = DateTime.now();
    expect(
      onSiteResult(
        linie,
        LocationFix(position: const LatLng(53.005, 13.001), at: now),
      ),
      OnSiteResult.yes,
    );
    expect(
      onSiteResult(
        linie,
        LocationFix(position: const LatLng(54.0, 13.0), at: now),
      ),
      OnSiteResult.no,
    );
    expect(
      onSiteResult(
        flaeche,
        LocationFix(position: const LatLng(53.005, 13.005), at: now),
      ),
      OnSiteResult.yes,
    );
    expect(
      onSiteResult(
        flaeche,
        LocationFix(
          position: const LatLng(53.005, 13.005),
          at: now,
          accuracyM: 250,
        ),
      ),
      OnSiteResult.inaccurate,
    );
    expect(onSiteResult(linie, null), OnSiteResult.unknown);
  });

  test('assertOnSite wirft tooFar mit Distanz', () {
    expect(
      () => assertOnSite(
        _linie(),
        LocationFix(position: const LatLng(54.0, 13.0), at: DateTime.now()),
      ),
      throwsA(
        isA<LocationException>().having(
          (e) => e.kind,
          'kind',
          LocationFailure.tooFar,
        ),
      ),
    );
  });

  test('Umkreis-Filter: Kanten-Distanz, skip ohne Geometrie', () {
    final near = _linie();
    final far = Trail(
      id: 'far',
      name: 'Far',
      typ: 'wald',
      kurzbeschreibung: '',
      beschreibung: '',
      laengeKm: 1,
      dauerMin: 30,
      rundkurs: false,
      markierung: '',
      betreiber: '',
      region: '',
      anreise: '',
      startName: '',
      arten: const [],
      route: const [LatLng(54.5, 13.0), LatLng(54.51, 13.0)],
      stationen: const [],
      amenities: const [],
    );
    final broken = Trail(
      id: 'broken',
      name: 'Broken',
      typ: 'wald',
      kurzbeschreibung: '',
      beschreibung: '',
      laengeKm: 0,
      dauerMin: 0,
      rundkurs: false,
      markierung: '',
      betreiber: '',
      region: '',
      anreise: '',
      startName: '',
      arten: const [],
      stationen: const [],
      amenities: const [],
    );
    final user = const LatLng(53.0, 13.0);
    final filtered = filterTrailsByRadius(
      [near, far, broken],
      radius: MapRadius.km20,
      user: user,
    );
    expect(filtered.map((t) => t.id), ['linie']);
    expect(
      filterTrailsByRadius([near, far], radius: MapRadius.all, user: user),
      [near, far],
    );
  });

  test('formatDistanceM', () {
    expect(formatDistanceM(120), '120 m');
    expect(formatDistanceM(1500), '1.5 km');
    expect(formatDistanceM(20000), '20 km');
  });

  test('pointInPolygon Kante zählt als innen', () {
    final poly = [
      const LatLng(0, 0),
      const LatLng(0, 1),
      const LatLng(1, 1),
      const LatLng(1, 0),
    ];
    expect(pointInPolygon(const LatLng(0, 0.5), poly), isTrue);
    expect(pointInPolygon(const LatLng(0.5, 0.5), poly), isTrue);
    expect(pointInPolygon(const LatLng(2, 2), poly), isFalse);
  });
}
