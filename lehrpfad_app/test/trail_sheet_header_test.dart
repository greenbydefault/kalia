import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:lehrpfad_app/features/trail/domain/trail.dart';
import 'package:lehrpfad_app/features/trail/presentation/detail/trail_sheet_header.dart';

Trail _trail({required bool eintritt}) {
  return Trail(
    id: 't',
    name: 'Test-Hof',
    typ: 'kinderbauernhof',
    form: 'flaeche',
    kurzbeschreibung: 'k',
    beschreibung: 'b',
    laengeKm: 0,
    dauerMin: 60,
    rundkurs: false,
    markierung: 'm',
    betreiber: 'b',
    region: 'r',
    eintritt: eintritt,
    anreise: 'a',
    startName: 's',
    arten: const [],
    area: const [
      LatLng(52.56, 13.38),
      LatLng(52.56, 13.39),
      LatLng(52.57, 13.39),
    ],
    stationen: const [],
    amenities: const [],
  );
}

void main() {
  testWidgets('Eintritt-Chip nur wenn eintritt true', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrailSheetHeader(trail: _trail(eintritt: false), onClose: () {}),
        ),
      ),
    );
    expect(find.text('Eintritt'), findsNothing);
    expect(find.text('Kinderbauernhof'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrailSheetHeader(trail: _trail(eintritt: true), onClose: () {}),
        ),
      ),
    );
    expect(find.text('Eintritt'), findsOneWidget);
  });
}
