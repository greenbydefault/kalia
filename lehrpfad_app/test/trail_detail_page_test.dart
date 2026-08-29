import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:lehrpfad_app/features/trail/data/providers.dart';
import 'package:lehrpfad_app/features/trail/domain/trail.dart';
import 'package:lehrpfad_app/features/trail/presentation/detail/trail_detail_page.dart';
import 'package:lehrpfad_app/features/trail/presentation/map/trail_hero_pager.dart';
import 'package:shared_preferences/shared_preferences.dart';

Trail _trail() {
  return Trail(
    id: 't',
    name: 'Test-Hof',
    typ: 'kinderbauernhof',
    form: 'flaeche',
    kurzbeschreibung: 'kurz',
    beschreibung: 'lang',
    laengeKm: 0,
    dauerMin: 60,
    rundkurs: false,
    markierung: 'm',
    betreiber: 'b',
    region: 'r',
    eintritt: false,
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
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Hero fährt mit dem Content mit, statt oben fix zu bleiben', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final trail = _trail();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          trailsProvider.overrideWith((ref) async => [trail]),
        ],
        child: MaterialApp(
          home: TrailDetailPage(trail: trail, onClose: () {}),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(CustomScrollView), findsOneWidget);
    final pager = find.byType(TrailHeroPager, skipOffstage: false);
    expect(pager, findsOneWidget);

    final y0 = tester.getTopLeft(pager).dy;
    expect(y0, closeTo(0, 0.5));

    tester
        .widget<CustomScrollView>(find.byType(CustomScrollView))
        .controller!
        .jumpTo(200);
    await tester.pump();

    final y1 = tester.getTopLeft(pager).dy;
    expect(y1, closeTo(y0 - 200, 0.5));
  });
}
