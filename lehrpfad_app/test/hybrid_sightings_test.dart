import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/features/species/data/hybrid_sightings_repository.dart';
import 'package:lehrpfad_app/features/species/data/local_funde_store.dart';
import 'package:lehrpfad_app/features/species/data/local_sightings_store.dart';
import 'package:lehrpfad_app/features/species/domain/fund.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/memory_funde_store.dart';

void main() {
  final tag1 = DateTime.utc(2026, 11, 1);
  final tag2 = DateTime.utc(2026, 11, 10);

  test('applyChange schreibt den kompletten Stand lokal', () async {
    final store = MemoryFundeStore();
    final repo = HybridSightingsRepository(local: store);
    await repo.applyChange(
      funde: {
        'biber': Fund(speciesId: 'biber', entdecktAm: tag1, trailId: 'a'),
        'eisvogel': Fund(speciesId: 'eisvogel', entdecktAm: tag2),
      },
      speciesId: 'eisvogel',
    );
    await repo.applyChange(
      funde: {'eisvogel': Fund(speciesId: 'eisvogel', entdecktAm: tag2)},
      speciesId: 'biber',
    );
    expect((await repo.getFunde()).keys, {'eisvogel'});
  });

  test('mergeWithRemote: Union, frühestes Datum, lokale Angaben bleiben', () async {
    final store = MemoryFundeStore({
      'local-only': Fund(speciesId: 'local-only', entdecktAm: tag2),
      'shared': Fund(
        speciesId: 'shared',
        entdecktAm: tag2,
        von: EntdecktVon.kind,
      ),
      'alt': const Fund(speciesId: 'alt'),
    });
    final repo = HybridSightingsRepository(local: store);
    final merged = await repo.mergeWithRemote({
      'shared': Fund(speciesId: 'shared', entdecktAm: tag1, trailId: 'x'),
      'remote-only': Fund(speciesId: 'remote-only', entdecktAm: tag1),
      'alt': Fund(speciesId: 'alt', entdecktAm: tag1),
    });
    expect(merged.keys, {'local-only', 'shared', 'remote-only', 'alt'});
    expect(merged['shared']!.entdecktAm, tag1);
    expect(merged['shared']!.trailId, 'x');
    expect(merged['shared']!.von, EntdecktVon.kind);
    expect(merged['alt']!.entdecktAm, tag1);
    expect(store.funde, merged);
  });

  group('LocalFundeStore', () {
    test('Roundtrip über SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final store = LocalFundeStore();
      final fund = Fund(
        speciesId: 'biber',
        entdecktAm: tag1,
        trailId: 'a',
        von: EntdecktVon.gemeinsam,
      );
      await store.write({'biber': fund});
      expect(await LocalFundeStore().read(), {'biber': fund});
    });

    test('Migration: Altbestand (nur IDs) wird Fund ohne Datum', () async {
      SharedPreferences.setMockInitialValues({
        'species_sightings': '["biber","eisvogel"]',
      });
      final funde = await LocalFundeStore().read();
      expect(funde.keys, {'biber', 'eisvogel'});
      expect(funde['biber']!.entdecktAm, isNull);
    });

    test('Leerer Bestand nach Entfernen wird nicht neu migriert', () async {
      SharedPreferences.setMockInitialValues({
        'species_sightings': '["biber"]',
      });
      final store = LocalFundeStore();
      await store.write({});
      expect(await store.read(), isEmpty);
    });
  });

  test('LocalSightingsStore (Legacy) liest weiter', () async {
    SharedPreferences.setMockInitialValues({});
    final store = LocalSightingsStore();
    await store.write({'biber'});
    expect(await store.read(), {'biber'});
  });
}
