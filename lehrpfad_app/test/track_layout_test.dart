import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:lehrpfad_app/features/trail/domain/station.dart';
import 'package:lehrpfad_app/features/trail/track_engine/track_layout.dart';
import 'package:lehrpfad_app/features/trail/track_engine/track_style.dart';

void main() {
  final route = <LatLng>[
    for (var i = 0; i < 40; i++) LatLng(51.8 + i * 0.001, 14.0 + i * 0.0008),
  ];

  Station stationAt(LatLng p, int n) => Station(
    osmId: n,
    position: p,
    km: n.toDouble(),
    reihenfolge: n,
    titel: 'S$n',
    thema: 't',
    kurztext: 'k',
    erlebnisse: const [],
    barrierefrei: false,
  );

  test('Fit: projizierte Punkte liegen im Viewport mit Padding', () {
    const w = 320.0;
    const h = TrackStyle.height;
    final layout = TrackLayout.build(
      route: route,
      stations: [stationAt(route[10], 1), stationAt(route[25], 2)],
      width: w,
      height: h,
      rundkurs: false,
    );

    expect(layout.isEmpty, isFalse);
    final pad = TrackStyle.padding;
    for (final p in layout.route) {
      expect(p.x, inInclusiveRange(pad - 0.5, w - pad + 0.5));
      expect(p.y, inInclusiveRange(pad - 0.5, h - pad + 0.5));
    }
    for (final s in layout.stations) {
      expect(s.point.x, inInclusiveRange(0, w));
      expect(s.point.y, inInclusiveRange(0, h));
    }
  });

  test('Hit-Test: Station trifft, weiter Weg nicht', () {
    final layout = TrackLayout.build(
      route: route,
      stations: [stationAt(route[10], 1)],
      width: 320,
      height: TrackStyle.height,
      rundkurs: false,
    );
    final target = layout.stations.first.point;
    expect(layout.hitTest(target), isNotNull);
    expect(layout.hitTest(target)!.osmId, 1);
    expect(layout.hitTest(const TrackPoint(0, 0)), isNull);
  });

  test('Simplify: lange Polyline wird kürzer, Endpunkte bleiben', () {
    final long = <LatLng>[
      for (var i = 0; i < 500; i++) LatLng(52 + i * 0.0001, 13 + i * 0.0001),
    ];
    final simplified = simplifyPolyline(
      long,
      targetCount: TrackStyle.simplifyTarget,
    );
    expect(simplified.length, lessThan(long.length));
    expect(simplified.length, lessThanOrEqualTo(TrackStyle.simplifyTarget));
    expect(simplified.first, long.first);
    expect(simplified.last, long.last);
  });

  test('Leere Route liefert leeres Layout', () {
    final layout = TrackLayout.build(
      route: const [],
      stations: const [],
      width: 200,
      height: 200,
      rundkurs: false,
    );
    expect(layout.isEmpty, isTrue);
  });
}
