import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/features/species/data/hybrid_sightings_repository.dart';
import 'package:lehrpfad_app/features/species/data/local_sightings_store.dart';
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
  test('setSeen toggles local ids and persists', () async {
    final store = _MemoryStore();
    final repo = HybridSightingsRepository(local: store);
    await repo.setSeen('biber', true);
    await repo.setSeen('eisvogel', true);
    await repo.setSeen('biber', false);
    expect(await repo.getSeenIds(), {'eisvogel'});
  });

  test('mergeWithRemote unions local and remote', () async {
    final store = _MemoryStore();
    await store.write({'local-only', 'shared'});
    final repo = HybridSightingsRepository(local: store);
    final merged = await repo.mergeWithRemote({'shared', 'remote-only'});
    expect(merged, {'local-only', 'shared', 'remote-only'});
    expect(await store.read(), merged);
  });

  test('applySeenChange writes notifier set without re-read race', () async {
    final store = _MemoryStore();
    await store.write({'stale'});
    final repo = HybridSightingsRepository(local: store);
    await repo.applySeenChange(
      ids: {'a', 'b'},
      speciesId: 'b',
      seen: true,
    );
    expect(await repo.getSeenIds(), {'a', 'b'});
  });

  test('persistSeenIds last-wins on sequential writes', () async {
    final store = _MemoryStore();
    final repo = HybridSightingsRepository(local: store);
    await repo.persistSeenIds({'one'});
    await repo.persistSeenIds({'one', 'two'});
    expect(await repo.getSeenIds(), {'one', 'two'});
  });

  test('LocalSightingsStore roundtrips via SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({});
    final store = LocalSightingsStore();
    await store.write({'biber', 'eisvogel'});
    expect(await store.read(), {'biber', 'eisvogel'});
  });
}
