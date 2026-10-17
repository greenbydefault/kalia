import '../report_config.dart';
import 'geo.dart';

/// Roher Fix aus dem Stream. Der Zeitstempel bleibt lokal.
class RawFix {
  const RawFix(this.lat, this.lng, this.accuracyM, this.t);

  final double lat;
  final double lng;
  final double accuracyM;
  final DateTime t;
}

enum FilterReject { paused, inaccurate, tooFast, tooClose, stationary }

/// Zustand des Track-Filters. Unveränderlich, jeder Fix liefert einen neuen.
class TrackFilterState {
  const TrackFilterState({
    this.segment = 0,
    this.lastAccepted,
    this.lastRaw,
    this.slowSince,
  });

  /// Aktuelles Segment. Wächst nach jeder Pause.
  final int segment;

  /// Letzter gespeicherter Punkt im aktuellen Segment.
  final RawFix? lastAccepted;

  /// Letzter Fix, der Schritt 1 bis 3 bestanden hat (für die Geschwindigkeit).
  final RawFix? lastRaw;

  /// Seit wann die Geschwindigkeit unter `stationarySpeedMps` liegt.
  final DateTime? slowSince;

  /// Nach einer Pause beginnt ein neues Segment. Der erste Fix danach wird
  /// ohne Geschwindigkeitsprüfung akzeptiert.
  TrackFilterState nextSegment() => TrackFilterState(segment: segment + 1);
}

class FilterResult {
  const FilterResult(this.state, {this.rejected});

  final TrackFilterState state;

  /// `null` = gespeichert.
  final FilterReject? rejected;

  bool get accepted => rejected == null;
}

/// Track-Filter in genau der Reihenfolge von Spec 6.3. Der Track wird nicht
/// geglättet, die Vereinfachung macht der Server.
FilterResult filterTrackFix({
  required TrackFilterState state,
  required RawFix fix,
  required bool paused,
  ReportConfig c = cfg,
}) {
  // 1. Status paused
  if (paused) return FilterResult(state, rejected: FilterReject.paused);

  // 2. Genauigkeit
  if (fix.accuracyM > c.trackFixMaxAccM) {
    return FilterResult(state, rejected: FilterReject.inaccurate);
  }

  final last = state.lastAccepted;
  double? distToLast;
  if (last != null) {
    distToLast = distanceM(last.lat, last.lng, fix.lat, fix.lng);
    // 3. Sprung: Geschwindigkeit zum letzten gespeicherten Punkt
    final dt = fix.t.difference(last.t).inMilliseconds / 1000;
    final speed = distToLast / (dt > 0.001 ? dt : 0.001);
    if (speed > c.trackMaxSpeedMps) {
      return FilterResult(state, rejected: FilterReject.tooFast);
    }
  }

  // Stehen: Geschwindigkeit von Fix zu Fix. Wird für jeden Fix gepflegt,
  // der Schritt 3 bestanden hat, auch wenn er in Schritt 4 verworfen wird.
  var slowSince = state.slowSince;
  final raw = state.lastRaw;
  if (raw != null) {
    final dt = fix.t.difference(raw.t).inMilliseconds / 1000;
    if (dt > 0) {
      final v = distanceM(raw.lat, raw.lng, fix.lat, fix.lng) / dt;
      slowSince = v < c.stationarySpeedMps ? (slowSince ?? raw.t) : null;
    }
  }
  final next = TrackFilterState(
    segment: state.segment,
    lastAccepted: last,
    lastRaw: fix,
    slowSince: slowSince,
  );

  // 4. Mindestabstand
  if (distToLast != null && distToLast < c.trackMinDistM) {
    return FilterResult(next, rejected: FilterReject.tooClose);
  }

  // 5. Stehen seit mindestens stationaryHoldS
  if (slowSince != null &&
      fix.t.difference(slowSince).inSeconds >= c.stationaryHoldS) {
    return FilterResult(next, rejected: FilterReject.stationary);
  }

  return FilterResult(
    TrackFilterState(
      segment: state.segment,
      lastAccepted: fix,
      lastRaw: fix,
      slowSince: slowSince,
    ),
  );
}
