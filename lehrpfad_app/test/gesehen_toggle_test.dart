import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/features/species/data/hybrid_sightings_repository.dart';
import 'package:lehrpfad_app/features/species/data/local_sightings_store.dart';
import 'package:lehrpfad_app/features/species/data/species_providers.dart';
import 'package:lehrpfad_app/features/species/domain/species.dart';
import 'package:lehrpfad_app/features/species/domain/species_content.dart';
import 'package:lehrpfad_app/features/species/presentation/gesehen_toggle.dart';
import 'package:lehrpfad_app/features/species/presentation/species_detail_sheet.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('GesehenToggle toggles label and persists via provider',
      (tester) async {
    final store = _MemoryStore();
    final repo = HybridSightingsRepository(local: store);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sightingsRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              final seen = ref
                      .watch(sightingsProvider)
                      .asData
                      ?.value
                      .contains('biber') ??
                  false;
              return Scaffold(
                body: GesehenToggle(
                  seen: seen,
                  onChanged: (v) =>
                      ref.read(sightingsProvider.notifier).setSeen('biber', v),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Hab gesehen'), findsOneWidget);

    await tester.tap(find.text('Hab gesehen'));
    await tester.pumpAndSettle();

    expect(find.text('Gesehen'), findsOneWidget);
    expect(await store.read(), {'biber'});
  });

  testWidgets('SpeciesDetailSheet places Hab gesehen above content',
      (tester) async {
    final store = _MemoryStore();
    final repo = HybridSightingsRepository(local: store);
    const species = Species(
      id: 'biber',
      nameDe: 'Biber',
      nameLat: 'Castor fiber',
      kategorie: 'fauna',
      kurztext: 'Nager am Wasser',
      content: SpeciesContent(
        hook: 'Baut Dämme.',
        erkennung: ['Breiter Schwanz'],
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sightingsRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SpeciesDetailSheet(species: species),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final toggleY = tester.getTopLeft(find.text('Hab gesehen')).dy;
    final sectionY =
        tester.getTopLeft(find.text('Woran erkenne ich’s?')).dy;
    expect(toggleY, lessThan(sectionY));
  });
}
