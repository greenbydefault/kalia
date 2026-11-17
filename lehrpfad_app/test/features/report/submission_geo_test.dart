import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/features/report/data/report_server.dart';
import 'package:lehrpfad_app/features/report/domain/report_enums.dart';

const _draft = '11111111-1111-4111-8111-111111111111';

void main() {
  test('Track: GeoJSON [lng, lat] wird zu TrackPoint(lat, lng)', () {
    final geo = parseSubmissionGeo({
      'track': [
        [
          [10.0, 54.0],
          [10.1, 54.1],
        ],
        [
          [10.2, 54.2],
        ], // zu kurz, fällt weg
      ],
      'points': [],
    }, _draft);
    expect(geo.segments, hasLength(1));
    expect(geo.segments.first.first.lat, 54.0);
    expect(geo.segments.first.first.lng, 10.0);
    expect(geo.segments.first.last.lat, 54.1);
  });

  test('Marker: Typ, Position und Nummer', () {
    final geo = parseSubmissionGeo({
      'track': [],
      'points': [
        {
          'id': 'a',
          'type': 'station',
          'seq': 2,
          'number': 3,
          'title': 'Eiche',
          'lat': 54.3,
          'lng': 10.3,
        },
        {'id': 'b', 'type': 'unbekannt', 'lat': 1.0, 'lng': 2.0},
      ],
    }, _draft);
    expect(geo.points, hasLength(1));
    expect(geo.points.first.type, PointType.station);
    expect(geo.points.first.number, 3);
    expect(geo.points.first.lat, 54.3);
    expect(geo.points.first.draftId, _draft);
  });

  test('Ungültige Antwort ergibt leeres Ergebnis', () {
    final geo = parseSubmissionGeo(null, _draft);
    expect(geo.segments, isEmpty);
    expect(geo.points, isEmpty);
  });
}
