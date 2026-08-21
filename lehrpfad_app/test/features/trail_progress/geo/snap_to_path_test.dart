import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:lehrpfad_app/features/trail_progress/geo/polyline_metrics.dart';
import 'package:lehrpfad_app/features/trail_progress/geo/snap_to_path.dart';

void main() {
  final route = [
    const LatLng(53.0, 8.0),
    const LatLng(53.0, 8.01),
    const LatLng(53.01, 8.01),
  ];

  test('nearest point snaps onto segment', () {
    final metrics = PolylineMetrics.from(route);
    final off = const LatLng(53.0005, 8.005);
    final snap = nearestPointOnPolyline(off, metrics);
    expect(snap.distanceToPathM, lessThan(80));
    expect(snap.alongTrackM, greaterThan(0));
    expect(snap.alongTrackM, lessThan(metrics.totalLengthM));
  });

  test('prefix and suffix split route', () {
    final metrics = PolylineMetrics.from(route);
    final mid = metrics.totalLengthM / 2;
    final done = metrics.prefixUntil(mid);
    final rest = metrics.suffixFrom(mid);
    expect(done.length, greaterThanOrEqualTo(2));
    expect(rest.length, greaterThanOrEqualTo(2));
    expect(done.first, route.first);
    expect(rest.last, route.last);
  });
}
