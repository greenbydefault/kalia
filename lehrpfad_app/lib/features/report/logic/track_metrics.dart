import 'dart:math' as math;

import '../report_config.dart';
import 'geo.dart';

/// Länge = Summe der Haversine-Abstände zwischen aufeinanderfolgenden
/// Punkten desselben Segments. Lücken zwischen Segmenten zählen nicht
/// (Spec 6.5).
double trackLengthM(TrackSegments segments) {
  var sum = 0.0;
  for (final seg in segments) {
    for (var i = 1; i < seg.length; i++) {
      sum += seg[i - 1].distanceTo(seg[i]);
    }
  }
  return sum;
}

/// Modus „Nur Punkte“: Summe der Luftlinien zwischen den Markern in
/// Erfassungsreihenfolge. Wird mit „ungefähr“ angezeigt.
double markerChainLengthM(List<TrackPoint> markersInOrder) {
  var sum = 0.0;
  for (var i = 1; i < markersInOrder.length; i++) {
    sum += markersInOrder[i - 1].distanceTo(markersInOrder[i]);
  }
  return sum;
}

/// Rundweg vorgeschlagen, wenn Start und Ende höchstens `loopMaxGapM`
/// auseinander liegen und die Länge mindestens `loopMinLengthM` beträgt.
bool suggestLoop({
  required double startEndGapM,
  required double lengthM,
  ReportConfig c = cfg,
}) => startEndGapM <= c.loopMaxGapM && lengthM >= c.loopMinLengthM;

/// Rundweg-Erkennung direkt aus dem Track (erster und letzter Punkt).
bool suggestLoopForTrack(TrackSegments segments, {ReportConfig c = cfg}) {
  final points = [for (final s in segments) ...s];
  if (points.length < 2) return false;
  return suggestLoop(
    startEndGapM: points.first.distanceTo(points.last),
    lengthM: trackLengthM(segments),
    c: c,
  );
}

/// Größte Lücke im Track in Metern: zwischen Segmenten (z. B. nach einer
/// Pause) und zwischen aufeinanderfolgenden Punkten eines Segments.
double largestGapM(TrackSegments segments) {
  var maxGap = 0.0;
  TrackPoint? prev;
  for (final seg in segments) {
    for (final p in seg) {
      if (prev != null) maxGap = math.max(maxGap, prev.distanceTo(p));
      prev = p;
    }
  }
  return maxGap;
}

/// Gekürzter Track (R4 „Kürzen“): schneidet am Anfang und am Ende die
/// gewählten Meter ab, entlang des Tracks gemessen. Der Schnittpunkt wird
/// auf der Strecke interpoliert. Marker bleiben unverändert.
///
/// Gekürzte Teile verlassen das Gerät nie (Spec 7.3), dieses Ergebnis ist
/// der Upload-Track.
TrackSegments trimTrack(
  TrackSegments segments, {
  double startM = 0,
  double endM = 0,
}) {
  final total = trackLengthM(segments);
  final from = math.max(0.0, startM);
  final to = total - math.max(0.0, endM);
  if (from <= 0 && endM <= 0) {
    return [for (final s in segments) List<TrackPoint>.of(s)];
  }
  if (to <= from) return const [];

  final out = <List<TrackPoint>>[];
  var travelled = 0.0;
  for (final seg in segments) {
    final kept = <TrackPoint>[];
    if (seg.length == 1) {
      if (travelled >= from && travelled <= to) kept.add(seg.first);
    }
    for (var i = 1; i < seg.length; i++) {
      final a = seg[i - 1];
      final b = seg[i];
      final len = a.distanceTo(b);
      final s0 = travelled;
      final s1 = travelled + len;
      travelled = s1;
      if (s1 < from || s0 > to) continue;
      final startFrac = len == 0 ? 0.0 : (math.max(from, s0) - s0) / len;
      final endFrac = len == 0 ? 1.0 : (math.min(to, s1) - s0) / len;
      final pa = _lerp(a, b, startFrac);
      final pb = _lerp(a, b, endFrac);
      if (kept.isEmpty || kept.last != pa) kept.add(pa);
      if (kept.last != pb) kept.add(pb);
    }
    if (kept.isNotEmpty) out.add(kept);
  }
  return out;
}

TrackPoint _lerp(TrackPoint a, TrackPoint b, double t) {
  if (t <= 0) return a;
  if (t >= 1) return b;
  return TrackPoint(
    a.lat + (b.lat - a.lat) * t,
    a.lng + (b.lng - a.lng) * t,
    math.max(a.accuracyM, b.accuracyM),
  );
}

/// Anzahl der Punkte über alle Segmente.
int trackPointCount(TrackSegments segments) =>
    segments.fold(0, (n, s) => n + s.length);
