import 'dart:math' as math;

import 'track_layout.dart';
import 'track_style.dart';

/// Contour-Polylinie; [dashed] steuert Strichelung im Painter.
class ContourLine {
  final List<TrackPoint> points;
  final bool dashed;
  const ContourLine({required this.points, this.dashed = false});
}

/// Dekorative Offset-Konturen entlang der Route (kein DEM). 2B-fähig via Signatur.
List<ContourLine> buildContours(
  TrackLayout layout, {
  required int seed,
  List<double>? offsets,
}) {
  if (layout.isEmpty) return const [];
  final bands = offsets ?? TrackStyle.contourOffsets;
  final skeleton = layout.route;
  final closed = layout.closedLoop;
  final lines = <ContourLine>[];

  for (var i = 0; i < bands.length; i++) {
    final signed = i.isEven ? bands[i] : -bands[i];
    final pts = _offsetPolyline(
      skeleton,
      signed,
      seed: seed + i * 17,
      closed: closed,
    );
    if (pts.length >= 2) {
      lines.add(ContourLine(points: pts, dashed: i >= 2));
    }
  }
  return lines;
}

List<TrackPoint> _offsetPolyline(
  List<TrackPoint> pts,
  double distance, {
  required int seed,
  required bool closed,
}) {
  if (pts.length < 2) return const [];
  final n = pts.length;
  final out = <TrackPoint>[];

  for (var i = 0; i < n; i++) {
    final prev = pts[i == 0 ? (closed ? n - 2 : 0) : i - 1];
    final next = pts[i == n - 1 ? (closed ? 1 : n - 1) : i + 1];
    var tx = next.x - prev.x;
    var ty = next.y - prev.y;
    if (tx * tx + ty * ty < 1e-18) {
      final j = i < n - 1 ? i + 1 : i - 1;
      tx = pts[j].x - pts[i].x;
      ty = pts[j].y - pts[i].y;
    }
    final tLen = math.sqrt(tx * tx + ty * ty);
    if (tLen < 1e-9) {
      out.add(pts[i]);
      continue;
    }
    final nx = -ty / tLen;
    final ny = tx / tLen;
    final noise = _noise1d(seed, i) * (distance.abs() * 0.22);
    out.add(
      TrackPoint(
        pts[i].x + nx * (distance + noise),
        pts[i].y + ny * (distance + noise),
      ),
    );
  }
  if (closed && out.length >= 2) out.add(out.first);
  return out;
}

double _noise1d(int seed, int i) {
  var h = seed * 374761393 + i * 668265263;
  h = (h ^ (h >> 13)) * 1274126177;
  h ^= h >> 16;
  return ((h & 0xFFFF) / 0xFFFF) * 2 - 1;
}
