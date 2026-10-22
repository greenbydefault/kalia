import 'dart:convert';

import 'package:drift/drift.dart';

import '../models/trail_index_entry.dart';

part 'offline_database.g.dart';

/// Lokaler Katalog. Inhalt je Zeile als JSON im Seed-Format, dazu die
/// Version für den Abgleich (`get_catalog_versions()`).
@DataClassName('TrailRow')
class TrailIndex extends Table {
  TextColumn get id => text()();
  IntColumn get dataVersion => integer()();
  BoolColumn get closed => boolean().withDefault(const Constant(false))();
  TextColumn get json => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SpeciesRow')
class SpeciesIndex extends Table {
  TextColumn get id => text()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get json => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Schlüssel/Wert: `seed_signature`, `last_sync_at`.
@DataClassName('MetaRow')
class SyncMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [TrailIndex, SpeciesIndex, SyncMeta])
class OfflineDatabase extends _$OfflineDatabase {
  OfflineDatabase(super.e);

  static const metaSeedSignature = 'seed_signature';
  static const metaLastSyncAt = 'last_sync_at';

  @override
  int get schemaVersion => 1;

  // --- Trails ---

  Future<Map<String, int>> trailVersions() async {
    final rows = await select(trailIndex).get();
    return {for (final r in rows) r.id: r.dataVersion};
  }

  Stream<List<Map<String, dynamic>>> watchTrailJsons() {
    final query = select(trailIndex)..orderBy([(t) => OrderingTerm.asc(t.id)]);
    return query.watch().map(
      (rows) => [
        for (final r in rows) jsonDecode(r.json) as Map<String, dynamic>,
      ],
    );
  }

  Future<void> upsertTrails(Iterable<TrailIndexEntry> entries) {
    return batch((b) {
      for (final e in entries) {
        b.insert(
          trailIndex,
          TrailIndexCompanion.insert(
            id: e.id,
            dataVersion: e.dataVersion,
            closed: Value(e.closed),
            json: jsonEncode(e.json),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> deleteTrails(Iterable<String> ids) {
    return (delete(trailIndex)..where((t) => t.id.isIn(ids))).go();
  }

  /// Sperr-Flag aller Trails aus dem Versions-RPC nachziehen.
  Future<void> setClosedFlags(Map<String, bool> closedById) {
    return batch((b) {
      for (final e in closedById.entries) {
        b.update(
          trailIndex,
          TrailIndexCompanion(closed: Value(e.value)),
          where: (t) => t.id.equals(e.key),
        );
      }
    });
  }

  Future<Set<String>> closedTrailIds() async {
    final rows = await (select(
      trailIndex,
    )..where((t) => t.closed.equals(true))).get();
    return {for (final r in rows) r.id};
  }

  // --- Arten ---

  Future<Map<String, int>> speciesVersions() async {
    final rows = await select(speciesIndex).get();
    return {for (final r in rows) r.id: r.version};
  }

  Future<List<Map<String, dynamic>>> speciesJsons() async {
    final rows = await select(speciesIndex).get();
    return [for (final r in rows) jsonDecode(r.json) as Map<String, dynamic>];
  }

  Future<void> upsertSpecies(Iterable<SpeciesIndexEntry> entries) {
    return batch((b) {
      for (final e in entries) {
        b.insert(
          speciesIndex,
          SpeciesIndexCompanion.insert(
            id: e.id,
            version: Value(e.version),
            json: jsonEncode(e.json),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> deleteSpecies(Iterable<String> ids) {
    return (delete(speciesIndex)..where((t) => t.id.isIn(ids))).go();
  }

  // --- Meta ---

  Future<String?> meta(String key) async {
    final row = await (select(
      syncMeta,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> setMeta(String key, String value) {
    return into(
      syncMeta,
    ).insertOnConflictUpdate(SyncMetaCompanion.insert(key: key, value: value));
  }
}
