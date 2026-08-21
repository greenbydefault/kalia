import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:lehrpfad_app/features/trail/domain/station.dart';
import 'package:lehrpfad_app/features/trail/domain/trail.dart';
import 'package:lehrpfad_app/features/trail_progress/geo/polyline_metrics.dart';
import 'package:lehrpfad_app/features/trail_progress/geo/station_geofence.dart';
import 'package:lehrpfad_app/features/trail_progress/geo/walk_progress_evaluator.dart';

Trail _trail() {
  final route = [
    const LatLng(53.0, 8.0),
    const LatLng(53.0, 8.02),
  ];
  return Trail(
    id: 't1',
    name: 'Test',
    typ: 'natur',
    kurzbeschreibung: '',
    beschreibung: '',
    laengeKm: 1,
    dauerMin: 30,
    rundkurs: false,
    markierung: '',
    betreiber: '',
    region: '',
    anreise: '',
    startName: '',
    arten: const [],
    route: route,
    stationen: [
      Station(
        osmId: 1,
        position: const LatLng(53.0, 8.01),
        km: 0.5,
        reihenfolge: 1,
        titel: 'Mitte',
        thema: '',
        kurztext: '',
        erlebnisse: const [],
        barrierefrei: false,
      ),
    ],
    amenities: const [],
  );
}

void main() {
  test('station geofence marks visit', () {
    final trail = _trail();
    final metrics = PolylineMetrics.from(trail.route);
    final eval = evaluateWalkProgress(
      trail: trail,
      metrics: metrics,
      position: const LatLng(53.0, 8.01),
      visitedStationIds: {},
      stationRadiusM: 50,
    );
    expect(eval.newlyVisitedStationIds, contains(stationKey(trail.stationen.first)));
  });

  test('off-track when far from polyline', () {
    final trail = _trail();
    final metrics = PolylineMetrics.from(trail.route);
    final eval = evaluateWalkProgress(
      trail: trail,
      metrics: metrics,
      position: const LatLng(53.05, 8.05),
      visitedStationIds: {},
      offTrackThresholdM: 40,
    );
    expect(eval.offTrack, isTrue);
  });

  test('A→B am Ziel: kein Auto-Complete ohne Guard', () {
    final trail = _trail();
    final metrics = PolylineMetrics.from(trail.route);
    final started = DateTime.utc(2026, 1, 1, 12);
    final eval = evaluateWalkProgress(
      trail: trail,
      metrics: metrics,
      position: const LatLng(53.0, 8.02),
      visitedStationIds: {},
      startedAt: started,
      now: started.add(const Duration(seconds: 10)),
    );
    expect(eval.progressRatio, greaterThan(0.9));
    expect(eval.shouldAutoComplete, isFalse);
  });

  test('A→B am Ziel: Auto-Complete nach Mindestdauer', () {
    final trail = _trail();
    final metrics = PolylineMetrics.from(trail.route);
    final started = DateTime.utc(2026, 1, 1, 12);
    final eval = evaluateWalkProgress(
      trail: trail,
      metrics: metrics,
      position: const LatLng(53.0, 8.02),
      visitedStationIds: {},
      startedAt: started,
      now: started.add(const Duration(minutes: 3)),
    );
    expect(eval.shouldAutoComplete, isTrue);
  });

  test('Fläche: kein Off-Track, Progress über Stationen', () {
    final trail = Trail(
      id: 'f1',
      name: 'Platz',
      typ: 'waldspielplatz',
      form: 'flaeche',
      kurzbeschreibung: '',
      beschreibung: '',
      laengeKm: 0,
      dauerMin: 20,
      rundkurs: false,
      markierung: '',
      betreiber: '',
      region: '',
      anreise: '',
      startName: '',
      arten: const [],
      area: const [
        LatLng(53.0, 8.0),
        LatLng(53.0, 8.01),
        LatLng(53.01, 8.01),
        LatLng(53.01, 8.0),
      ],
      stationen: [
        Station(
          osmId: 1,
          position: const LatLng(53.005, 8.005),
          km: 0,
          reihenfolge: 1,
          titel: 'Pumpe',
          thema: '',
          kurztext: '',
          erlebnisse: const [],
          barrierefrei: false,
        ),
      ],
      amenities: const [],
    );
    final eval = evaluateWalkProgress(
      trail: trail,
      metrics: PolylineMetrics.from(const []),
      position: const LatLng(54.0, 9.0),
      visitedStationIds: {},
    );
    expect(eval.offTrack, isFalse);
    expect(eval.progressRatio, 0);
    expect(eval.shouldAutoComplete, isFalse);
  });
}
