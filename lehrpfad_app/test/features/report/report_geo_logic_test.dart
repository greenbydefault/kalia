import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/features/report/logic/averaging.dart';
import 'package:lehrpfad_app/features/report/logic/deviation.dart';
import 'package:lehrpfad_app/features/report/logic/geo.dart';
import 'package:lehrpfad_app/features/report/logic/track_filter.dart';
import 'package:lehrpfad_app/features/report/logic/track_metrics.dart';

/// Meter pro Breitengrad mit dem Erdradius der Spec.
const _mPerDegLat = earthRadiusM * 3.141592653589793 / 180;

double _north(double lat, double m) => lat + m / _mPerDegLat;

void main() {
  group('averageFixes (13.1)', () {
    test('A1: gleiche Genauigkeit, Mittel der Koordinaten', () {
      final r = averageFixes(const [
        Fix(52.0000, 13.0000, 10),
        Fix(52.0002, 13.0002, 10),
        Fix(52.0001, 13.0001, 10),
      ])!;
      expect(r.lat, closeTo(52.0001, 0.00001));
      expect(r.lng, closeTo(13.0001, 0.00001));
      expect(r.accuracyM, closeTo(5.8, 0.1));
      expect(r.fixCount, 3);
      expect(r.lowAccuracy, isFalse);
    });

    test('A2: Gewichtung nach 1/Genauigkeit², Fix mit 30 m zählt noch', () {
      final r = averageFixes(const [
        Fix(52.0000, 13.0000, 5),
        Fix(52.0010, 13.0000, 5),
        Fix(52.0100, 13.0000, 30),
      ])!;
      expect(r.lat, closeTo(52.00063, 0.00001));
      expect(r.lng, closeTo(13.0, 0.00001));
      expect(r.accuracyM, closeTo(3.5, 0.1));
      expect(r.fixCount, 3);
    });

    test('A3: weniger als 3 brauchbare Fixes, bester Einzel-Fix', () {
      final r = averageFixes(const [Fix(52.0, 13.0, 12), Fix(52.1, 13.1, 10)])!;
      expect(r.accuracyM, closeTo(10, 0.1));
      expect(r.lat, 52.1);
      expect(r.fixCount, 1);
      expect(r.lowAccuracy, isFalse);
    });

    test('A4: nur schwache Fixes, lowAccuracy', () {
      final r = averageFixes(const [Fix(52.0, 13.0, 45), Fix(52.1, 13.1, 40)])!;
      expect(r.accuracyM, closeTo(40, 0.1));
      expect(r.fixCount, 1);
      expect(r.lowAccuracy, isTrue);
    });

    test('keine Fixes: Messung bricht ab (Z6)', () {
      expect(averageFixes(const []), isNull);
    });

    test('Mittelung endet nach 3 s mit 3 Fixes, spätestens nach 8 s', () {
      expect(averagingDone(elapsedS: 2.9, usableFixes: 5), isFalse);
      expect(averagingDone(elapsedS: 3, usableFixes: 2), isFalse);
      expect(averagingDone(elapsedS: 3, usableFixes: 3), isTrue);
      expect(averagingDone(elapsedS: 8, usableFixes: 0), isTrue);
    });
  });

  group('filterTrackFix (13.1, letzter Punkt bei t = 0 s)', () {
    final t0 = DateTime.utc(2026, 10, 17, 12);
    const lat = 52.0;
    const lng = 13.0;

    TrackFilterState seeded() => filterTrackFix(
      state: const TrackFilterState(),
      fix: RawFix(lat, lng, 5, t0),
      paused: false,
    ).state;

    RawFix fixAt(double metersNorth, int seconds, {double acc = 5}) => RawFix(
      _north(lat, metersNorth),
      lng,
      acc,
      t0.add(Duration(seconds: seconds)),
    );

    test('erster Fix wird gespeichert', () {
      final r = filterTrackFix(
        state: const TrackFilterState(),
        fix: RawFix(lat, lng, 5, t0),
        paused: false,
      );
      expect(r.accepted, isTrue);
    });

    test('F1: 30 m in 2 s (15 m/s) wird verworfen', () {
      final r = filterTrackFix(
        state: seeded(),
        fix: fixAt(30, 2),
        paused: false,
      );
      expect(r.rejected, FilterReject.tooFast);
    });

    test('F2: 5 m in 2 s (2,5 m/s), Genauigkeit 12, gespeichert', () {
      final r = filterTrackFix(
        state: seeded(),
        fix: fixAt(5, 2, acc: 12),
        paused: false,
      );
      expect(r.accepted, isTrue);
    });

    test('F3: 3 m entfernt, verworfen (unter 4 m)', () {
      final r = filterTrackFix(
        state: seeded(),
        fix: fixAt(3, 2),
        paused: false,
      );
      expect(r.rejected, FilterReject.tooClose);
    });

    test('F4: Genauigkeit 31 verworfen, 30 gespeichert', () {
      final bad = filterTrackFix(
        state: seeded(),
        fix: fixAt(10, 4, acc: 31),
        paused: false,
      );
      final ok = filterTrackFix(
        state: seeded(),
        fix: fixAt(10, 4, acc: 30),
        paused: false,
      );
      expect(bad.rejected, FilterReject.inaccurate);
      expect(ok.accepted, isTrue);
    });

    test('F5: Status paused verwirft', () {
      final r = filterTrackFix(
        state: seeded(),
        fix: fixAt(10, 4),
        paused: true,
      );
      expect(r.rejected, FilterReject.paused);
    });

    test('F6: seit 20 s unter 0,3 m/s verworfen, bis wieder schneller', () {
      var state = seeded();
      FilterResult? atTwenty;
      // Kriechen mit 0,21 m/s: alle 2 s 0,42 m.
      for (var k = 1; k <= 10; k++) {
        final r = filterTrackFix(
          state: state,
          fix: fixAt(0.42 * k, 2 * k),
          paused: false,
        );
        state = r.state;
        if (k == 10) atTwenty = r;
      }
      // 4,2 m vom letzten Punkt, aber 20 s langsam
      expect(atTwenty!.rejected, FilterReject.stationary);

      // Wieder schneller (3,75 m/s von Fix zu Fix): gespeichert
      final moving = filterTrackFix(
        state: state,
        fix: fixAt(12, 22),
        paused: false,
      );
      expect(moving.accepted, isTrue);
    });

    test('F7: erster Fix nach Pause 400 m entfernt, neues Segment', () {
      final afterPause = seeded().nextSegment();
      final r = filterTrackFix(
        state: afterPause,
        fix: fixAt(400, 120),
        paused: false,
      );
      expect(r.accepted, isTrue);
      expect(r.state.segment, 1);
    });
  });

  group('Länge und Rundweg (13.1)', () {
    TrackPoint p(double lat, double lng) => TrackPoint(lat, lng);

    test('L1: 111,2 m, ein Segment', () {
      final len = trackLengthM([
        [p(52.0000, 13.0000), p(52.0010, 13.0000)],
      ]);
      expect(len, closeTo(111.2, 0.5));
    });

    test('L2: zwei Segmente, Lücke zählt nicht', () {
      final len = trackLengthM([
        [p(52.0000, 13.0000)],
        [p(52.0010, 13.0000)],
      ]);
      expect(len, 0);
    });

    test('L3: 179,7 m (±1 m)', () {
      final len = trackLengthM([
        [p(52.0000, 13.0000), p(52.0010, 13.0000), p(52.0010, 13.0010)],
      ]);
      expect(len, closeTo(179.7, 1));
    });

    test('R1: Abstand 40 m, Länge 500 m = Rundweg', () {
      expect(suggestLoop(startEndGapM: 40, lengthM: 500), isTrue);
    });

    test('R2: Abstand 60 m = kein Rundweg', () {
      expect(suggestLoop(startEndGapM: 60, lengthM: 500), isFalse);
    });

    test('R3: Länge 250 m = kein Rundweg', () {
      expect(suggestLoop(startEndGapM: 10, lengthM: 250), isFalse);
    });

    test('Rundweg aus dem Track: Start gleich Ende, 500 m', () {
      final seg = [
        p(52.0, 13.0),
        p(_north(52.0, 250), 13.0),
        p(_north(52.0, 5), 13.0),
        p(_north(52.0, 255), 13.0),
        p(_north(52.0, 10), 13.0),
      ];
      expect(suggestLoopForTrack([seg]), isTrue);
    });

    test('Marker-Kette (Nur Punkte): Luftlinien in Reihenfolge', () {
      final len = markerChainLengthM([
        p(52.0000, 13.0),
        p(52.0010, 13.0),
        p(52.0020, 13.0),
      ]);
      expect(len, closeTo(222.4, 1));
    });

    test('größte Lücke: zwischen Segmenten', () {
      final gap = largestGapM([
        [p(52.0000, 13.0), p(_north(52.0, 10), 13.0)],
        [p(_north(52.0, 110), 13.0), p(_north(52.0, 120), 13.0)],
      ]);
      expect(gap, closeTo(100, 0.5));
    });
  });

  group('trimTrack (Kürzen in R4)', () {
    TrackSegments line() => [
      [for (var i = 0; i <= 10; i++) TrackPoint(_north(52.0, 100.0 * i), 13.0)],
    ];

    test('ohne Kürzen unverändert', () {
      final t = trimTrack(line());
      expect(trackLengthM(t), closeTo(1000, 0.5));
    });

    test('Anfang 250 m und Ende 130 m: Länge 620 m, Schnitt interpoliert', () {
      final t = trimTrack(line(), startM: 250, endM: 130);
      expect(trackLengthM(t), closeTo(620, 0.5));
      expect(t.first.first.lat, closeTo(_north(52.0, 250), 1e-7));
      expect(t.last.last.lat, closeTo(_north(52.0, 870), 1e-7));
    });

    test('alles gekürzt = leer', () {
      expect(trimTrack(line(), startM: 600, endM: 600), isEmpty);
    });

    test('Segmente bleiben getrennt, Lücke zählt nicht', () {
      final segs = [
        [TrackPoint(52.0, 13.0), TrackPoint(_north(52.0, 100), 13.0)],
        [
          TrackPoint(_north(52.0, 500), 13.0),
          TrackPoint(_north(52.0, 600), 13.0),
        ],
      ];
      final t = trimTrack(segs, startM: 150);
      expect(t.length, 1);
      expect(trackLengthM(t), closeTo(50, 0.5));
    });
  });

  group('Abweichung, Konsens, Anwesenheit (13.1)', () {
    test('K1: unter 20 m ist noise', () {
      expect(classifyDeviation(12), DeviationClass.noise);
      expect(classifyDeviation(19.9), DeviationClass.noise);
    });

    test('K2: 20 bis unter 25 m ist borderline', () {
      expect(classifyDeviation(20), DeviationClass.borderline);
      expect(classifyDeviation(24.9), DeviationClass.borderline);
    });

    test('K3: ab 25 m ist candidate', () {
      expect(classifyDeviation(25), DeviationClass.candidate);
      expect(classifyDeviation(200), DeviationClass.candidate);
    });

    ReportPos pos(String user, double lat, {String target = 'p1'}) =>
        ReportPos(userId: user, targetPointId: target, lat: lat, lng: 13.0);

    test('C1: A und B, 18 m auseinander, Konsens', () {
      expect(isConsensus(pos('A', 52.0), pos('B', _north(52.0, 18))), isTrue);
    });

    test('C2: 40 m auseinander, kein Konsens', () {
      expect(isConsensus(pos('A', 52.0), pos('B', _north(52.0, 40))), isFalse);
    });

    test('C3: genau 25,0 m, Konsens', () {
      expect(isConsensus(pos('A', 52.0), pos('B', _north(52.0, 25))), isTrue);
    });

    test('C4: derselbe Nutzer zweimal, kein Konsens', () {
      expect(isConsensus(pos('A', 52.0), pos('A', _north(52.0, 18))), isFalse);
    });

    test('C5: verschiedene Zielpunkte, kein Konsens', () {
      expect(
        isConsensus(pos('A', 52.0), pos('B', _north(52.0, 18), target: 'p2')),
        isFalse,
      );
    });

    test('P1: 480 m / 500 m erlaubt, 520 m nicht', () {
      expect(mayReport(480), isTrue);
      expect(mayReport(500), isTrue);
      expect(mayReport(520), isFalse);
    });
  });
}
