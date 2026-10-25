import 'dart:async';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/admin_repository.dart';
import '../core/field_spec.dart';
import 'import_models.dart';

/// Spalten ohne die großen JSON-Felder: reicht für die Liste.
const _listColumns =
    'id,batch_id,trail_id,file_name,file_hash,status,modus,attempts,report,'
    'error,kosten_usd,created_at,updated_at,template_version';

String sha256Hex(Uint8List bytes) => sha256.convert(bytes).toString();

/// Ergebnis der Vorabprüfung in der Dropzone.
class PrecheckResult {
  const PrecheckResult({
    required this.name,
    required this.hash,
    required this.status,
    this.jobId,
    this.trailId,
  });

  final String name;
  final String hash;

  /// `neu` | `bereits_importiert` | `update`
  final String status;
  final String? jobId;
  final String? trailId;

  factory PrecheckResult.fromJson(Map<String, dynamic> j) => PrecheckResult(
    name: j['name'] as String? ?? '',
    hash: j['hash'] as String? ?? '',
    status: j['status'] as String? ?? 'neu',
    jobId: j['job_id'] as String?,
    trailId: j['trail_id'] as String?,
  );
}

/// Alle Datenbankzugriffe des Import-Bereichs (RPCs aus Migration 0035/0036).
class ImportRepository {
  ImportRepository(this._c);

  final SupabaseClient _c;

  // -- Lesen --------------------------------------------------------------
  Future<List<ImportJob>> listJobs() async {
    final rows = await _c
        .from('import_jobs')
        .select(_listColumns)
        .order('created_at', ascending: false)
        .limit(2000);
    return [for (final r in rows) ImportJob.fromRow(Map.from(r))];
  }

  Future<ImportJob?> getJob(String id) async {
    final r = await _c.from('import_jobs').select().eq('id', id).maybeSingle();
    return r == null ? null : ImportJob.fromRow(Map.from(r));
  }

  /// Jobs, die im Review nacheinander abgearbeitet werden (Reihenfolge der Anlage).
  Future<List<String>> reviewQueue() async {
    final rows = await _c
        .from('import_jobs')
        .select('id')
        .inFilter('status', ['bereit', 'wartet_auf_klaerung'])
        .order('created_at');
    return [for (final r in rows) r['id'] as String];
  }

  Future<List<DbRow>> events(String trailId) async {
    final rows = await _c
        .from('import_events')
        .select()
        .eq('trail_id', trailId)
        .order('created_at', ascending: false)
        .limit(200);
    return [for (final r in rows) Map<String, dynamic>.from(r)];
  }

  Future<List<DbRow>> questions(String trailId) async {
    final rows = await _c
        .from('import_questions')
        .select()
        .eq('trail_id', trailId)
        .order('created_at');
    return [for (final r in rows) Map<String, dynamic>.from(r)];
  }

  Future<List<DbRow>> speciesSuggestions(String trailId) async {
    final rows = await _c
        .from('species_suggestions')
        .select()
        .eq('trail_id', trailId)
        .eq('status', 'offen')
        .order('id');
    return [for (final r in rows) Map<String, dynamic>.from(r)];
  }

  Future<List<DbRow>> sources(String trailId) async {
    final rows = await _c
        .from('trail_sources')
        .select()
        .eq('trail_id', trailId)
        .order('abschnitt');
    return [for (final r in rows) Map<String, dynamic>.from(r)];
  }

  Future<List<DbRow>> officialImages(String trailId) async {
    final rows = await _c
        .from('images')
        .select()
        .eq('trail_id', trailId)
        .eq('source', 'official')
        .order('sort');
    return [for (final r in rows) Map<String, dynamic>.from(r)];
  }

  Future<List<DbRow>> stations(String trailId) async {
    final rows = await _c
        .from('stations')
        .select('id,reihenfolge,titel,lat,lon,km')
        .eq('trail_id', trailId)
        .order('reihenfolge');
    return [for (final r in rows) Map<String, dynamic>.from(r)];
  }

  Future<DbRow?> trailRow(String id) async {
    final r = await _c.from('trails').select().eq('id', id).maybeSingle();
    return r == null ? null : Map<String, dynamic>.from(r);
  }

