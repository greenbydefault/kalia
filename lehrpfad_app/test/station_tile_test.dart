import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:lehrpfad_app/features/trail/domain/station.dart';
import 'package:lehrpfad_app/features/trail/presentation/detail/widgets/station_tile.dart';

const _station = Station(
  osmId: 1,
  position: LatLng(53.0, 8.01),
  km: 0.5,
  reihenfolge: 2,
  titel: 'Moorsteg',
  thema: 'Torf und Wasser',
  kurztext: 'Langer Text, der auf der Peek-Kachel nicht erscheinen soll.',
  erlebnisse: ['steg'],
  barrierefrei: true,
);

void main() {
  Future<void> pumpTile(
    WidgetTester tester, {
    required Station station,
    VoidCallback? onTap,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 156,
            child: StationTile(
              station: station,
              onTap: onTap ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('Peek-Kachel zeigt Nummer, Titel und Thema', (tester) async {
    await pumpTile(tester, station: _station);

    expect(find.text('2'), findsOneWidget);
    expect(find.text('Moorsteg'), findsOneWidget);
    expect(find.text('Torf und Wasser'), findsOneWidget);
    expect(
      find.text('Langer Text, der auf der Peek-Kachel nicht erscheinen soll.'),
      findsNothing,
    );
    expect(find.byTooltip('Barrierefrei'), findsOneWidget);
  });

  testWidgets('Karten-Tap feuert onTap', (tester) async {
    var taps = 0;
    await pumpTile(tester, station: _station, onTap: () => taps++);

    await tester.tap(find.text('Moorsteg'));
    await tester.pump();

    expect(taps, 1);
  });
}
