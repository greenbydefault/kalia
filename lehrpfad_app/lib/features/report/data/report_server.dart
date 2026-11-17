import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_client_provider.dart';
import '../../trail/data/providers.dart';
import '../domain/report_enums.dart';
import '../domain/report_models.dart';
import '../logic/geo.dart';
import 'report_providers.dart';

SubmissionStatus? submissionStatusFromWire(String? w) => switch (w) {
  'submitted' => SubmissionStatus.submitted,
  'in_review' => SubmissionStatus.inReview,
  'needs_info' => SubmissionStatus.needsInfo,
  'approved' => SubmissionStatus.approved,
  'partially_approved' => SubmissionStatus.partiallyApproved,
  'rejected' => SubmissionStatus.rejected,
  'withdrawn' => SubmissionStatus.withdrawn,
  _ => null,
};

DecisionReason? decisionReasonFromWire(String? w) => switch (w) {
  'duplicate' => DecisionReason.duplicate,
  'within_gps_noise' => DecisionReason.withinGpsNoise,
  'not_family_suitable' => DecisionReason.notFamilySuitable,
  'not_public' => DecisionReason.notPublic,
  'insufficient_data' => DecisionReason.insufficientData,
  'wrong_location' => DecisionReason.wrongLocation,
  'other' => DecisionReason.other,
  null => null,
  _ => DecisionReason.other,
};

String decisionReasonKey(DecisionReason r) => switch (r) {
  DecisionReason.duplicate => 'report.reject.duplicate',
  DecisionReason.withinGpsNoise => 'report.reject.within_gps_noise',
  DecisionReason.notFamilySuitable => 'report.reject.not_family_suitable',
  DecisionReason.notPublic => 'report.reject.not_public',
  DecisionReason.insufficientData => 'report.reject.insufficient_data',
  DecisionReason.wrongLocation => 'report.reject.wrong_location',
  DecisionReason.other => 'report.reject.other',
};

/// Status, bei dem die Nutzerin etwas Neues sehen soll (Punkt in R7).
bool isUnseen(ReportDraft d) {
  final s = d.serverStatus;
  if (s == null || s == SubmissionStatus.submitted) return false;
  return d.lastSeenStatus != s.name;
}

class ReportEvent {
  const ReportEvent({
    required this.event,
    required this.at,
    this.payload = const {},
  });

  final String event;
  final DateTime at;
  final Map<String, dynamic> payload;
}

/// Track und Marker einer eingereichten Meldung (Antwort von
/// `my_submission_geo`).
class SubmissionGeo {
  const SubmissionGeo({this.segments = const [], this.points = const []});

  final TrackSegments segments;
  final List<DraftPoint> points;
}

/// `track` ist GeoJSON-MultiLineString (`[[[lng, lat], ...], ...]`).
SubmissionGeo parseSubmissionGeo(Object? json, String draftId) {
  if (json is! Map) return const SubmissionGeo();
  final segments = <List<TrackPoint>>[];
  final track = json['track'];
  if (track is List) {
    for (final seg in track) {
      if (seg is! List) continue;
      final line = <TrackPoint>[];
      for (final c in seg) {
        if (c is List && c.length >= 2) {
          line.add(
            TrackPoint((c[1] as num).toDouble(), (c[0] as num).toDouble()),
          );
        }
      }
      if (line.length >= 2) segments.add(line);
    }
  }
  final points = <DraftPoint>[];
  final raw = json['points'];
  if (raw is List) {
    for (final p in raw) {
      if (p is! Map) continue;
      final lat = p['lat'];
      final lng = p['lng'];
      if (lat is! num || lng is! num) continue;
      final type = PointType.values
          .where((t) => t.name == p['type'])
          .firstOrNull;
      if (type == null) continue;
      points.add(
        DraftPoint(
          id: '${p['id']}',
          draftId: draftId,
          type: type,
          seq: (p['seq'] as num?)?.toInt() ?? points.length,
          number: (p['number'] as num?)?.toInt(),
          title: p['title'] as String?,
          hintKind: HintKind.values
              .where((h) => h.name == p['hint_kind'])
              .firstOrNull,
          lat: lat.toDouble(),
          lng: lng.toDouble(),
          accuracyM: (p['accuracy_m'] as num?)?.toDouble() ?? 0,
          fixCount: (p['fix_count'] as num?)?.toInt() ?? 1,
          lowAccuracy: (p['low_accuracy'] as bool?) ?? false,
          recordedOn: DateTime.now(),
        ),
      );
    }
  }
  return SubmissionGeo(segments: segments, points: points);
}

final reportServerProvider = Provider<ReportServer>((ref) => ReportServer(ref));

/// Lesen und Schreiben der eigenen Meldungen auf dem Server (R7, R8).
class ReportServer {
  ReportServer(this._ref);

  final Ref _ref;

  SupabaseClient? get _client => _ref.read(supabaseClientProvider);