  Future<List<DbRow>> searchSpecies(String q) async {
    final t = q.trim();
    if (t.isEmpty) return const [];
    final like = '%${t.replaceAll('%', '')}%';
    final rows = await _c
        .from('species')
        .select('id,name_de,name_lat,kategorie')
        .or('name_de.ilike.$like,name_lat.ilike.$like')
        .order('name_de')
        .limit(20);
    return [for (final r in rows) Map<String, dynamic>.from(r)];
  }

  // -- Schreiben ---------------------------------------------------------------
  Future<DbRow> updateTrail(String id, Map<String, dynamic> patch) async {
    await _c.from('trails').update(patch).eq('id', id);
    return patch;
  }

  Future<void> updateStationText(String trailId, int reihenfolge, String text) =>
      _c
          .from('stations')
          .update({'kurztext': text})
          .eq('trail_id', trailId)
          .eq('reihenfolge', reihenfolge);

  Future<void> addStation(String trailId, DbRow row) =>
      _c.from('stations').insert({...row, 'trail_id': trailId});

  Future<void> attachSpecies(
    String trailId,
    String speciesId, {
    String nachweis = 'typisch',
    int? sortierung,
  }) async {
    final n =
        sortierung ??
        (await _c.from('trail_species').count().eq('trail_id', trailId)) + 1;
    await _c.from('trail_species').upsert({
      'trail_id': trailId,
      'species_id': speciesId,
      'nachweis': nachweis,
      'sortierung': n,
    });
    final ids = await _c
        .from('trail_species')
        .select('species_id')
        .eq('trail_id', trailId);
    await _c
        .from('trails')
        .update({
          'arten': [for (final r in ids) r['species_id']],
        })
        .eq('id', trailId);
  }

  Future<void> createSpecies({
    required String id,
    required String nameDe,
    String? nameLat,
    required String kategorie,
  }) => _c.from('species').insert({
    'id': id,
    'name_de': nameDe,
    if ((nameLat ?? '').isNotEmpty) 'name_lat': nameLat,
    'kategorie': kategorie,
    'content': {'tiefe': 'kurz'},
  });

  Future<void> setSuggestion(int id, String status, {String? speciesId}) => _c
      .from('species_suggestions')
      .update({'status': status, 'species_id': ?speciesId})
      .eq('id', id);

  // -- RPCs ----------------------------------------------------------------------
  Future<dynamic> _rpc(String fn, Map<String, dynamic> args) =>
      _c.rpc(fn, params: args);

  Future<Map<String, dynamic>> publish(String job) async =>
      Map<String, dynamic>.from(await _rpc('import_publish', {'p_job': job}));

  Future<void> unpublish(String job) => _rpc('import_unpublish', {'p_job': job});

  Future<void> discard(String job, String grund) =>
      _rpc('import_discard', {'p_job': job, 'p_grund': grund});

  Future<void> override(String job, ReportEntry e, String grund) =>
      _rpc('import_override', {
        'p_job': job,
        'p_code': e.code,
        'p_feld': e.feld,
        'p_grund': grund,
      });

  Future<void> ack(String job, ReportEntry e, {String status = 'erledigt'}) =>
      _rpc('import_ack', {
        'p_job': job,
        'p_code': e.code,
        'p_feld': e.feld,
        'p_wert': e.wert == null ? null : '${e.wert}',
        'p_status': status,
      });

  Future<void> retry(String job) => _rpc('import_retry', {'p_job': job});

  Future<void> revalidate(String job) =>
      _rpc('import_revalidate', {'p_job': job});

  Future<void> replaceFile(
    String job,
    String name,
    String hash,
    String path,
  ) => _rpc('import_replace_file', {
    'p_job': job,
    'p_file_name': name,
    'p_file_hash': hash,
    'p_storage_path': path,
  });

  Future<void> applyProposal(String job, List<String>? teile) =>
      _rpc('import_apply_proposal', {'p_job': job, 'p_teile': teile});

  Future<void> rejectProposal(String job) =>
      _rpc('import_reject_proposal', {'p_job': job});

  Future<void> ask(
    String job, {
    String? field,
    required String frage,
    required String adressat,
  }) => _rpc('import_ask', {
    'p_job': job,
    'p_field': field,
    'p_frage': frage,
    'p_adressat': adressat,
  });

  Future<void> setQuestion(int id, String status, {String? antwort}) => _rpc(
    'import_question_set',
    {'p_question': id, 'p_status': status, 'p_antwort': antwort},
  );

