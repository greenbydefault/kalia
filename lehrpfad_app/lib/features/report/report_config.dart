/// Alle Schwellenwerte für „Pfad melden“ (Spec Abschnitt 6.1).
/// Keine Zahlen im Widget-Code: Schwellen werden nur hier geändert.
class ReportConfig {
  const ReportConfig();

  // Signal (Meter / Sekunden)
  final double goodMaxM = 10;
  final double okMaxM = 25;
  final int startOverrideAfterS = 20;
  final int noSignalAfterS = 30;

  // Track-Filter
  final double trackFixMaxAccM = 30;
  final double trackMinDistM = 4;
  final double trackMaxSpeedMps = 8;
  final double stationarySpeedMps = 0.3;
  final int stationaryHoldS = 20;
  final int trackIntervalS = 2;

  // Mittelung eines Punkts
  final int avgMinS = 3;
  final int avgMaxS = 8;
  final int avgMinFixes = 3;

  // Abweichung, Konsens, Anwesenheit
  final double noiseMaxM = 20;
  final double candidateMinM = 25;
  final double consensusRadiusM = 25;
  final double presenceMaxM = 500;
  final double offTrailWarnM = 100;
  final double revisionStartWarnM = 300;
  final double duplicateClientRadiusM = 300;
  final double duplicateServerRadiusM = 150;

  // Rundweg
  final double loopMaxGapM = 50;
  final double loopMinLengthM = 300;

  // Gültigkeit und Hinweise H1 bis H4
  final double minTrackLengthM = 100;
  final double shortTrackWarnM = 300;
  final double gapWarnM = 50;
  final int minMarkersWithoutTrack = 2;

  // Kürzen in R4
  final double trimMaxM = 300;
  final double trimStepM = 10;

  // Grenzen je Entwurf
  final int maxMarkers = 60;
  final int maxTrackPoints = 20000;
  final int maxPhotosPerMarker = 3;
  final int maxPhotosPerSubmission = 20;

  // Fotos
  final int photoMaxEdgePx = 1600;
  final int photoJpegQuality = 80;

  // Schnellmeldungen
  final int quickWeakAttemptsBeforeOverride = 3;
  final double quickMaxDistToTargetM = 500;

  // Listen und Snackbars
  final double nearbyTrailsRadiusKm = 5;
  final int undoSnackbarS = 6;

  // Upload
  final List<int> uploadBackoffS = const [5, 30, 300];

  // Limits je Nutzer (Server)
  final int maxOpenSubmissions = 5;
  final int maxNewPerDay = 10;

  // Aufbewahrung der Rohdaten nach der Entscheidung [TODO: bestätigen]
  final int retentionDays = 90;

  // Puffer für lokale Track-Fixes (Abschnitt 7.1)
  final int trackFlushEveryS = 5;
  final int trackFlushEveryFixes = 10;

  // Texte: Längen
  final int titleMaxChars = 80;
  final int titleMinChars = 3;
  final int noteMaxChars = 500;
  final int quickNoteMaxChars = 200;
  final int hintNoteMaxChars = 300;
  final int otherNoteMinChars = 10;
}

/// Standard-Konfiguration. Tests und Logik nehmen sie per Default-Parameter.
const cfg = ReportConfig();
