import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../trail_progress/tracking/location_service.dart';
import '../domain/report_enums.dart';
import '../domain/report_models.dart';
import '../logic/averaging.dart';
import '../logic/draft_transitions.dart';
import '../logic/geo.dart';
import '../logic/review_logic.dart';
import '../logic/signal.dart';
import '../logic/track_filter.dart';
import '../logic/track_metrics.dart';
import '../report_config.dart';
import 'draft_store.dart';
import 'point_measurer.dart';
import 'report_providers.dart';

enum RecorderEventType {
  markerSet,
  lowAccuracy,
  noFix,
  markerLimit,
  trackFull,
  gpsBack,
  backgroundFailed,
}

class RecorderEvent {
  const RecorderEvent(this.type, {this.point});

  final RecorderEventType type;
  final DraftPoint? point;
}

/// Zustand der laufenden Aufnahme (R2). `null` im Provider = keine Aufnahme.
class RecorderState {
  const RecorderState({
    required this.draft,
    required this.points,
    required this.trackRev,
    required this.lengthM,
    required this.trackPointCount,
    this.fix,
    this.lastFixAt,
    this.nextType = PointType.station,
    this.measuring = false,
    this.measureProgress = 0,
    this.noGps = false,
    this.trackFull = false,
    this.secondsSinceFix,
  });

  final ReportDraft draft;
  final List<DraftPoint> points;

  /// Erhöht sich mit jedem neuen Track-Punkt, damit die Karte neu zeichnet.
  final int trackRev;
  final double lengthM;
  final int trackPointCount;
  final LocationFix? fix;
  final DateTime? lastFixAt;
  final PointType nextType;
  final bool measuring;
  final double measureProgress;
  final bool noGps;
  final bool trackFull;
  final double? secondsSinceFix;

  bool get paused => draft.status == DraftStatus.paused;
  bool get pointsOnly => draft.mode == RecordingMode.pointsOnly;
  int get stationCount =>
      points.where((p) => p.type == PointType.station).length;
  bool get markerLimit => markerLimitReached(points.length);

  SignalLevel get signal =>
      signalLevel(accuracyM: fix?.accuracyM, secondsSinceFix: secondsSinceFix);

  RecorderState copyWith({
    ReportDraft? draft,
    List<DraftPoint>? points,
    int? trackRev,
    double? lengthM,
    int? trackPointCount,
    LocationFix? fix,
    DateTime? lastFixAt,
    PointType? nextType,
    bool? measuring,
    double? measureProgress,
    bool? noGps,
    bool? trackFull,
    double? secondsSinceFix,
  }) => RecorderState(
    draft: draft ?? this.draft,
    points: points ?? this.points,
    trackRev: trackRev ?? this.trackRev,
    lengthM: lengthM ?? this.lengthM,
    trackPointCount: trackPointCount ?? this.trackPointCount,
    fix: fix ?? this.fix,
    lastFixAt: lastFixAt ?? this.lastFixAt,
    nextType: nextType ?? this.nextType,
    measuring: measuring ?? this.measuring,
    measureProgress: measureProgress ?? this.measureProgress,
    noGps: noGps ?? this.noGps,
    trackFull: trackFull ?? this.trackFull,
    secondsSinceFix: secondsSinceFix ?? this.secondsSinceFix,
  );
}

final reportRecorderProvider = NotifierProvider<ReportRecorder, RecorderState?>(
  ReportRecorder.new,
);

/// Aufnahme-Controller (Spec 4.3, 6): hält den Standort-Stream, filtert den
/// Track, mittelt Marker und schreibt alles sofort in den Entwurfsspeicher.
class ReportRecorder extends Notifier<RecorderState?> {
  final _events = StreamController<RecorderEvent>.broadcast();

  /// Track-Segmente der laufenden Aufnahme (veränderlich, [RecorderState.trackRev]
  /// zeigt Änderungen an).
  final TrackSegments segments = [];

  TrackFilterState _filter = const TrackFilterState();
  final _buffer = <TrackFix>[];
  int _fixSeq = 0;
  StreamSubscription<LocationFix>? _sub;
  Timer? _flushTimer;
  Timer? _tick;
  DateTime _startedAt = DateTime.now();

  Stream<RecorderEvent> get events => _events.stream;

  @override
  RecorderState? build() {
    ref.onDispose(() {
      _stopStream();
      _events.close();
    });
    return null;
  }

