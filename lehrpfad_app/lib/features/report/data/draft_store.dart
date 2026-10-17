import 'dart:typed_data';

import '../domain/report_models.dart';

/// Lokaler Entwurfsspeicher (Spec 7.1). Marker, Statuswechsel und
/// Formularfelder werden sofort geschrieben, Track-Fixes in Blöcken.
///
/// Zwei Adapter: Dateien (native) und Speicher (Web, Tests). Die Aufnahme
/// selbst läuft nur auf dem Handy.
abstract class ReportDraftStore {
  Future<List<ReportDraft>> listDrafts();
  Future<ReportDraft?> load(String id);
  Future<void> saveDraft(ReportDraft draft);

  Future<List<DraftPoint>> points(String draftId);
  Future<void> savePoint(DraftPoint point);
  Future<void> deletePoint(String draftId, String pointId);

  Future<List<DraftPhoto>> photos(String draftId);
  Future<void> savePhoto(DraftPhoto photo);
  Future<void> deletePhoto(String draftId, String photoId);

  /// Legt die Bytes ab und liefert den lokalen Pfad.
  Future<String> writePhotoBytes(
    String draftId,
    String photoId,
    Uint8List bytes,
  );
  Future<Uint8List?> readPhotoBytes(String localPath);

  Future<void> appendFixes(String draftId, List<TrackFix> fixes);
  Future<List<TrackFix>> fixes(String draftId);

  /// Löscht Datenbankzeilen und Fotodateien gemeinsam.
  Future<void> deleteDraft(String draftId);

  /// Nach erfolgreichem Upload: Track-Fixes und Fotodateien weg, die Zeile
  /// bleibt als Cache für R7.
  Future<void> clearHeavy(String draftId);
}

/// In-Memory-Adapter (Web, Tests).
class MemoryReportDraftStore implements ReportDraftStore {
  final _drafts = <String, ReportDraft>{};
  final _points = <String, Map<String, DraftPoint>>{};
  final _photos = <String, Map<String, DraftPhoto>>{};
  final _fixes = <String, List<TrackFix>>{};
  final _bytes = <String, Uint8List>{};

  @override
  Future<List<ReportDraft>> listDrafts() async => _drafts.values.toList();

  @override
  Future<ReportDraft?> load(String id) async => _drafts[id];

  @override
  Future<void> saveDraft(ReportDraft draft) async => _drafts[draft.id] = draft;

  @override
  Future<List<DraftPoint>> points(String draftId) async {
    final list = (_points[draftId] ?? const {}).values.toList()
      ..sort((a, b) => a.seq.compareTo(b.seq));
    return list;
  }

  @override
  Future<void> savePoint(DraftPoint point) async {
    (_points[point.draftId] ??= {})[point.id] = point;
  }

  @override
  Future<void> deletePoint(String draftId, String pointId) async {
    _points[draftId]?.remove(pointId);
  }

  @override
  Future<List<DraftPhoto>> photos(String draftId) async =>
      (_photos[draftId] ?? const {}).values.toList();

  @override
  Future<void> savePhoto(DraftPhoto photo) async {
    (_photos[photo.draftId] ??= {})[photo.id] = photo;
  }

  @override
  Future<void> deletePhoto(String draftId, String photoId) async {
    final p = _photos[draftId]?.remove(photoId);
    if (p != null) _bytes.remove(p.localPath);
  }

  @override
  Future<String> writePhotoBytes(
    String draftId,
    String photoId,
    Uint8List bytes,
  ) async {
    final path = 'mem:$draftId/$photoId.jpg';
    _bytes[path] = bytes;
    return path;
  }

  @override
  Future<Uint8List?> readPhotoBytes(String localPath) async =>
      _bytes[localPath];

  @override
  Future<void> appendFixes(String draftId, List<TrackFix> fixes) async {
    (_fixes[draftId] ??= []).addAll(fixes);
  }

  @override
  Future<List<TrackFix>> fixes(String draftId) async =>
      List.of(_fixes[draftId] ?? const []);

  @override
  Future<void> deleteDraft(String draftId) async {
    _drafts.remove(draftId);
    _points.remove(draftId);
    _fixes.remove(draftId);
    final photos = _photos.remove(draftId);
    for (final p in photos?.values ?? const <DraftPhoto>[]) {
      _bytes.remove(p.localPath);
    }
  }

  @override
  Future<void> clearHeavy(String draftId) async {
    _fixes.remove(draftId);
    final photos = _photos[draftId];
    for (final p in photos?.values ?? const <DraftPhoto>[]) {
      _bytes.remove(p.localPath);
    }
    _photos.remove(draftId);
  }
}
