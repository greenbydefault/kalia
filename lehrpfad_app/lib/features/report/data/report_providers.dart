import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../domain/report_enums.dart';
import '../domain/report_models.dart';
import '../logic/geo.dart';
import 'draft_store.dart';
import 'draft_store_platform.dart';

const _uuid = Uuid();

String newReportId() => _uuid.v4();

final reportDraftStoreProvider = Provider<ReportDraftStore>(
  (ref) => createReportDraftStore(),
);

/// Alle lokalen Beiträge (Entwürfe, Warteschlange, Cache eingereichter),
/// neueste zuerst.
final reportDraftsProvider =
    AsyncNotifierProvider<ReportDraftsNotifier, List<ReportDraft>>(
      ReportDraftsNotifier.new,
    );

class ReportDraftsNotifier extends AsyncNotifier<List<ReportDraft>> {
  @override
  Future<List<ReportDraft>> build() => _load();

  Future<List<ReportDraft>> _load() async {
    final list = await ref.read(reportDraftStoreProvider).listDrafts();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  Future<void> refresh() async {
    state = AsyncData(await _load());
  }

  Future<void> save(ReportDraft draft) async {
    await ref.read(reportDraftStoreProvider).saveDraft(draft);
    await refresh();
  }

  Future<void> delete(String id) async {
    await ref.read(reportDraftStoreProvider).deleteDraft(id);
    await refresh();
  }
}

/// Baut aus den gespeicherten Fixes die Segmente des Tracks.
TrackSegments segmentsFromFixes(List<TrackFix> fixes) {
  final bySegment = <int, List<TrackPoint>>{};
  for (final f in fixes) {
    (bySegment[f.segment] ??= []).add(TrackPoint(f.lat, f.lng, f.accuracyM));
  }
  final keys = bySegment.keys.toList()..sort();
  return [for (final k in keys) bySegment[k]!];
}

/// Entwurf im Status [DraftStatus.recording] oder [DraftStatus.paused].
final activeRecordingDraftProvider = Provider<ReportDraft?>((ref) {
  final drafts = ref.watch(reportDraftsProvider).value ?? const [];
  for (final d in drafts) {
    if (d.status == DraftStatus.recording || d.status == DraftStatus.paused) {
      return d;
    }
  }
  return null;
});