  ReportConfig get _c => cfg;
  LocationService get _location => ref.read(locationServiceProvider);
  ReportDraftStore get _store => ref.read(reportDraftStoreProvider);

  void _touchDrafts() {
    unawaited(ref.read(reportDraftsProvider.notifier).refresh());
  }

  // ── Start, Fortsetzen ────────────────────────────────────────────

  /// Legt den Entwurf an, startet den Stream und misst den Start-Marker.
  Future<ReportDraft> start({
    required ReportKind kind,
    required RecordingMode mode,
    String? targetTrailId,
    String? targetTrailName,
    bool lowAccuracyStart = false,
  }) async {
    final running = state;
    if (running != null) return running.draft;
    final now = DateTime.now();
    final draft = ReportDraft(
      id: newReportId(),
      kind: kind,
      mode: mode,
      status: DraftStatus.recording,
      createdAt: now,
      updatedAt: now,
      targetTrailId: targetTrailId,
      targetTrailName: targetTrailName,
      lowAccuracyStart: lowAccuracyStart,
      openedAt: now,
    );
    await _store.saveDraft(draft);
    _resetRuntime();
    state = RecorderState(
      draft: draft,
      points: const [],
      trackRev: 0,
      lengthM: 0,
      trackPointCount: 0,
    );
    _attach();
    _touchDrafts();
    unawaited(_setStartMarker(lowAccuracyStart));
    return draft;
  }

  /// Nimmt eine unterbrochene oder fertige Aufnahme wieder auf (R15, „Weiter
  /// aufnehmen“ in R4). Beginnt ein neues Track-Segment.
  Future<void> resume(String draftId, {bool dropAutoEnd = false}) async {
    if (state != null && state!.draft.id == draftId) return;
    final draft = await _store.load(draftId);
    if (draft == null) return;
    var points = await _store.points(draftId);
    if (dropAutoEnd) {
      for (final p in points.where((p) => p.type == PointType.end)) {
        await _store.deletePoint(draftId, p.id);
      }
      points = [
        for (final p in points)
          if (p.type != PointType.end) p,
      ];
    }
    final fixes = await _store.fixes(draftId);
    _resetRuntime();
    segments
      ..clear()
      ..addAll(segmentsFromFixes(fixes));
    final lastSeg = fixes.isEmpty
        ? -1
        : fixes.map((f) => f.segment).reduce((a, b) => a > b ? a : b);
    _filter = TrackFilterState(segment: lastSeg + 1);
    _fixSeq = fixes.isEmpty ? 0 : fixes.last.seq + 1;
    final next = draft.status == DraftStatus.review
        ? DraftStatus.recording
        : (draft.status == DraftStatus.paused
              ? DraftStatus.recording
              : draft.status);
    final resumed = draft.copyWith(status: next, justFinished: false);
    await _store.saveDraft(resumed);
    state = RecorderState(
      draft: resumed,
      points: points,
      trackRev: 1,
      lengthM: trackLengthM(segments),
      trackPointCount: trackPointCount(segments),
      nextType: PointType.station,
    );
    _attach();
    _touchDrafts();
  }

  void _resetRuntime() {
    _stopStream();
    segments.clear();
    _filter = const TrackFilterState();
    _buffer.clear();
    _fixSeq = 0;
    _startedAt = DateTime.now();
  }

  void _attach() {
    final s = state;
    if (s == null) return;
    _sub?.cancel();
    final profile = s.pointsOnly
        ? LocationProfile.pointFix
        : LocationProfile.recording;
    _sub = _location
        .watchFixes(profile)
        .listen(_onFix, onError: _onStreamError);
    _tick ??= Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    _flushTimer ??= Timer.periodic(
      Duration(seconds: _c.trackFlushEveryS),
      (_) => unawaited(_flush()),
    );
  }

  void _stopStream() {
    _sub?.cancel();
    _sub = null;
    _tick?.cancel();
    _tick = null;
    _flushTimer?.cancel();
    _flushTimer = null;
  }

  /// Nur Punkte läuft im Hintergrund nichts: Stream bei App im Hintergrund
  /// anhalten, beim Zurückkehren neu starten.
  void setForeground(bool foreground) {
    final s = state;
    if (s == null || !s.pointsOnly) return;
    if (foreground) {
      if (_sub == null) _attach();
    } else {
      _sub?.cancel();
      _sub = null;
    }
  }

