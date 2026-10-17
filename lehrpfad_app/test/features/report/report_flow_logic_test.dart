import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/features/report/domain/report_enums.dart';
import 'package:lehrpfad_app/features/report/logic/draft_transitions.dart';
import 'package:lehrpfad_app/features/report/logic/permission_logic.dart';
import 'package:lehrpfad_app/features/report/logic/quick_result.dart';
import 'package:lehrpfad_app/features/report/logic/review_logic.dart';
import 'package:lehrpfad_app/features/report/logic/signal.dart';

PermSnapshot _snap({
  bool service = true,
  ReportPermission permission = ReportPermission.whileInUse,
  bool precise = true,
}) => PermSnapshot(
  serviceEnabled: service,
  permission: permission,
  precise: precise,
);

void main() {
  group('Modus-Entscheidung (13.2, M1 bis M4)', () {
    test('M1: beim Verwenden, genau, Dienst startet: trackAndPoints', () {
      final d = decideRecordingMode(permission: _snap(), serviceStarted: true);
      expect(d.mode, RecordingMode.trackAndPoints);
    });

    test('M2: Dienststart fehlgeschlagen: pointsOnly', () {
      final d = decideRecordingMode(permission: _snap(), serviceStarted: false);
      expect(d.mode, RecordingMode.pointsOnly);
    });

    test('Benachrichtigung unter Android 13 abgelehnt: pointsOnly', () {
      final d = decideRecordingMode(
        permission: _snap(),
        serviceStarted: true,
        notificationsDenied: true,
      );
      expect(d.mode, RecordingMode.pointsOnly);
    });

    test('M3: nur ungefähr, gesperrt, R14 „Genau nötig“', () {
      final d = decideRecordingMode(
        permission: _snap(precise: false),
        serviceStarted: true,
      );
      expect(d.isBlocked, isTrue);
      expect(d.blockedBy, PermVariant.precise);
    });

    test('M4: abgelehnt oder nicht erteilt, R14 passend', () {
      PermVariant? v(ReportPermission p) => decideRecordingMode(
        permission: _snap(permission: p),
        serviceStarted: true,
      ).blockedBy;
      expect(v(ReportPermission.notDetermined), PermVariant.pre);
      expect(v(ReportPermission.denied), PermVariant.denied);
      expect(v(ReportPermission.deniedForever), PermVariant.settings);
    });

    test('Dienst aus hat Vorrang (Prüfreihenfolge 3.4)', () {
      final d = decideRecordingMode(
        permission: _snap(
          service: false,
          permission: ReportPermission.denied,
          precise: false,
        ),
        serviceStarted: true,
      );
      expect(d.blockedBy, PermVariant.off);
    });
  });

  group('Übergänge des Entwurfs (13.2, S1 bis S14)', () {
    void expectStep(DraftStatus from, DraftEvent e, DraftStatus? to) {
      expect(nextDraftStatus(from, e), to, reason: '$from + $e');
    }

    test('S1 bis S4', () {
      expectStep(DraftStatus.recording, DraftEvent.pause, DraftStatus.paused);
      expectStep(DraftStatus.paused, DraftEvent.resume, DraftStatus.recording);
      expectStep(
        DraftStatus.recording,
        DraftEvent.finishAndReview,
        DraftStatus.review,
      );
      expectStep(
        DraftStatus.paused,
        DraftEvent.finishAndReview,
        DraftStatus.review,
      );
      expectStep(
        DraftStatus.review,
        DraftEvent.continueRecording,
        DraftStatus.recording,
      );
    });

    test('S5 bis S7', () {
      expectStep(
        DraftStatus.review,
        DraftEvent.submitSignedIn,
        DraftStatus.queued,
      );
      expectStep(
        DraftStatus.review,
        DraftEvent.submitSignedOut,
        DraftStatus.awaitingAccount,
      );
      expectStep(
        DraftStatus.awaitingAccount,
        DraftEvent.signInSucceeded,
        DraftStatus.queued,
      );
    });

    test('S8 bis S12', () {
      expectStep(
        DraftStatus.queued,
        DraftEvent.queueStarts,
        DraftStatus.uploading,
      );
      expectStep(
        DraftStatus.uploading,
        DraftEvent.uploadComplete,
        DraftStatus.submitted,
      );
      expectStep(
        DraftStatus.uploading,
        DraftEvent.uploadNetworkError,
        DraftStatus.queued,
      );
      expectStep(
        DraftStatus.uploading,
        DraftEvent.upload401,
        DraftStatus.awaitingAccount,
      );
      expectStep(
        DraftStatus.uploading,
        DraftEvent.uploadRejected,
        DraftStatus.failed,
      );
    });

    test('S13 und S14', () {
      expectStep(DraftStatus.failed, DraftEvent.edit, DraftStatus.review);
      expectStep(
        DraftStatus.recording,
        DraftEvent.systemKilledReview,
        DraftStatus.review,
      );
      expectStep(
        DraftStatus.paused,
        DraftEvent.systemKilledReview,
        DraftStatus.review,
      );
    });

    test('unzulässige Übergänge liefern null', () {
      expectStep(DraftStatus.submitted, DraftEvent.pause, null);
      expectStep(DraftStatus.review, DraftEvent.queueStarts, null);
      expectStep(DraftStatus.queued, DraftEvent.submitSignedIn, null);
      expectStep(DraftStatus.recording, DraftEvent.submitSignedIn, null);
      expectStep(DraftStatus.submitted, DraftEvent.edit, null);
    });
  });

  group('Signal (3.5)', () {
    test('Stufen', () {
      expect(signalLevel(accuracyM: 10), SignalLevel.good);
      expect(signalLevel(accuracyM: 11), SignalLevel.mid);
      expect(signalLevel(accuracyM: 25), SignalLevel.mid);
      expect(signalLevel(accuracyM: 25.1), SignalLevel.weak);
    });

    test('Kein GPS: nie ein Fix oder seit mehr als 30 s', () {
      expect(signalLevel(accuracyM: null), SignalLevel.none);
      expect(signalLevel(accuracyM: 5, secondsSinceFix: 31), SignalLevel.none);
      expect(signalLevel(accuracyM: 5, secondsSinceFix: 30), SignalLevel.good);
    });

    test('„Trotzdem starten“ erst nach 20 s und nur bei schwachem Signal', () {
      expect(showStartAnyway(accuracyM: 40, secondsSinceOpen: 19), isFalse);
      expect(showStartAnyway(accuracyM: 40, secondsSinceOpen: 20), isTrue);
      expect(showStartAnyway(accuracyM: 12, secondsSinceOpen: 60), isFalse);
      expect(showStartAnyway(accuracyM: null, secondsSinceOpen: 25), isTrue);
    });
  });

  group('Schnellmeldung R11 bis R13', () {
    test('unter 20 m: Rausch-Karte', () {
      expect(
        evaluateQuickResult(deviationM: 12, accuracyM: 8, attempts: 1),
        QuickResultState.noise,
      );
    });

    test('ab 20 m und gutes Signal: sendbar', () {
      expect(
        evaluateQuickResult(deviationM: 47, accuracyM: 8, attempts: 1),
        QuickResultState.ready,
      );
    });

    test('Genauigkeit über 25 m: erst nach dem dritten Versuch senden', () {
      expect(
        evaluateQuickResult(deviationM: 47, accuracyM: 30, attempts: 2),
        QuickResultState.weak,
      );
      expect(
        evaluateQuickResult(deviationM: 47, accuracyM: 30, attempts: 3),
        QuickResultState.weakOverride,
      );
    });

    test('zu weit weg: über 500 m', () {
      expect(quickTooFar(500), isFalse);
      expect(quickTooFar(501), isTrue);
    });

    test('abseits des Pfads: Rückfrage über 100 m', () {
      expect(needsOffTrailConfirm(100), isFalse);
      expect(needsOffTrailConfirm(101), isTrue);
    });

    test('closed und danger nur bis 500 m zum Pfad', () {
      expect(
        hintSendAllowed(isClosedOrDanger: true, distanceToTrailM: 600),
        isFalse,
      );
      expect(
        hintSendAllowed(isClosedOrDanger: true, distanceToTrailM: 400),
        isTrue,
      );
      expect(
        hintSendAllowed(isClosedOrDanger: false, distanceToTrailM: 600),
        isTrue,
      );
    });

    test('„Sonstiges“ braucht mindestens 10 Zeichen', () {
      expect(otherNoteValid('zu kurz'), isFalse);
      expect(otherNoteValid('   zu kurz   '), isFalse);
      expect(otherNoteValid('genug Zeichen hier'), isTrue);
      expect(otherNoteValid(null), isFalse);
    });
  });

  group('Prüfen R4', () {
    const station = ReviewMarker(type: PointType.station, number: 1);

    test('Hinweise H1 bis H5', () {
      final h = computeReviewHints(
        markers: const [
          ReviewMarker(type: PointType.waypoint),
          ReviewMarker(type: PointType.parking, lowAccuracy: true),
        ],
        trackLengthM: 250,
        gapM: 80,
      );
      expect(h.has(ReviewHint.h1TooShort), isTrue);
      expect(h.has(ReviewHint.h2NoStation), isTrue);
      expect(h.has(ReviewHint.h3Inaccurate), isTrue);
      expect(h.inaccurateCount, 1);
      expect(h.has(ReviewHint.h4Gap), isTrue);
      expect(h.gapM, 80);
      expect(h.has(ReviewHint.h5DupNumbers), isFalse);
    });

    test('keine Hinweise bei sauberer Aufnahme', () {
      final h = computeReviewHints(
        markers: const [
          station,
          ReviewMarker(type: PointType.station, number: 2),
        ],
        trackLengthM: 2400,
        gapM: 10,
      );
      expect(h.hints, isEmpty);
    });

    test('H5: doppelte Stationsnummern', () {
      final h = computeReviewHints(
        markers: const [station, station],
        trackLengthM: 2400,
        gapM: 0,
      );
      expect(h.has(ReviewHint.h5DupNumbers), isTrue);
    });

    test('Länge genau 300 m und Lücke genau 50 m lösen H1/H4 nicht aus', () {
      final h = computeReviewHints(
        markers: const [station],
        trackLengthM: 300,
        gapM: 50,
      );
      expect(h.has(ReviewHint.h1TooShort), isFalse);
      expect(h.has(ReviewHint.h4Gap), isFalse);
    });

    test('Gültigkeit newTrail: Name und Gebiet Pflicht', () {
      final e = validateForSubmit(
        kind: ReportKind.newTrail,
        title: 'ab',
        area: null,
        trackLengthM: 500,
        markerCount: 0,
      );
      expect(e, [ReviewFieldError.nameTooShort, ReviewFieldError.areaMissing]);
    });

    test('Gültigkeit: Track unter 100 m und weniger als 2 Marker', () {
      expect(
        validateForSubmit(
          kind: ReportKind.revision,
          title: null,
          area: null,
          trackLengthM: 99,
          markerCount: 1,
        ),
        [ReviewFieldError.tooShort],
      );
      expect(
        validateForSubmit(
          kind: ReportKind.revision,
          title: null,
          area: null,
          trackLengthM: 99,
          markerCount: 2,
        ),
        isEmpty,
      );
      expect(
        validateForSubmit(
          kind: ReportKind.revision,
          title: null,
          area: null,
          trackLengthM: 100,
          markerCount: 0,
        ),
        isEmpty,
      );
    });

    test('gültiger neuer Pfad', () {
      expect(
        validateForSubmit(
          kind: ReportKind.newTrail,
          title: 'Waldlehrpfad Beispiel',
          area: 'wald',
          trackLengthM: 2400,
          markerCount: 5,
        ),
        isEmpty,
      );
    });

    test('Grenzen: 60 Marker, 20 000 Track-Punkte', () {
      expect(markerLimitReached(59), isFalse);
      expect(markerLimitReached(60), isTrue);
      expect(trackLimitReached(19999), isFalse);
      expect(trackLimitReached(20000), isTrue);
    });

    test('Nummern rücken nach, manuelle bleiben', () {
      final nums = renumberStations(const [
        ReviewMarker(type: PointType.start),
        ReviewMarker(type: PointType.station, number: 1),
        ReviewMarker(type: PointType.station, number: 3),
        ReviewMarker(type: PointType.waypoint),
        ReviewMarker(type: PointType.station, number: 4),
      ]);
      expect(nums, [null, 1, 2, null, 3]);

      final manual = renumberStations(
        const [
          ReviewMarker(type: PointType.station, number: 7),
          ReviewMarker(type: PointType.station, number: 3),
        ],
        manual: {0},
      );
      expect(manual, [7, 8]);
    });

    test('nächste Stationsnummer', () {
      expect(nextStationNumber(const []), 1);
      expect(
        nextStationNumber(const [
          ReviewMarker(type: PointType.station, number: 2),
          ReviewMarker(type: PointType.waypoint),
        ]),
        3,
      );
    });
  });
}
