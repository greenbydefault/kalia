/// Enums des lokalen Entwurfs (Spec Abschnitt 2.1).
enum ReportKind { newTrail, revision, quick }

enum PointType { start, parking, station, waypoint, hint, end }

enum HintKind { closed, danger, stairsRoots, viewpoint, facility, other }

enum QuickIntent { movePoint, addPoint, hint, other }

enum RecordingMode { trackAndPoints, pointsOnly }

enum DraftStatus {
  // Aufnahme und Prüfen
  recording,
  paused,
  review,
  // Einreichen gedrückt, nicht angemeldet
  awaitingAccount,
  // Upload-Queue
  queued,
  uploading,
  // Server hat den Beitrag
  submitted,
  // Validierungsfehler vom Server
  failed,
}

/// Server-Status eines Beitrags (Spec Abschnitt 2.2).
enum SubmissionStatus {
  submitted,
  inReview,
  needsInfo,
  approved,
  partiallyApproved,
  rejected,
  withdrawn,
}

/// Grundcodes für Ablehnung (`decision_reason_code`).
enum DecisionReason {
  duplicate,
  withinGpsNoise,
  notFamilySuitable,
  notPublic,
  insufficientData,
  wrongLocation,
  other,
}

/// Gebiet eines neuen Pfads (Seed-Feld `gebiet`).
const reportAreas = [
  'wald',
  'heide',
  'moor',
  'kueste',
  'wasser',
  'aue',
  'hof',
];