  void _onStreamError(Object error) {
    final s = state;
    if (s == null) return;
    if (!s.pointsOnly && s.fix == null) {
      // Dienststart schlägt fehl: weiter mit „Nur Punkte“ (Z32, M2).
      final draft = s.draft.copyWith(mode: RecordingMode.pointsOnly);
      state = s.copyWith(draft: draft);
      unawaited(_store.saveDraft(draft));
      _attach();
      _events.add(const RecorderEvent(RecorderEventType.backgroundFailed));
    }
  }

  // ── Fixes ────────────────────────────────────────────────────────

  void _onFix(LocationFix f) {
    final s = state;
    if (s == null) return;
    final now = DateTime.now();
    var next = s.copyWith(
      fix: f,
      lastFixAt: now,
      secondsSinceFix: 0,
      noGps: false,
    );
    if (s.noGps) _events.add(const RecorderEvent(RecorderEventType.gpsBack));

    if (!s.pointsOnly && !s.trackFull) {
      final raw = RawFix(
        f.position.latitude,
        f.position.longitude,
        f.accuracyM ?? 100,
        f.at,
      );
      final result = filterTrackFix(
        state: _filter,
        fix: raw,
        paused: s.paused,
        c: _c,
      );
      _filter = result.state;
      if (result.accepted) {
        while (segments.length <= _filter.segment) {
          segments.add([]);
        }
        final seg = segments[_filter.segment];
        final point = TrackPoint(raw.lat, raw.lng, raw.accuracyM);
        final added = seg.isEmpty ? 0.0 : seg.last.distanceTo(point);
        seg.add(point);
        _buffer.add(
          TrackFix(
            draftId: s.draft.id,
            seq: _fixSeq++,
            segment: _filter.segment,
            lat: raw.lat,
            lng: raw.lng,
            accuracyM: raw.accuracyM,
            t: raw.t,
          ),
        );
        final count = s.trackPointCount + 1;
        final full = trackLimitReached(count, c: _c);
        next = next.copyWith(
          trackRev: s.trackRev + 1,
          lengthM: s.lengthM + added,
          trackPointCount: count,
          trackFull: full,
        );
        if (full) _events.add(const RecorderEvent(RecorderEventType.trackFull));
        if (_buffer.length >= _c.trackFlushEveryFixes) unawaited(_flush());
      }
    }
    state = next;
  }

  void _onTick() {
    final s = state;
    if (s == null) return;
    final ref0 = s.lastFixAt ?? _startedAt;
    final secs = DateTime.now().difference(ref0).inMilliseconds / 1000;
    final noGps = secs > _c.noSignalAfterS;
    state = s.copyWith(secondsSinceFix: secs, noGps: noGps);
  }

  Future<void> _flush() async {
    if (_buffer.isEmpty) return;
    final id = state?.draft.id ?? _buffer.first.draftId;
    final batch = List<TrackFix>.of(_buffer);
    _buffer.clear();
    try {
      await _store.appendFixes(id, batch);
    } catch (_) {
      // Daten bleiben im Speicher, nächster Block versucht es erneut (Z11).
      _buffer.insertAll(0, batch);
    }
  }

  // ── Marker ───────────────────────────────────────────────────────

  Future<void> _setStartMarker(bool forceLow) async {
    final s0 = state;
    if (s0 == null) return;
    state = s0.copyWith(measuring: true, measureProgress: 0);
    final avg = await measurePoint(
      _location,
      onProgress: (p) {
        final s = state;
        if (s != null) state = s.copyWith(measureProgress: p);
      },
    );
    final s = state;
    if (s == null) return;
    if (avg == null) {
      state = s.copyWith(measuring: false);
      _events.add(const RecorderEvent(RecorderEventType.noFix));
      return;
    }
    final point = _newPoint(
      s,
      type: PointType.start,
      avg: avg,
      forceLow: forceLow,
    );
    await _store.savePoint(point);
    state = s.copyWith(points: [...s.points, point], measuring: false);
  }

  DraftPoint _newPoint(
    RecorderState s, {
    required PointType type,
    required Averaged avg,
    bool forceLow = false,
  }) {
    final seq = s.points.isEmpty
        ? 0
        : s.points.map((p) => p.seq).reduce((a, b) => a > b ? a : b) + 1;
    final markers = [
      for (final p in s.points) ReviewMarker(type: p.type, number: p.number),
    ];
    return DraftPoint(
      id: newReportId(),
      draftId: s.draft.id,
      type: type,
      seq: seq,
      number: type == PointType.station ? nextStationNumber(markers) : null,
      lat: avg.lat,
      lng: avg.lng,
      accuracyM: avg.accuracyM,
      fixCount: avg.fixCount,
      lowAccuracy: avg.lowAccuracy || forceLow,
      recordedOn: DateTime.now(),
    );
  }