  /// Holt den Stand der eigenen Meldungen und gleicht den lokalen Cache ab.
  /// `false` bei Fehler (Anzeige „Stand von …“).
  Future<bool> refresh() async {
    final client = _client;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) return false;
    try {
      final rows = await client
          .from('submissions')
          .select(
            'id, client_submission_id, kind, target_trail_id, intent, status, '
            'title, decision_reason_code, decision_note, decided_at, '
            'photos_expected, submitted_at',
          )
          .eq('user_id', uid)
          .order('submitted_at', ascending: false)
          .limit(100);
      final store = _ref.read(reportDraftStoreProvider);
      final local = {for (final d in await store.listDrafts()) d.id: d};
      final trails = _ref.read(trailsProvider).value ?? const [];
      final names = {for (final t in trails) t.id: t.name};
      final now = DateTime.now();

      for (final r in rows) {
        final cid = r['client_submission_id'] as String;
        final status = submissionStatusFromWire(r['status'] as String?);
        String? question;
        if (status == SubmissionStatus.needsInfo) {
          final ev = await client
              .from('submission_events')
              .select('payload')
              .eq('submission_id', r['id'] as String)
              .eq('event', 'needs_info')
              .order('created_at', ascending: false)
              .limit(1);
          if (ev.isNotEmpty) {
            question =
                (ev.first['payload'] as Map<String, dynamic>?)?['question']
                    as String?;
          }
        }
        final existing = local[cid];
        final decidedAt = DateTime.tryParse('${r['decided_at'] ?? ''}');
        if (existing != null) {
          // Lokale Zustände wie queued/uploading bleiben unberührt.
          await store.saveDraft(
            existing.copyWith(
              serverId: r['id'] as String,
              serverStatus: status,
              decisionReason: decisionReasonFromWire(
                r['decision_reason_code'] as String?,
              ),
              decisionNote: r['decision_note'] as String?,
              serverQuestion: question,
              decidedAt: decidedAt,
              photosExpected: (r['photos_expected'] as num?)?.toInt(),
              serverCheckedAt: now,
              updatedAt: existing.updatedAt,
            ),
          );
        } else {
          final kind = switch (r['kind']) {
            'new_trail' => ReportKind.newTrail,
            'revision' => ReportKind.revision,
            _ => ReportKind.quick,
          };
          final intent = switch (r['intent']) {
            'move_point' => QuickIntent.movePoint,
            'add_point' => QuickIntent.addPoint,
            'hint' => QuickIntent.hint,
            'other' => QuickIntent.other,
            _ => null,
          };
          final submittedAt =
              DateTime.tryParse('${r['submitted_at'] ?? ''}') ?? now;
          final tid = r['target_trail_id'] as String?;
          await store.saveDraft(
            ReportDraft(
              id: cid,
              kind: kind,
              mode: RecordingMode.trackAndPoints,
              status: DraftStatus.submitted,
              createdAt: submittedAt,
              updatedAt: submittedAt,
              targetTrailId: tid,
              targetTrailName: tid == null ? null : names[tid],
              intent: intent,
              title: r['title'] as String?,
              serverId: r['id'] as String,
              serverStatus: status,
              decisionReason: decisionReasonFromWire(
                r['decision_reason_code'] as String?,
              ),
              decisionNote: r['decision_note'] as String?,
              serverQuestion: question,
              decidedAt: decidedAt,
              photosExpected: (r['photos_expected'] as num?)?.toInt() ?? 0,
              serverCheckedAt: now,
              // Auf einem neuen Gerät nichts als „neu“ markieren.
              lastSeenStatus: status?.name,
            ),
          );
        }
      }
      await _ref.read(reportDraftsProvider.notifier).refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Verlauf aus `submission_events` (nur sichtbare Einträge).
  Future<List<ReportEvent>> events(String serverId) async {
    final client = _client;
    if (client == null) return const [];
    final rows = await client
        .from('submission_events')
        .select('event, payload, created_at')
        .eq('submission_id', serverId)
        .order('created_at');
    return [
      for (final r in rows)
        ReportEvent(
          event: r['event'] as String,
          at: DateTime.tryParse('${r['created_at']}') ?? DateTime.now(),
          payload: (r['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
    ];
  }

  /// Track und Marker der eigenen Meldung (für die Detailkarte).
  Future<SubmissionGeo> geo(String serverId, String draftId) async {
    final client = _client;
    if (client == null) return const SubmissionGeo();
    final res = await client.rpc<dynamic>(
      'my_submission_geo',
      params: {'p_submission_id': serverId},
    );
    return parseSubmissionGeo(res, draftId);
  }

  Future<void> reply(String serverId, String text) async {
    await _client!.rpc<dynamic>(
      'reply_submission',
      params: {'p_submission_id': serverId, 'p_text': text},
    );
  }

  Future<void> withdraw(String serverId) async {
    await _client!.rpc<dynamic>(
      'withdraw_submission',
      params: {'p_submission_id': serverId},
    );
  }
}