  Future<String> createBatch(String name) async =>
      (await _rpc('import_batch_create', {'p_name': name})) as String;

  Future<void> pauseBatch(String id, bool pause) =>
      _rpc('import_pause_batch', {'p_batch': id, 'p_pause': pause});

  Future<Map<String, dynamic>> batchStats(String id) async =>
      Map<String, dynamic>.from(await _rpc('import_batch_stats', {'p_batch': id}));

  Future<List<PrecheckResult>> precheck(
    List<({String name, String hash})> files,
  ) async {
    final res = await _rpc('import_precheck', {
      'p_files': [
        for (final f in files) {'name': f.name, 'hash': f.hash},
      ],
    });
    return [
      for (final r in (res as List)) PrecheckResult.fromJson(Map.from(r)),
    ];
  }

  /// ZIP in den Bucket `imports` (`<hash>.zip`), dann Job anlegen.
  Future<Map<String, dynamic>> upload({
    required String name,
    required Uint8List bytes,
    required String hash,
    String? batch,
    int priority = 0,
  }) async {
    final path = '$hash.zip';
    await _c.storage
        .from('imports')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'application/zip',
            upsert: true,
          ),
        );
    return Map<String, dynamic>.from(
      await _rpc('import_enqueue', {
        'p_file_name': name,
        'p_file_hash': hash,
        'p_storage_path': path,
        'p_batch': batch,
        'p_priority': priority,
      }),
    );
  }

  Future<void> replaceUpload(
    String job, {
    required String name,
    required Uint8List bytes,
  }) async {
    final hash = sha256Hex(bytes);
    final path = '$hash.zip';
    await _c.storage
        .from('imports')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'application/zip',
            upsert: true,
          ),
        );
    await replaceFile(job, name, hash, path);
  }

  // -- Realtime ---------------------------------------------------------------------
  /// Meldet jede Änderung an `import_jobs` (Insert/Update). Aufrufer räumt mit `unsubscribe` auf.
  RealtimeChannel subscribe(void Function() onChange) {
    final ch = _c.channel('import-jobs-${DateTime.now().microsecondsSinceEpoch}');
    ch
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'import_jobs',
          callback: (_) => onChange(),
        )
        .subscribe();
    return ch;
  }

  Future<void> unsubscribe(RealtimeChannel ch) => _c.removeChannel(ch);
}

final importRepositoryProvider = Provider<ImportRepository>(
  (ref) => ImportRepository(ref.watch(adminClientProvider)),
);

final importMessagesProvider = FutureProvider<ImportMessages>((ref) async {
  return ImportMessages.parse(
    await rootBundle.loadString('import_worker/messages.json'),
  );
});

final importJobsProvider = FutureProvider<List<ImportJob>>(
  (ref) => ref.watch(importRepositoryProvider).listJobs(),
);

final importJobProvider = FutureProvider.family<ImportJob?, String>(
  (ref, id) => ref.watch(importRepositoryProvider).getJob(id),
);

final importQueueProvider = FutureProvider<List<String>>(
  (ref) => ref.watch(importRepositoryProvider).reviewQueue(),
);

/// Anzahl der Jobs, die auf einen Menschen warten (Badge in der Sidebar).
final importOpenCountProvider = Provider<int>((ref) {
  final jobs = ref.watch(importJobsProvider).value ?? const [];
  return jobs
      .where(
        (j) =>
            j.status == ImportStatus.bereit ||
            j.status == ImportStatus.vorschlag ||
            j.status == ImportStatus.wartetAufKlaerung ||
            j.status == ImportStatus.fehlgeschlagen,
      )
      .length;
});

/// Hält die Realtime-Verbindung offen und lädt Listen nach Änderungen neu (entprellt).
final importRealtimeProvider = Provider<void>((ref) {
  final repo = ref.watch(importRepositoryProvider);
  Timer? timer;
  final ch = repo.subscribe(() {
    timer?.cancel();
    timer = Timer(const Duration(milliseconds: 400), () {
      ref.invalidate(importJobsProvider);
      ref.invalidate(importQueueProvider);
      ref.invalidate(importJobProvider);
    });
  });
  ref.onDispose(() {
    timer?.cancel();
    repo.unsubscribe(ch);
  });
});
