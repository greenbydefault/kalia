import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../species/data/supabase_species_repository.dart';
import '../../trail/data/supabase_trail_repository.dart';
import '../models/trail_index_entry.dart';
import '../offline_config.dart';
import '../storage/offline_database.dart';

/// Ergebnis des Versionsvergleichs.
typedef VersionDiff = ({Set<String> fetch, Set<String> tombstone});

/// Vergleicht lokale mit entfernten Versionen (id → Version).
///
/// - `fetch`: remote neu oder Version höher
/// - `tombstone`: lokal vorhanden, remote nicht mehr sichtbar
///   (`sichtbar=false` oder gelöscht)
VersionDiff diffVersions(Map<String, int> local, Map<String, int> remote) {
  final fetch = <String>{};
  for (final e in remote.entries) {
    final have = local[e.key];
    if (have == null || e.value > have) fetch.add(e.key);
  }
  final tombstone = {
    for (final id in local.keys)
      if (!remote.containsKey(id)) id,
  };
  return (fetch: fetch, tombstone: tombstone);
}

/// Antwort von `get_catalog_versions()`.
class CatalogVersions {
  const CatalogVersions({
    required this.trails,
    required this.closed,
    required this.species,
  });

  final Map<String, int> trails;
  final Map<String, bool> closed;
  final Map<String, int> species;

