import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_client_provider.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/connectivity/offline_provider.dart';
import '../../auth/data/auth_providers.dart';
import '../domain/report_enums.dart';
import '../domain/report_models.dart';
import '../logic/draft_transitions.dart';
import '../logic/geo.dart';
import '../logic/track_metrics.dart';
import '../report_config.dart';
import 'report_providers.dart';
import 'report_server.dart';

const _bucket = 'submission-photos';

const _intentWire = {
  QuickIntent.movePoint: 'move_point',
  QuickIntent.addPoint: 'add_point',
  QuickIntent.hint: 'hint',
  QuickIntent.other: 'other',
};

const _kindWire = {
  ReportKind.newTrail: 'new_trail',
  ReportKind.revision: 'revision',
  ReportKind.quick: 'quick',
};

String _date(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Baut den Upload (Spec 7.3). Der Track läuft ohne Zeitstempel und gekürzt,
/// gekürzte Teile verlassen das Gerät nie.
Map<String, Object?> buildSubmissionPayload({
  required ReportDraft draft,
  required List<DraftPoint> points,
  required TrackSegments segments,
  required int photoCount,
  String appVersion = '',
  String platform = '',
}) {
  final trimmed = trimTrack(
    segments,
    startM: draft.trimStartM,
    endM: draft.trimEndM,
  );
  final sent = [
    for (final p in points)
      if (!(p.type == PointType.start && draft.trimStartM > 0) &&
          !(p.type == PointType.end && draft.trimEndM > 0))
        p,
  ];
  return {
    'client_submission_id': draft.id,
    'kind': _kindWire[draft.kind],
    if (draft.targetTrailId != null) 'target_trail_id': draft.targetTrailId,
    if (draft.intent != null) 'intent': _intentWire[draft.intent],
    if (draft.kind == ReportKind.newTrail) ...{
      'title': draft.title?.trim(),
      'area': draft.area,
    },
    if (draft.kind != ReportKind.quick) ...{
      'is_loop': draft.isLoop ?? false,
      'stroller': draft.stroller,
    },
    if (draft.note != null && draft.note!.trim().isNotEmpty)
      'note': draft.note!.trim(),
    if (trimmed.isNotEmpty)
      'track': {
        'segments': [
          for (final s in trimmed)
            [
              for (final p in s) [p.lng, p.lat, p.accuracyM],
            ],
        ],
      },
    'points': [
      for (final p in sent)
        {
          'id': p.id,
          'type': p.type.name,
          'seq': p.seq,
          if (p.number != null) 'number': p.number,
          if (p.title != null && p.title!.isNotEmpty) 'title': p.title,
          if (p.hintKind != null) 'hint_kind': p.hintKind!.name,
          'lat': p.lat,
          'lng': p.lng,
          'accuracy_m': p.accuracyM,
          'fix_count': p.fixCount,
          'low_accuracy': p.lowAccuracy,
          if (p.targetPointId != null) 'target_point_id': p.targetPointId,
          if (p.note != null && p.note!.isNotEmpty) 'note': p.note,
          'recorded_on': _date(p.recordedOn),
        },
    ],
    'photos_expected': photoCount,
    'app_version': appVersion,
    'platform': platform,
  };
}

/// Fehlercodes, die der Server als Nachricht wirft.
const rejectionCodes = {
  'limit_open',
  'limit_daily',
  'invalid_payload',
  'too_large',
};

final reportUploaderProvider = Provider<ReportUploader>((ref) {
  final uploader = ReportUploader(ref);
  ref.onDispose(uploader.dispose);
  return uploader;
});

/// Hält Verbindung, Konto und Warteschlange zusammen: Einreichen löst
/// `flush` aus, ebenso App-Start, Netz-Rückkehr, Anmeldung und manuelles
/// „Erneut versuchen“.
class ReportUploader {
  ReportUploader(this._ref);

  final Ref _ref;
  bool _running = false;
  Timer? _retry;

  void dispose() => _retry?.cancel();

  SupabaseClient? get _client => _ref.read(supabaseClientProvider);
  bool get _signedIn =>
      SupabaseConfig.isConfigured && _ref.read(authStateProvider).value != null;

  /// Einreichen aus R4 (Z-Status S5/S6). Ändert den Status und startet die
  /// Warteschlange.
  Future<ReportDraft> submit(ReportDraft draft) async {
    final event = _signedIn
        ? DraftEvent.submitSignedIn
        : DraftEvent.submitSignedOut;
    final next = nextDraftStatus(draft.status, event) ?? draft.status;
    final updated = draft.copyWith(status: next, clearFailure: true);
    await _ref.read(reportDraftsProvider.notifier).save(updated);
    if (next == DraftStatus.queued) unawaited(flush());
    return updated;
  }

  /// „Erneut versuchen“ und Bearbeiten nach `failed`.
  Future<void> retry(String draftId) async {
    final draft = await _ref.read(reportDraftStoreProvider).load(draftId);
    if (draft == null) return;
    if (draft.status == DraftStatus.failed ||
        draft.status == DraftStatus.awaitingAccount) {
      final status = _signedIn
          ? DraftStatus.queued
          : DraftStatus.awaitingAccount;
      await _ref
          .read(reportDraftsProvider.notifier)
          .save(
            draft.copyWith(status: status, clearFailure: true, attempts: 0),
          );
    }
    unawaited(flush());
  }

  /// Arbeitet alle wartenden Beiträge ab.
  Future<void> flush() async {
    if (_running || !SupabaseConfig.isConfigured) return;
    _running = true;
    _retry?.cancel();
    try {
      final store = _ref.read(reportDraftStoreProvider);
      var drafts = await store.listDrafts();
      if (_signedIn) {
        for (final d in drafts.where(
          (d) => d.status == DraftStatus.awaitingAccount,
        )) {
          await store.saveDraft(d.copyWith(status: DraftStatus.queued));
        }
        drafts = await store.listDrafts();
      }
      // Ein Upload, der beim Beenden der App lief, gilt als wartend.
      final waiting =
          drafts
              .where(
                (d) =>
                    d.status == DraftStatus.queued ||
                    d.status == DraftStatus.uploading,
              )
              .toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      for (final d in waiting) {
        if (!_signedIn) break;
        final ok = await _upload(d);
        if (!ok) break;
      }
    } finally {
      _running = false;
      unawaited(_ref.read(reportDraftsProvider.notifier).refresh());
    }
  }

  Future<void> _set(ReportDraft d) async {
    await _ref.read(reportDraftStoreProvider).saveDraft(d);
  }

  /// `true`, wenn der Beitrag durch ist oder endgültig scheiterte. `false`
  /// bei Netzfehler oder Abmeldung (Queue stoppt).
  Future<bool> _upload(ReportDraft draft) async {
    final client = _client;
    if (client == null) return false;
    final store = _ref.read(reportDraftStoreProvider);
    var d = draft.copyWith(
      status: DraftStatus.uploading,
      attempts: draft.attempts + 1,
    );
    await _set(d);
    unawaited(_ref.read(reportDraftsProvider.notifier).refresh());

    try {
      if (d.serverId == null) {
        final points = await store.points(d.id);
        final fixes = await store.fixes(d.id);
        final photos = await store.photos(d.id);
        final payload = buildSubmissionPayload(
          draft: d,
          points: points,
          segments: segmentsFromFixes(fixes),
          photoCount: photos.length,
          platform: 'app',
        );
        final id = await client.rpc<dynamic>(
          'create_submission',
          params: {'payload': payload},
        );
        d = d.copyWith(serverId: '$id', photosExpected: photos.length);
        await _set(d);
      }

      final photos = await store.photos(d.id);
      for (final photo in photos.where((p) => !p.uploaded)) {
        final bytes = await store.readPhotoBytes(photo.localPath);
        if (bytes == null) {
          await store.savePhoto(photo.copyWith(uploaded: true));
          continue;
        }
        await _sendPhoto(client, d.serverId!, photo, bytes);
        await store.savePhoto(photo.copyWith(uploaded: true));
      }

      d = d.copyWith(
        status: nextDraftStatus(
          DraftStatus.uploading,
          DraftEvent.uploadComplete,
        ),
        serverStatus: SubmissionStatus.submitted,
        photosMissing: 0,
        clearFailure: true,
        serverCheckedAt: DateTime.now(),
      );
      await _set(d);
      await store.clearHeavy(d.id);
      return true;
    } on AuthException {
      await _set(d.copyWith(status: DraftStatus.awaitingAccount));
      return false;
    } on PostgrestException catch (e) {
      if (e.code == '28000' || e.code == 'PGRST301' || e.code == '401') {
        await _set(d.copyWith(status: DraftStatus.awaitingAccount));
        return false;
      }
      final code = rejectionCodes.firstWhere(
        (c) => e.message.contains(c),
        orElse: () => '',
      );
      if (code.isNotEmpty) {
        await _set(d.copyWith(status: DraftStatus.failed, failureCode: code));
        return true;
      }
      return _networkFailure(d);
    } on StorageException catch (e) {
      if (e.statusCode == '401' || e.statusCode == '403') {
        await _set(d.copyWith(status: DraftStatus.awaitingAccount));
        return false;
      }
      return _networkFailure(d);
    } catch (_) {
      return _networkFailure(d);
    }
  }

  Future<bool> _sendPhoto(
    SupabaseClient client,
    String submissionId,
    DraftPhoto photo,
    Uint8List bytes,
  ) async {
    final uid = client.auth.currentUser?.id;
    if (uid == null) throw const AuthException('Nicht angemeldet.');
    final path = '$uid/$submissionId/${photo.id}.jpg';
    await client.storage
        .from(_bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );
    await client.rpc<dynamic>(
      'attach_photo',
      params: {
        'p_submission_id': submissionId,
        'p_point_id': photo.pointId,
        'p_path': path,
        'p_width': photo.width,
        'p_height': photo.height,
      },
    );
    return true;
  }

  /// Netzfehler oder 5xx: zurück in die Warteschlange, Wiederholung nach
  /// 5 s, 30 s, 5 min. Danach nur noch bei Auslösern.
  Future<bool> _networkFailure(ReportDraft d) async {
    await _set(d.copyWith(status: DraftStatus.queued));
    final backoff = cfg.uploadBackoffS;
    if (d.attempts <= backoff.length) {
      _retry = Timer(Duration(seconds: backoff[d.attempts - 1]), () {
        unawaited(flush());
      });
    }
    return false;
  }
}

/// Löst `flush` bei App-Start, Netz-Rückkehr und Anmeldung aus. Einmalig in
/// der Shell beobachten.
final reportUploadLifecycleProvider = Provider<void>((ref) {
  if (!SupabaseConfig.isConfigured) return;
  final uploader = ref.watch(reportUploaderProvider);
  unawaited(uploader.flush());
  unawaited(ref.read(reportServerProvider).refresh());
  ref.listen<bool>(offlineProvider, (prev, offline) {
    if (prev == true && !offline) unawaited(uploader.flush());
  });
  ref.listen(authStateProvider, (prev, next) {
    final user = next.asData?.value;
    if (user != null && prev?.asData?.value == null) {
      unawaited(uploader.flush());
    }
  });
});
