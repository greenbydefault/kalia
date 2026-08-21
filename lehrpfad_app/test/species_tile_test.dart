import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/features/species/data/hybrid_sightings_repository.dart';
import 'package:lehrpfad_app/features/species/data/local_sightings_store.dart';
import 'package:lehrpfad_app/features/species/data/species_providers.dart';
import 'package:lehrpfad_app/features/species/domain/species.dart';
import 'package:lehrpfad_app/features/species/domain/species_content.dart';
import 'package:lehrpfad_app/features/species/presentation/species_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryStore implements SightingsStore {
  Set<String> ids = {};

  @override
  Future<Set<String>> read() async => {...ids};

  @override
  Future<void> write(Set<String> next) async {
    ids = {...next};
  }
}

const _biber = Species(
  id: 'biber',
  nameDe: 'Biber',
  nameLat: 'Castor fiber',
  kategorie: 'fauna',
  kurztext: 'Nager am Wasser',
  content: SpeciesContent(
    hook: 'Hier formt jemand den Fluss um.',
    erkennung: ['Breiter Schwanz'],
  ),
);

const _wiedehopf = Species(
  id: 'wiedehopf',
  nameDe: 'Wiedehopf',
  nameLat: 'Upupa epops',
  kategorie: 'fauna',
  kurztext: 'Mit Haube.',
  content: SpeciesContent(hook: 'Die Federhaube steht zu Berge.'),
  audioPath: 'assets/audio/species/wiedehopf.mp3',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpTile(
    WidgetTester tester, {
    required Species species,
    required HybridSightingsRepository repo,
    VoidCallback? onTap,
  }) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          sightingsRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 156,
              child: Consumer(
                builder: (context, ref, _) {
                  final seen = ref
                          .watch(sightingsProvider)
                          .asData
                          ?.value
                          .contains(species.id) ??
                      false;
                  return SpeciesTile(
                    species: species,
                    seen: seen,
                    onTap: onTap ?? () {},
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('Peek-Karte zeigt Name und Hook', (tester) async {
    final repo = HybridSightingsRepository(local: _MemoryStore());
    await pumpTile(tester, species: _biber, repo: repo);
    await tester.pumpAndSettle();

    expect(find.text('Biber'), findsOneWidget);
    expect(find.text('Hier formt jemand den Fluss um.'), findsOneWidget);
  });

  testWidgets('Auge toggelt Seen ohne Karten-Tap', (tester) async {
    final store = _MemoryStore();
    final repo = HybridSightingsRepository(local: store);
    var cardTaps = 0;

    await pumpTile(
      tester,
      species: _biber,
      repo: repo,
      onTap: () => cardTaps++,
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Als gesehen markieren'), findsOneWidget);
    await tester.tap(find.byTooltip('Als gesehen markieren'));
    await tester.pumpAndSettle();

    expect(cardTaps, 0);
    expect(await store.read(), {'biber'});
    expect(find.byTooltip('Gesehen, Markierung aufheben'), findsOneWidget);
  });

  testWidgets('Play fehlt ohne audioPath, ist da mit audioPath', (tester) async {
    final repo = HybridSightingsRepository(local: _MemoryStore());

    await pumpTile(tester, species: _biber, repo: repo);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Stimme anhören'), findsNothing);

    await pumpTile(tester, species: _wiedehopf, repo: repo);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Stimme anhören'), findsOneWidget);
  });

  testWidgets('Play-Tap öffnet die Karte nicht', (tester) async {
    final repo = HybridSightingsRepository(local: _MemoryStore());
    var cardTaps = 0;

    await pumpTile(
      tester,
      species: _wiedehopf,
      repo: repo,
      onTap: () => cardTaps++,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Stimme anhören'));
    await tester.pump();

    expect(cardTaps, 0);
  });

  testWidgets('Karten-Tap feuert onTap', (tester) async {
    final repo = HybridSightingsRepository(local: _MemoryStore());
    var cardTaps = 0;

    await pumpTile(
      tester,
      species: _biber,
      repo: repo,
      onTap: () => cardTaps++,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Biber'));
    await tester.pump();

    expect(cardTaps, 1);
  });
}
