import 'package:latlong2/latlong.dart';

import '../../trail/domain/haversine.dart';

export '../../trail/domain/haversine.dart';

/// Vorberechnete Segmentlängen und kumulierte Distanz einer Polyline.
class PolylineMetrics {
  PolylineMetrics._({
    required this.points,
    required this.segmentLengthsM,
    required this.cumDistM,
    required this.totalLengthM,
  });

  final List<LatLng> points;
  final List<double> segmentLengthsM;
  final List<double> cumDistM;
  final double totalLengthM;

  factory PolylineMetrics.from(List<LatLng> route) {
    if (route.length < 2) {
      return PolylineMetrics._(
        points: List.unmodifiable(route),
        segmentLengthsM: const [],
        cumDistM: route.isEmpty ? const [] : const [0],
        totalLengthM: 0,
      );
    }
    final segments = <double>[];
    final cum = <double>[0];
    var total = 0.0;
    for (var i = 0; i < route.length - 1; i++) {
      final d = haversineMeters(route[i], route[i + 1]);
      segments.add(d);
      total += d;
      cum.add(total);
    }
    return PolylineMetrics._(
      points: List.unmodifiable(route),
      segmentLengthsM: List.unmodifiable(segments),
      cumDistM: List.unmodifiable(cum),
      totalLengthM: total,
    );
  }

  /// Punkte bis [alongTrackM] inkl. interpoliertem Endpunkt.
  List<LatLng> prefixUntil(double alongTrackM) {
    if (points.isEmpty) return const [];
    if (alongTrackM <= 0) return [points.first];
    if (alongTrackM >= totalLengthM) return List.of(points);

    final out = <LatLng>[points.first];
    for (var i = 0; i < segmentLengthsM.length; i++) {
      final segEnd = cumDistM[i + 1];
      if (segEnd < alongTrackM) {
        out.add(points[i + 1]);
        continue;
      }
      final segStart = cumDistM[i];
      final segLen = segmentLengthsM[i];
      if (segLen <= 0) {
        out.add(points[i + 1]);
        break;
      }
      final t = ((alongTrackM - segStart) / segLen).clamp(0.0, 1.0);
      out.add(_lerp(points[i], points[i + 1], t));
      break;
    }
    return out;
  }

  /// Rest ab [alongTrackM].
  List<LatLng> suffixFrom(double alongTrackM) {
    if (points.isEmpty) return const [];
    if (alongTrackM <= 0) return List.of(points);
    if (alongTrackM >= totalLengthM) return [points.last];

    for (var i = 0; i < segmentLengthsM.length; i++) {
      final segEnd = cumDistM[i + 1];
      if (segEnd < alongTrackM) continue;
      final segStart = cumDistM[i];
      final segLen = segmentLengthsM[i];
      final t = segLen <= 0
          ? 1.0
          : ((alongTrackM - segStart) / segLen).clamp(0.0, 1.0);
      final start = _lerp(points[i], points[i + 1], t);
      return [start, ...points.sublist(i + 1)];
    }
    return [points.last];
  }
}

LatLng _lerp(LatLng a, LatLng b, double t) => LatLng(
  a.latitude + (b.latitude - a.latitude) * t,
  a.longitude + (b.longitude - a.longitude) * t,
);
