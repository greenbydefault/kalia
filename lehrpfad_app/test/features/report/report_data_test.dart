import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/features/report/data/file_draft_store.dart';
import 'package:lehrpfad_app/features/report/data/report_uploader.dart';
import 'package:lehrpfad_app/features/report/domain/report_enums.dart';
import 'package:lehrpfad_app/features/report/domain/report_models.dart';
import 'package:lehrpfad_app/features/report/logic/geo.dart';

const _id = '11111111-1111-4111-8111-111111111111';

ReportDraft _draft({
  ReportKind kind = ReportKind.newTrail,
  double trimStartM = 0,
  double trimEndM = 0,
}) {
  final now = DateTime(2026, 10, 17);
  return ReportDraft(
    id: _id,
    kind: kind,
    mode: RecordingMode.trackAndPoints,
    status: DraftStatus.review,
    createdAt: now,
    updatedAt: now,
    title: '  Teichweg ',
    area: 'Plön',
    isLoop: true,
    trimStartM: trimStartM,
    trimEndM: trimEndM,
  );
}

DraftPoint _point(String id, PointType type, int seq, {double lat = 54.0}) {
  return DraftPoint(
    id: id,
    draftId: _id,
    type: type,
    seq: seq,
    lat: lat,
    lng: 10.0,
    accuracyM: 4,
    fixCount: 6,
    lowAccuracy: false,
    recordedOn: DateTime(2026, 10, 17),
  );
}

TrackSegments get _segments => [
  [
    for (var i = 0; i < 30; i++) TrackPoint(54.0 + i * 0.0001, 10.0, 5),
  ],
];

void main() {
  group('buildSubmissionPayload', () {
    test('neuer Pfad: Titel getrimmt, Track ohne Zeit, Datum ohne Uhrzeit', () {
      final p = buildSubmissionPayload(
        draft: _draft(),
        points: [_point('a', PointType.start, 0)],
        segments: _segments,
        photoCount: 2,
      );
      expect(p['client_submission_id'], _id);
      expect(p['kind'], 'new_trail');
      expect(p['title'], 'Teichweg');
      expect(p['photos_expected'], 2);
      final track = p['track']! as Map;
      final seg = (track['segments']! as List).first as List;
      expect(seg.first, [10.0, 54.0, 5.0]); // [lng, lat, acc]
      final pt = (p['points']! as List).first as Map;
      expect(pt['recorded_on'], '2026-10-17');
    });

    test('ohne Track fehlt der Schlüssel', () {
      final p = buildSubmissionPayload(
        draft: _draft(),
        points: const [],
        segments: const [],
        photoCount: 0,
      );
      expect(p.containsKey('track'), isFalse);
    });

    test('gekürzter Anfang/Ende nimmt Start-/Ende-Marker mit', () {
      final p = buildSubmissionPayload(
        draft: _draft(trimStartM: 10, trimEndM: 10),
        points: [
          _point('a', PointType.start, 0),
          _point('b', PointType.station, 1),
          _point('c', PointType.end, 2),
        ],
        segments: _segments,
        photoCount: 0,
      );
      final types = [
        for (final m in p['points']! as List) (m as Map)['type'],
      ];
      expect(types, ['station']);
    });

    test('Schnellmeldung ohne is_loop/title', () {
      final p = buildSubmissionPayload(
        draft: _draft(kind: ReportKind.quick),
        points: [_point('a', PointType.hint, 0)],
        segments: const [],
        photoCount: 0,
      );
      expect(p.containsKey('is_loop'), isFalse);
      expect(p.containsKey('title'), isFalse);
      expect(p['kind'], 'quick');
    });
  });

  group('Entwurfsspeicher', () {
    late Directory tmp;
    late FileReportDraftStore store;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('report_store_');
      store = FileReportDraftStore(root: tmp);
    });
    tearDown(() => tmp.deleteSync(recursive: true));

    test('Entwurf, Punkte und Fixes überleben einen Neustart', () async {
      await store.saveDraft(_draft());
      await store.savePoint(_point('a', PointType.start, 0));
      await store.savePoint(_point('b', PointType.station, 1));
      await store.appendFixes(_id, [
        for (var i = 0; i < 5; i++)
          TrackFix(
            draftId: _id,
            seq: i,
            segment: 0,
            lat: 54.0 + i * 0.0001,
            lng: 10,
            accuracyM: 5,
            t: DateTime(2026, 10, 17, 12, 0, i),
          ),
      ]);

      final fresh = FileReportDraftStore(root: tmp);
      expect((await fresh.load(_id))?.title, '  Teichweg ');
      expect((await fresh.points(_id)).map((p) => p.id), ['a', 'b']);
      expect((await fresh.fixes(_id)).length, 5);
      expect((await fresh.listDrafts()).length, 1);
    });

    test('Punkt löschen und Entwurf löschen', () async {
      await store.saveDraft(_draft());
      await store.savePoint(_point('a', PointType.start, 0));
      await store.deletePoint(_id, 'a');
      expect(await store.points(_id), isEmpty);
      await store.deleteDraft(_id);
      expect(await store.load(_id), isNull);
    });

    test('parallele Schreibzugriffe gehen nicht verloren', () async {
      await store.saveDraft(_draft());
      await Future.wait([
        for (var i = 0; i < 20; i++)
          store.savePoint(_point('p$i', PointType.waypoint, i)),
      ]);
      expect((await store.points(_id)).length, 20);
    });
  });
}
