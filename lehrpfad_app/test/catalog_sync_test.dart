import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/features/offline/catalog/catalog_sync.dart';
import 'package:lehrpfad_app/features/offline/storage/offline_database.dart';

class _FakeRemote implements CatalogRemote {
  bool speciesFails = true;
  int trailCalls = 0;

  @override
  Future<CatalogVersions> versions() async => const CatalogVersions(
    trails: {'neu': 1},
    closed: {'neu': false},
    species: {'eiche': 2},
  );

  @override
  Future<List<Map<String, dynamic>>> trailRows(List<String> ids) async {
    trailCalls++;
    return [
      for (final id in ids) {'id': id, 'data_version': 1, 'name': id},
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> speciesRows(List<String> ids) async {
    if (speciesFails) throw Exception('PGRST201');
    return [
      for (final id in ids)
        {'id': id, 'version': 2, 'name_de': 'Eiche', 'kategorie': 'flora'},
    ];
  }
}

void main() {
  late OfflineDatabase db;
  late _FakeRemote remote;
  late CatalogSync sync;

  setUp(() {
    db = OfflineDatabase(NativeDatabase.memory());
    remote = _FakeRemote();
    sync = CatalogSync(remote, db, now: () => DateTime.utc(2026, 11, 19));
  });

  tearDown(() => db.close());

  test('Arten-Fehler hält neue Trails nicht zurück', () async {
    final report = await sync.run();

    expect(report.trailsFetched, 1);
    expect(report.speciesError, contains('PGRST201'));
    expect(await db.trailVersions(), {'neu': 1});
    expect(await db.speciesVersions(), isEmpty);
    expect(await db.meta(OfflineDatabase.metaLastSyncAt), isNull);
    expect(
      await db.meta(OfflineDatabase.metaLastSyncError),
      contains('PGRST201'),
    );
  });

  test('zweiter Lauf holt nur die Arten nach', () async {
    await sync.run();
    remote.speciesFails = false;

    final report = await sync.run();

    expect(remote.trailCalls, 1);
    expect(report.trailsFetched, 0);
    expect(report.speciesFetched, 1);
    expect(report.speciesError, isNull);
    expect(await db.speciesVersions(), {'eiche': 2});
    expect(await db.meta(OfflineDatabase.metaLastSyncAt), isNotNull);
    expect(await db.meta(OfflineDatabase.metaLastSyncError), '');
  });
}
