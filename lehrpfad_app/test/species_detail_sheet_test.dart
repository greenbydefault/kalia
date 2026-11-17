import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/features/nearby_trails/data/karte_state.dart';
import 'package:lehrpfad_app/features/species/data/hybrid_sightings_repository.dart';
import 'package:lehrpfad_app/features/species/data/species_providers.dart';
import 'package:lehrpfad_app/features/species/domain/fund.dart';
import 'package:lehrpfad_app/features/species/domain/species.dart';
import 'package:lehrpfad_app/features/species/domain/species_content.dart';
import 'package:lehrpfad_app/features/species/presentation/species_detail_sheet.dart';
import 'package:lehrpfad_app/features/trail/data/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/memory_funde_store.dart';

const _biber = Species(
  id: 'biber',
  nameDe: 'Biber',
  nameLat: 'Castor fiber',
  kategorie: 'fauna',
  kurztext: 'Nager am Wasser',
  gruppe: '',
  content: SpeciesContent(
    hook: 'Baut Dämme.',
    erkennung: ['Breiter Schwanz'],
    funFacts: ['Seine Zähne wachsen ein Leben lang.', 'Zweiter Fakt.'],
    hoertext: 'Ein Satz zum Einsprechen, der in der UI nicht stehen darf.',
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<MemoryFundeStore> pumpSheet(
    WidgetTester tester, {
    Map<String, Fund>? start,
  }) async {
    final store = MemoryFundeStore(start);
    final repo = HybridSightingsRepository(local: store);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sightingsRepositoryProvider.overrideWithValue(repo),
          trailsProvider.overrideWithValue(const AsyncData([])),
          bezugCoordsProvider.overrideWithValue(null),
          speciesCatalogProvider.overrideWith((ref) async => [_biber]),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => SpeciesDetailSheet.show(context, _biber),
                  child: const Text('öffnen'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('öffnen'));
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets('Offene Variante: Silhouette, Aktion oben, kein Hörtext', (
    tester,
  ) async {
    await pumpSheet(tester);

    expect(find.text('Noch nicht entdeckt'), findsOneWidget);
    expect(find.text('Wer hat’s entdeckt?'), findsNothing);
    expect(find.textContaining('Doch nicht gesehen?'), findsNothing);
    expect(find.text('Wusstest du?'), findsOneWidget);
    expect(find.text('Seine Zähne wachsen ein Leben lang.'), findsOneWidget);
    // Erster Fakt steht oben, im Steckbrief nur noch der Rest.
    expect(find.text('Zweiter Fakt.'), findsOneWidget);

    final aktionY = tester.getTopLeft(find.text('Hab ich gesehen')).dy;
    final steckbriefY = tester.getTopLeft(find.text('Woran erkenne ich’s?')).dy;
    expect(aktionY, lessThan(steckbriefY));
    expect(
      find.text('Ein Satz zum Einsprechen, der in der UI nicht stehen darf.'),
      findsNothing,
    );
    expect(find.text('Gute Chancen'), findsNothing);
  });

  testWidgets('Freischalten: Sheet bleibt offen und wechselt zu gefunden', (
    tester,
  ) async {
    final store = await pumpSheet(tester);

    await tester.tap(find.byKey(const ValueKey('sheet-hab-ich-gesehen')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(store.ids, {'biber'});
    expect(store.funde['biber']!.entdecktAm, isNotNull);
    expect(find.text('Neu in eurer Sammlung'), findsOneWidget);
    expect(find.text('Noch nicht entdeckt'), findsNothing);
    expect(find.text('Hab ich gesehen'), findsNothing);
    expect(find.text('Wer hat’s entdeckt?'), findsOneWidget);
    expect(find.text('Biber ist jetzt in eurer Sammlung'), findsOneWidget);
    expect(find.text('Entdeckt heute'), findsOneWidget);
  });

  testWidgets('Wer: Einfachauswahl, erneuter Tap hebt auf', (tester) async {
    final store = await pumpSheet(
      tester,
      start: {'biber': Fund(speciesId: 'biber', entdecktAm: DateTime.now())},
    );

    await tester.ensureVisible(find.byKey(const ValueKey('sheet-wer-kind')));
    await tester.tap(find.byKey(const ValueKey('sheet-wer-kind')));
    await tester.pumpAndSettle();
    expect(store.funde['biber']!.von, EntdecktVon.kind);

    await tester.tap(find.byKey(const ValueKey('sheet-wer-gemeinsam')));
    await tester.pumpAndSettle();
    expect(store.funde['biber']!.von, EntdecktVon.gemeinsam);

    await tester.tap(find.byKey(const ValueKey('sheet-wer-gemeinsam')));
    await tester.pumpAndSettle();
    expect(store.funde['biber']!.von, isNull);
  });

  testWidgets('Entfernen: Inline-Bestätigung, Snackbar, Rückgängig', (
    tester,
  ) async {
    final tag = DateTime.utc(2026, 10, 1);
    final fund = Fund(
      speciesId: 'biber',
      entdecktAm: tag,
      trailId: 'a',
      von: EntdecktVon.kind,
    );
    final store = await pumpSheet(tester, start: {'biber': fund});

    final link = find.byKey(const ValueKey('sheet-entfernen-link'));
    await tester.ensureVisible(link);
    await tester.tap(link);
    await tester.pumpAndSettle();
    expect(find.text('Wirklich entfernen?'), findsOneWidget);

    // Behalten schließt nur die Frage.
    await tester.tap(find.byKey(const ValueKey('sheet-entfernen-behalten')));
    await tester.pumpAndSettle();
    expect(find.text('Wirklich entfernen?'), findsNothing);
    expect(store.ids, {'biber'});

    await tester.ensureVisible(link);
    await tester.tap(link);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sheet-entfernen-ja')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(store.ids, isEmpty);
    expect(find.text('Biber entfernt'), findsOneWidget);
    expect(find.text('Noch nicht entdeckt'), findsNothing); // Sheet zu

    await tester.tap(find.text('Rückgängig'));
    await tester.pumpAndSettle();
    expect(store.funde['biber'], fund);
  });
}