  void selectType(PointType type) {
    final s = state;
    if (s == null) return;
    state = s.copyWith(nextType: type);
  }

  /// Setzt einen Marker vom gewählten Typ. Gibt den Marker zurück oder `null`
  /// (kein Signal, Limit, laufende Messung).
  Future<DraftPoint?> setPoint() async {
    final s0 = state;
    if (s0 == null || s0.measuring) return null;
    if (s0.markerLimit) {
      _events.add(const RecorderEvent(RecorderEventType.markerLimit));
      return null;
    }
    unawaited(HapticFeedback.mediumImpact());
    state = s0.copyWith(measuring: true, measureProgress: 0);
    final avg = await measurePoint(
      _location,
      onProgress: (p) {
        final s = state;
        if (s != null) state = s.copyWith(measureProgress: p);
      },
    );
    final s = state;
    if (s == null) return null;
    if (avg == null) {
      state = s.copyWith(measuring: false);
      _events.add(const RecorderEvent(RecorderEventType.noFix));
      return null;
    }
    final point = _newPoint(s, type: s.nextType, avg: avg);
    await _store.savePoint(point);
    state = s.copyWith(
      points: [...s.points, point],
      measuring: false,
      nextType: PointType.station,
    );
    if (point.lowAccuracy) {
      unawaited(HapticFeedback.lightImpact());
      unawaited(
        Future<void>.delayed(
          const Duration(milliseconds: 120),
          HapticFeedback.lightImpact,
        ),
      );
      _events.add(RecorderEvent(RecorderEventType.lowAccuracy, point: point));
    } else {
      unawaited(HapticFeedback.mediumImpact());
    }
    _events.add(RecorderEvent(RecorderEventType.markerSet, point: point));
    return point;
  }

  Future<void> updatePoint(DraftPoint point) async {
    final s = state;
    await _store.savePoint(point);
    if (s == null) return;
    state = s.copyWith(
      points: [for (final p in s.points) p.id == point.id ? point : p],
    );
  }

  /// Entfernt einen Marker. Automatische Stationsnummern rücken nach.
  Future<DraftPoint?> deletePoint(String pointId) async {
    final s = state;
    if (s == null) return null;
    DraftPoint? removed;
    for (final p in s.points) {
      if (p.id == pointId) removed = p;
    }
    if (removed == null) return null;
    await _store.deletePoint(s.draft.id, pointId);
    final rest = [
      for (final p in s.points)
        if (p.id != pointId) p,
    ];
    final renumbered = await _renumber(rest);
    state = s.copyWith(points: renumbered);
    return removed;
  }

  /// Rückgängig für „Löschen“ und für den letzten Marker.
  Future<void> restorePoint(DraftPoint point) async {
    final s = state;
    if (s == null) return;
    await _store.savePoint(point);
    final all = [...s.points, point]..sort((a, b) => a.seq.compareTo(b.seq));
    state = s.copyWith(points: await _renumber(all));
  }

