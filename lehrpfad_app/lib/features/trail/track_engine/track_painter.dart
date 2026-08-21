import 'package:flutter/material.dart';

import '../domain/station.dart';
import 'terrain_contours.dart';
import 'track_layout.dart';
import 'track_style.dart';

/// Terrain → Track → Start/A-B → Stationen.
class TrackPainter extends CustomPainter {
  final TrackLayout layout;
  final List<ContourLine> contours;
  final Station? selected;
  final Color stationFill;
  final Color stationSelected;
  final List<TextPainter> labelPainters;
  final bool showAbEndpoints;

  TrackPainter({
    required this.layout,
    required this.contours,
    required this.selected,
    required this.stationFill,
    required this.stationSelected,
    required this.labelPainters,
    this.showAbEndpoints = false,
  });

  static List<TextPainter> buildLabelPainters(
    TrackLayout layout, {
    required Color color,
  }) => [
    for (final s in layout.stations)
      TextPainter(
        text: TextSpan(
          text: '${s.station.reihenfolge}',
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = TrackStyle.background);
    if (layout.isEmpty) return;

    final contourPaint = Paint()
      ..color = TrackStyle.contour
      ..style = PaintingStyle.stroke
      ..strokeWidth = TrackStyle.contourWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final line in contours) {
      final path = _pathFrom(line.points);
      canvas.drawPath(line.dashed ? _dashPath(path) : path, contourPaint);
    }

    canvas.drawPath(
      _pathFrom(layout.route),
      Paint()
        ..color = TrackStyle.track
        ..style = PaintingStyle.stroke
        ..strokeWidth = TrackStyle.trackWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final start = layout.route.first;
    if (!showAbEndpoints) {
      canvas.drawCircle(
        Offset(start.x, start.y),
        TrackStyle.startRadius,
        Paint()..color = TrackStyle.track,
      );
    }

    for (var i = 0; i < layout.stations.length; i++) {
      final marker = layout.stations[i];
      final center = Offset(marker.point.x, marker.point.y);
      final fill = selected?.osmId == marker.station.osmId
          ? stationSelected
          : stationFill;
      canvas.drawCircle(
        center,
        TrackStyle.stationRadius,
        Paint()..color = fill,
      );
      canvas.drawCircle(
        center,
        TrackStyle.stationRadius,
        Paint()
          ..color = TrackStyle.stationBorder
          ..style = PaintingStyle.stroke
          ..strokeWidth = TrackStyle.stationBorderWidth,
      );
      if (i < labelPainters.length) {
        final tp = labelPainters[i];
        tp.paint(
          canvas,
          Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
        );
      }
    }

    if (showAbEndpoints) {
      _paintLetter(canvas, Offset(start.x, start.y), 'A', inverted: false);
      final end = layout.route.last;
      _paintLetter(canvas, Offset(end.x, end.y), 'B', inverted: true);
    }
  }

  static void _paintLetter(
    Canvas canvas,
    Offset center,
    String letter, {
    required bool inverted,
  }) {
    final fill = inverted ? TrackStyle.stationBorder : TrackStyle.track;
    final fg = inverted ? TrackStyle.track : TrackStyle.stationBorder;
    canvas.drawCircle(center, TrackStyle.stationRadius, Paint()..color = fill);
    if (inverted) {
      canvas.drawCircle(
        center,
        TrackStyle.stationRadius,
        Paint()
          ..color = TrackStyle.track
          ..style = PaintingStyle.stroke
          ..strokeWidth = TrackStyle.stationBorderWidth,
      );
    }
    final tp = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          color: fg,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  static Path _pathFrom(List<TrackPoint> pts) {
    final path = Path();
    if (pts.isEmpty) return path;
    path.moveTo(pts.first.x, pts.first.y);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].x, pts[i].y);
    }
    return path;
  }

  static Path _dashPath(Path source, {double dash = 6, double gap = 5}) {
    final out = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      while (distance < metric.length) {
        final next = distance + (draw ? dash : gap);
        if (draw) {
          out.addPath(
            metric.extractPath(distance, next.clamp(0, metric.length)),
            Offset.zero,
          );
        }
        distance = next;
        draw = !draw;
      }
    }
    return out;
  }

  @override
  bool shouldRepaint(covariant TrackPainter old) =>
      old.layout != layout ||
      old.contours != contours ||
      old.selected?.osmId != selected?.osmId ||
      old.stationFill != stationFill ||
      old.stationSelected != stationSelected ||
      old.showAbEndpoints != showAbEndpoints;
}
