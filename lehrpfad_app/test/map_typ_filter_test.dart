import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:lehrpfad_app/features/trail/domain/trail.dart';
import 'package:lehrpfad_app/features/trail/presentation/map/map_typ_filter.dart';

void main() {
  Trail trail({required String id, required String typ}) {
    return Trail(
      id: id,
      name: id,
      typ: typ,
      kurzbeschreibung: 'k',
      beschreibung: 'b',
      laengeKm: 1,
      dauerMin: 30,
      rundkurs: false,
      markierung: 'm',
      betreiber: 'b',
      region: 'r',
      anreise: 'a',
      startName: 's',
      arten: const [],
      route: const [LatLng(52, 13), LatLng(52.01, 13.01)],
      stationen: const [],
      amenities: const [],
    );
  }

  final waldA = trail(id: 'wald-a', typ: 'wald');
  final waldB = trail(id: 'wald-b', typ: 'wald');
  final moor = trail(id: 'moor-a', typ: 'moor');
  final spiel = trail(id: 'spiel', typ: 'wasserspielplatz');
  final hof = trail(id: 'hof', typ: 'kinderbauernhof');
  final unbekannt = trail(id: 'x', typ: 'unbekannter-typ');

  test('typsIn: Katalog-Reihenfolge, nur vorhandene Keys', () {
    expect(typsIn([spiel, waldA, moor, waldB]), [
      'wald',
      'moor',
      'wasserspielplatz',
    ]);
  });

  test('typsIn: kinderbauernhof in Katalog-Reihenfolge', () {
    expect(typsIn([hof, waldA, spiel]), [
      'wald',
      'wasserspielplatz',
      'kinderbauernhof',
    ]);
  });

  test('typsIn: unbekannte Keys hinten, Duplikate kollabiert', () {
    expect(typsIn([unbekannt, waldA, unbekannt, moor]), [
      'wald',
      'moor',
      'unbekannter-typ',
    ]);
  });

  test('filterTrailsByTyp: null = alle, inkl. null-Liste', () {
    final trails = [waldA, moor, spiel];
    expect(filterTrailsByTyp(trails, null), trails);
    expect(filterTrailsByTyp(null, 'wald'), isNull);
    expect(filterTrailsByTyp(null, null), isNull);
  });

  test('filterTrailsByTyp: nur Matching-Typ', () {
    expect(filterTrailsByTyp([waldA, moor, waldB, spiel], 'wald'), [
      waldA,
      waldB,
    ]);
    expect(filterTrailsByTyp([waldA, moor], 'wasserspielplatz'), isEmpty);
  });
}
