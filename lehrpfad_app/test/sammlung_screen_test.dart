import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/features/nearby_trails/data/karte_state.dart';
import 'package:lehrpfad_app/features/species/data/hybrid_sightings_repository.dart';
import 'package:lehrpfad_app/features/species/data/species_providers.dart';
import 'package:lehrpfad_app/features/species/domain/fund.dart';
import 'package:lehrpfad_app/features/species/domain/species.dart';
import 'package:lehrpfad_app/features/species/presentation/sammlung/sammlung_screen.dart';
import 'package:lehrpfad_app/features/trail/data/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/memory_funde_store.dart';

Species _s(String id, String kat, {String gruppe = ''}) => Species(
  id: id,
  nameDe: id,
  nameLat: '',
  kategorie: kat,
  kurztext: '',
  gruppe: gruppe,
);

final _katalog = [
  _s('Amsel', 'fauna', gruppe: 'voegel'),
  _s('Biber', 'fauna', gruppe: 'saeugetiere'),
  _s('Fuchs', 'fauna', gruppe: 'saeugetiere'),
  _s('Buche', 'flora', gruppe: 'baeume'),
  _s('Schild', 'geraete'),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<MemoryFundeStore> pump(
    WidgetTester tester, {
    Map<String, Fund>? funde,
  }) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = MemoryFundeStore(funde);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sightingsRepositoryProvider.overrideWithValue(
            HybridSightingsRepository(local: store),
          ),
          trailsProvider.overrideWithValue(const AsyncData([])),
          bezugCoordsProvider.overrideWithValue(null),
          speciesCatalogProvider.overrideWith((ref) async => _katalog),
        ],
        child: const MaterialApp(home: SammlungScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets('Neue Nutzer: „Noch keine Funde“, Hinweis, alles offen', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Noch keine Funde'), findsOneWidget);
    expect(find.byKey(const ValueKey('sammlung-kopf-hinweis')), findsOneWidget);
    expect(find.text('Eure Funde'), findsNothing);
    expect(find.text('Zuletzt entdeckt'), findsNothing);
    expect(find.text('Noch offen in eurer Nähe'), findsNothing);
    expect(find.text('Noch zu entdecken'), findsOneWidget);
    // Default Fauna, kein Schloss.
    expect(find.byIcon(Icons.lock), findsNothing);
    expect(find.text('Amsel'), findsOneWidget);
    expect(find.text('Buche'), findsNothing);
  });

  testWidgets('Funde: Kopf, Segmentzähler, Zuletzt, Funde vor Offen', (
    tester,
  ) async {
    await pump(
      tester,
      funde: {
        'Amsel': Fund(
          speciesId: 'Amsel',
          entdecktAm: DateTime.now().subtract(const Duration(days: 1)),
        ),
      },
    );

    expect(find.text('1 Fund · +1 diese Woche'), findsOneWidget);
    expect(find.text('Fauna 1'), findsOneWidget);
    expect(find.text('Flora 0'), findsOneWidget);
    expect(find.text('Geräte 0'), findsOneWidget);
    expect(find.text('Zuletzt entdeckt'), findsOneWidget);
    expect(find.text('gestern'), findsOneWidget);

    final funde = tester.getTopLeft(find.text('Eure Funde')).dy;
    final offen = tester.getTopLeft(find.text('Noch zu entdecken')).dy;
    expect(funde, lessThan(offen));
  });

  testWidgets('Gruppen-Chip filtert, blendet Zuletzt aus, Satz ohne Funde', (
    tester,
  ) async {
    await pump(
      tester,
      funde: {
        'Amsel': Fund(speciesId: 'Amsel', entdecktAm: DateTime.now()),
      },
    );

    await tester.tap(find.byKey(const ValueKey('sammlung-chip-saeugetiere')));
    await tester.pumpAndSettle();

    expect(find.text('Zuletzt entdeckt'), findsNothing);
    expect(
      find.text('Aus dieser Gruppe habt ihr noch nichts entdeckt.'),
      findsOneWidget,
    );
    expect(find.text('Biber'), findsOneWidget);
    expect(find.text('Fuchs'), findsOneWidget);
    expect(find.text('Amsel'), findsNothing);
  });

  testWidgets('Kategoriewechsel: Gruppe zurück auf Alle, Geräte ohne Chips', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('sammlung-chip-voegel')));
    await tester.pumpAndSettle();
    expect(find.text('Biber'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('sammlung-segment-flora')));
    await tester.pumpAndSettle();
    expect(find.text('Buche'), findsOneWidget);
    expect(find.byKey(const ValueKey('sammlung-chip-baeume')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('sammlung-segment-fauna')));
    await tester.pumpAndSettle();
    expect(find.text('Biber'), findsOneWidget); // Filter ist wieder „Alle“

    await tester.tap(find.byKey(const ValueKey('sammlung-segment-geraete')));
    await tester.pumpAndSettle();
    expect(find.text('Schild'), findsOneWidget);
    expect(find.byKey(const ValueKey('sammlung-chip-alle')), findsNothing);
  });

  testWidgets('Tap auf offene Kachel öffnet das Sheet, Freischalten wirkt', (
    tester,
  ) async {
    final store = await pump(tester);

    await tester.tap(find.byKey(const ValueKey('sammlung-kachel-Biber')));
    await tester.pumpAndSettle();
    expect(find.text('Noch nicht entdeckt'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('sheet-hab-ich-gesehen')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(store.ids, {'Biber'});

    // Hintergrund aktualisiert sich ohne Neuladen.
    await tester.tap(find.byKey(const ValueKey('sheet-schliessen')));
    await tester.pumpAndSettle();
    expect(find.text('1 Fund · +1 diese Woche'), findsOneWidget);
    expect(find.text('Eure Funde'), findsOneWidget);
    expect(find.text('Fauna 1'), findsOneWidget);
  });
}
