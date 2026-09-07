import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:lehrpfad_app/app/theme/app_colors.dart';
import 'package:lehrpfad_app/features/trail/domain/trail.dart';
import 'package:lehrpfad_app/shared/widgets/typ_start_marker.dart';

Trail _trail({required bool eintritt}) {
  return Trail(
    id: 't',
    name: 'Test',
    typ: 'erlebniswald',
    kurzbeschreibung: 'k',
    beschreibung: 'b',
    laengeKm: 0.5,
    dauerMin: 60,
    rundkurs: true,
    markierung: 'm',
    betreiber: 'b',
    region: 'r',
    eintritt: eintritt,
    anreise: 'a',
    startName: 's',
    arten: const [],
    route: const [LatLng(51.08, 10.51), LatLng(51.09, 10.52)],
    stationen: const [],
    amenities: const [],
  );
}

Color? _ringColor(WidgetTester tester) {
  final container = tester.widget<Container>(find.byType(Container).first);
  final box = container.decoration as BoxDecoration;
  return box.border?.top.color;
}

void main() {
  testWidgets('forTrail: Pin-Ring gold nur bei eintritt', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: TypStartMarker.forTrail(_trail(eintritt: false)))),
    );
    expect(_ringColor(tester), AppColors.n50);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: TypStartMarker.forTrail(_trail(eintritt: true)))),
    );
    expect(_ringColor(tester), AppColors.eintrittRing);
  });
}