  Future<List<DraftPoint>> _renumber(List<DraftPoint> points) async {
    final markers = [
      for (final p in points) ReviewMarker(type: p.type, number: p.number),
    ];
    final manual = {
      for (var i = 0; i < points.length; i++)
        if (points[i].numberManual) i,
    };
    final nums = renumberStations(markers, manual: manual);
    final out = <DraftPoint>[];
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      if (p.type == PointType.station && p.number != nums[i]) {
        final changed = p.copyWith(number: nums[i]);
        await _store.savePoint(changed);
        out.add(changed);
      } else {
        out.add(p);
      }
    }
    return out;
  }

  /// „Neu messen“ (R3 aus R2): nur bis 100 m Abstand.
  Future<bool> remeasure(String pointId) async {
    final s = state;
    if (s == null || s.measuring) return false;
    DraftPoint? target;
    for (final p in s.points) {
      if (p.id == pointId) target = p;
    }
    final here = s.fix;
    if (target == null || here == null) return false;
    final d = distanceM(
      target.lat,
      target.lng,
      here.position.latitude,
      here.position.longitude,
    );
    if (d > 100) return false;
    state = s.copyWith(measuring: true, measureProgress: 0);
    final avg = await measurePoint(_location);
    final s2 = state;
    if (s2 == null) return false;
    state = s2.copyWith(measuring: false);
    if (avg == null) {
      _events.add(const RecorderEvent(RecorderEventType.noFix));
      return false;
    }
    await updatePoint(
      target.copyWith(
        lat: avg.lat,
        lng: avg.lng,
        accuracyM: avg.accuracyM,
        fixCount: avg.fixCount,
        lowAccuracy: avg.lowAccuracy,
      ),
    );
    return true;
  }

  // ── Pause, Beenden ───────────────────────────────────────────────

  Future<void> pause() async {
    final s = state;
    if (s == null) return;
    final next = nextDraftStatus(s.draft.status, DraftEvent.pause);
    if (next == null) return;
    await _flush();
    final draft = s.draft.copyWith(status: next);
    await _store.saveDraft(draft);
    state = s.copyWith(draft: draft);
    _touchDrafts();
  }

  Future<void> resumeAfterPause() async {
    final s = state;
    if (s == null) return;
    final next = nextDraftStatus(s.draft.status, DraftEvent.resume);
    if (next == null) return;
    // Neues Track-Segment, der erste Fix danach wird ohne
    // Geschwindigkeitsprüfung akzeptiert.
    _filter = _filter.nextSegment();
    final draft = s.draft.copyWith(status: next);
    await _store.saveDraft(draft);
    state = s.copyWith(draft: draft);
    _touchDrafts();
  }

  /// „Beenden und prüfen“: stoppt den Stream, erkennt den Rundweg oder legt
  /// einen Ende-Marker am letzten guten Fix an. Danach R4.
  Future<ReportDraft?> finish() async {
    final s = state;
    if (s == null) return null;
    await _flush();
    _stopStream();
    state = null;
    final draft = await _finalize(
      s.draft,
      s.points,
      segments.map((e) => List<TrackPoint>.of(e)).toList(),
    );
    segments.clear();
    _touchDrafts();
    return draft;
  }

  /// R15 „Prüfen und einreichen“ nach unterbrochener Aufnahme (S14).
  Future<ReportDraft?> finishStored(String draftId) async {
    final draft = await _store.load(draftId);
    if (draft == null) return null;
    final points = await _store.points(draftId);
    final fixes = await _store.fixes(draftId);
    final d = await _finalize(draft, points, segmentsFromFixes(fixes));
    _touchDrafts();
    return d;
  }

  Future<ReportDraft> _finalize(
    ReportDraft draft,
    List<DraftPoint> points,
    TrackSegments segs,
  ) async {
    final event = draft.status == DraftStatus.review
        ? null
        : DraftEvent.finishAndReview;
    final next = event == null
        ? DraftStatus.review
        : nextDraftStatus(draft.status, event) ?? DraftStatus.review;
    final loop = suggestLoopForTrack(segs, c: _c);
    final hasEnd = points.any((p) => p.type == PointType.end);
    final flat = [for (final s in segs) ...s];
    if (!loop && !hasEnd && flat.isNotEmpty && !_pointsOnly(draft)) {
      final last = flat.last;
      final seq = points.isEmpty
          ? 0
          : points.map((p) => p.seq).reduce((a, b) => a > b ? a : b) + 1;
      await _store.savePoint(
        DraftPoint(
          id: newReportId(),
          draftId: draft.id,
          type: PointType.end,
          seq: seq,
          lat: last.lat,
          lng: last.lng,
          accuracyM: last.accuracyM,
          fixCount: 1,
          lowAccuracy: last.accuracyM > _c.okMaxM,
          recordedOn: DateTime.now(),
        ),
      );
    }
    final out = draft.copyWith(
      status: next,
      isLoop: loop,
      justFinished: true,
      openedAt: DateTime.now(),
    );
    await _store.saveDraft(out);
    return out;
  }

  bool _pointsOnly(ReportDraft d) => d.mode == RecordingMode.pointsOnly;

  /// „Verwerfen“: Entwurf, Track und Fotos löschen.
  Future<void> discard() async {
    final s = state;
    _stopStream();
    state = null;
    segments.clear();
    _buffer.clear();
    if (s != null) await _store.deleteDraft(s.draft.id);
    _touchDrafts();
  }
}