  factory CatalogVersions.fromJson(Map<String, dynamic> json) {
    final trails = (json['trails'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    final species = (json['species'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    return CatalogVersions(
      trails: {
        for (final t in trails)
          t['id'] as String: (t['data_version'] as num).toInt(),
      },
      closed: {for (final t in trails) t['id'] as String: t['closed'] == true},
      species: {
        for (final s in species)
          s['id'] as String: (s['version'] as num).toInt(),
      },
    );
  }
}

/// Netzzugriff des Syncs, austauschbar für Tests.
abstract interface class CatalogRemote {
  Future<CatalogVersions> versions();
  Future<List<Map<String, dynamic>>> trailRows(List<String> ids);
  Future<List<Map<String, dynamic>>> speciesRows(List<String> ids);
}

class SupabaseCatalogRemote implements CatalogRemote {
  SupabaseCatalogRemote(this._client);

  final SupabaseClient _client;

  @override
  Future<CatalogVersions> versions() async {
    final res = await _client.rpc('get_catalog_versions');
    return CatalogVersions.fromJson(Map<String, dynamic>.from(res as Map));
  }

  @override
  Future<List<Map<String, dynamic>>> trailRows(List<String> ids) async {
    final rows = await _client
        .from('trails')
        .select(SupabaseTrailRepository.columns)
        .inFilter('id', ids)
        .eq('images.source', 'official')
        .eq('images.status', 'approved')
        .isFilter('images.station_id', null)
        .order('reihenfolge', referencedTable: 'stations', ascending: true)
        .order('sort', referencedTable: 'images', ascending: true);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Future<List<Map<String, dynamic>>> speciesRows(List<String> ids) async {
    final rows = await _client
        .from('species')
        .select(SupabaseSpeciesRepository.columns)
        .inFilter('id', ids);
    return List<Map<String, dynamic>>.from(rows);
  }
}

class SyncReport {
  const SyncReport({
    this.trailsFetched = 0,
    this.speciesFetched = 0,
    this.trailsRemoved = 0,
    this.speciesRemoved = 0,
    this.speciesError,
  });

  final int trailsFetched;
  final int speciesFetched;
  final int trailsRemoved;
  final int speciesRemoved;

  /// Arten-Phase gescheitert, Trails sind trotzdem gespeichert.
  final String? speciesError;

  bool get changed =>
      trailsFetched + speciesFetched + trailsRemoved + speciesRemoved > 0;

  @override
  String toString() =>
      'SyncReport(trails +$trailsFetched -$trailsRemoved, '
      'arten +$speciesFetched -$speciesRemoved'
      '${speciesError == null ? '' : ', arten-fehler: $speciesError'})';
}

/// Version-basierter Katalogabgleich: ein RPC liefert alle Versionen, nur
/// geänderte Pakete werden geladen, Unsichtbares wird lokal gelöscht.
class CatalogSync {
  CatalogSync(this._remote, this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final CatalogRemote _remote;
  final OfflineDatabase _db;
  final DateTime Function() _now;

  Future<SyncReport> run() async {
    final remote = await _remote.versions();
    final trailDiff = diffVersions(await _db.trailVersions(), remote.trails);
    final speciesDiff = diffVersions(
      await _db.speciesVersions(),
      remote.species,
    );

    // Ein leerer Remote-Katalog bei gefülltem lokalem ist eher ein Fehler
    // (falsches Projekt, RLS) als ein Löschen aller Inhalte.
    final trailTombstones = remote.trails.isEmpty
        ? <String>{}
        : trailDiff.tombstone;
    final speciesTombstones = remote.species.isEmpty
        ? <String>{}
        : speciesDiff.tombstone;

    final trails = <TrailIndexEntry>[];
    for (final chunk in _chunks(
      trailDiff.fetch,
      OfflineConfig.trailFetchChunk,
    )) {
      for (final row in await _remote.trailRows(chunk)) {
        final id = row['id'] as String;
        trails.add(
          TrailIndexEntry(
            id: id,
            dataVersion:
                (row['data_version'] as num?)?.toInt() ?? remote.trails[id]!,
            closed: remote.closed[id] ?? false,
            json: SupabaseTrailRepository.trailRowToJson(row),
          ),
        );
      }
    }

    // Trails zuerst und für sich committen: ein kaputter Arten-Request darf
    // neue Pfade nicht zurückhalten. Fehlende Arten überspringt der
    // SpeciesResolver, bis sie nachkommen.
    await _db.transaction(() async {
      await _db.upsertTrails(trails);
      await _db.deleteTrails(trailTombstones);
      await _db.setClosedFlags(remote.closed);
    });

    final species = <SpeciesIndexEntry>[];
    String? speciesError;
    try {
      for (final chunk in _chunks(
        speciesDiff.fetch,
        OfflineConfig.speciesFetchChunk,
      )) {
        for (final row in await _remote.speciesRows(chunk)) {
          final id = row['id'] as String;
          species.add(
            SpeciesIndexEntry(
              id: id,
              version:
                  (row['version'] as num?)?.toInt() ?? remote.species[id]!,
              json: SupabaseSpeciesRepository.rowToJson(row),
            ),
          );
        }
      }
    } catch (e) {
      speciesError = '$e';
      species.clear();
    }

    // Ohne last_sync_at wiederholt der nächste Auslöser die Arten; die
    // Trails sind dann schon aktuell und werden nicht erneut geladen.
    await _db.transaction(() async {
      if (speciesError == null) {
        await _db.upsertSpecies(species);
        await _db.deleteSpecies(speciesTombstones);
        await _db.setMeta(
          OfflineDatabase.metaLastSyncAt,
          _now().toUtc().toIso8601String(),
        );
        await _db.setMeta(OfflineDatabase.metaLastSyncError, '');
      } else {
        await _db.setMeta(
          OfflineDatabase.metaLastSyncError,
          'Arten: $speciesError',
        );
      }
    });

    final report = SyncReport(
      trailsFetched: trails.length,
      speciesFetched: species.length,
      trailsRemoved: trailTombstones.length,
      speciesRemoved: speciesError == null ? speciesTombstones.length : 0,
      speciesError: speciesError,
    );
    debugPrint('CatalogSync $report');
    return report;
  }

  static Iterable<List<String>> _chunks(Set<String> ids, int size) sync* {
    final list = ids.toList()..sort();
    for (var i = 0; i < list.length; i += size) {
      yield list.sublist(i, i + size > list.length ? list.length : i + size);
    }
  }
}
