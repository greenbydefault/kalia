import '../domain/report_enums.dart';
import '../report_config.dart';

/// Schmale Sicht auf einen Marker für Prüfen und Validierung.
class ReviewMarker {
  const ReviewMarker({
    required this.type,
    this.number,
    this.lowAccuracy = false,
  });

  final PointType type;
  final int? number;
  final bool lowAccuracy;
}

/// Hinweise in R4. Nie blockierend.
enum ReviewHint { h1TooShort, h2NoStation, h3Inaccurate, h4Gap, h5DupNumbers }

class ReviewHints {
  const ReviewHints(this.hints, {this.inaccurateCount = 0, this.gapM = 0});

  final List<ReviewHint> hints;

  /// Für `report.review.h3` ({n}).
  final int inaccurateCount;

  /// Für `report.review.h4` ({d}).
  final double gapM;

  bool has(ReviewHint h) => hints.contains(h);
}

/// H1 bis H5 (Spec 4.5). [trackLengthM] ist die Länge des (gekürzten)
/// Tracks, [gapM] die größte Lücke.
ReviewHints computeReviewHints({
  required List<ReviewMarker> markers,
  required double trackLengthM,
  required double gapM,
  ReportConfig c = cfg,
}) {
  final hints = <ReviewHint>[];
  if (trackLengthM < c.shortTrackWarnM) hints.add(ReviewHint.h1TooShort);
  if (!markers.any((m) => m.type == PointType.station)) {
    hints.add(ReviewHint.h2NoStation);
  }
  final inaccurate = markers.where((m) => m.lowAccuracy).length;
  if (inaccurate > 0) hints.add(ReviewHint.h3Inaccurate);
  if (gapM > c.gapWarnM) hints.add(ReviewHint.h4Gap);
  if (hasDuplicateStationNumbers(markers)) hints.add(ReviewHint.h5DupNumbers);
  return ReviewHints(hints, inaccurateCount: inaccurate, gapM: gapM);
}

/// H5: Doppelte Stationsnummern. Mehrere Stationen ohne Nummer zählen nicht.
bool hasDuplicateStationNumbers(List<ReviewMarker> markers) {
  final seen = <int>{};
  for (final m in markers) {
    if (m.type != PointType.station || m.number == null) continue;
    if (!seen.add(m.number!)) return true;
  }
  return false;
}

/// Fehler in R4. `null` = Feld gültig.
enum ReviewFieldError { nameTooShort, areaMissing, tooShort }

/// Gültig zum Einreichen (Spec 4.5): bei `newTrail` Name mindestens
/// 3 Zeichen und Gebiet gewählt. Bei allen Arten zusätzlich Track
/// mindestens 100 m oder mindestens 2 Marker. Fotos sind nie Pflicht.
///
/// Reihenfolge der Fehler = Reihenfolge der Felder, damit R4 zum ersten
/// fehlerhaften Feld scrollen kann.
List<ReviewFieldError> validateForSubmit({
  required ReportKind kind,
  required String? title,
  required String? area,
  required double trackLengthM,
  required int markerCount,
  ReportConfig c = cfg,
}) {
  final errors = <ReviewFieldError>[];
  if (kind == ReportKind.newTrail) {
    if ((title?.trim().length ?? 0) < c.titleMinChars) {
      errors.add(ReviewFieldError.nameTooShort);
    }
    if (area == null || !reportAreas.contains(area)) {
      errors.add(ReviewFieldError.areaMissing);
    }
  }
  if (trackLengthM < c.minTrackLengthM &&
      markerCount < c.minMarkersWithoutTrack) {
    errors.add(ReviewFieldError.tooShort);
  }
  return errors;
}

/// Marker-Limit (Z7): Hauptbutton gesperrt bei `maxMarkers`.
bool markerLimitReached(int markerCount, {ReportConfig c = cfg}) =>
    markerCount >= c.maxMarkers;

/// Track-Limit (Z8): Aufzeichnung stoppt bei `maxTrackPoints`.
bool trackLimitReached(int pointCount, {ReportConfig c = cfg}) =>
    pointCount >= c.maxTrackPoints;

/// Automatische Stationsnummern nach Entfernen eines Markers (Rückgängig,
/// Löschen): Stationen werden in Erfassungsreihenfolge 1..n neu nummeriert.
/// Manuell gesetzte Nummern bleiben, [manual] enthält deren Indizes.
List<int?> renumberStations(
  List<ReviewMarker> markersInOrder, {
  Set<int> manual = const {},
}) {
  final out = <int?>[];
  var next = 1;
  for (var i = 0; i < markersInOrder.length; i++) {
    final m = markersInOrder[i];
    if (m.type != PointType.station) {
      out.add(m.number);
      continue;
    }
    if (manual.contains(i)) {
      out.add(m.number);
      if (m.number != null && m.number! >= next) next = m.number! + 1;
    } else {
      out.add(next++);
    }
  }
  return out;
}

/// Nummer des nächsten Markers der Art Station.
int nextStationNumber(List<ReviewMarker> markersInOrder) {
  var max = 0;
  for (final m in markersInOrder) {
    if (m.type == PointType.station && (m.number ?? 0) > max) {
      max = m.number!;
    }
  }
  return max + 1;
}
