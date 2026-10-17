import '../report_config.dart';
import 'deviation.dart';

/// Ergebnis-Zustand der Station-verschieben-Meldung (R11, Spec 5.3).
enum QuickResultState {
  /// Normal sendbar.
  ready,

  /// Abweichung unter 20 m: Infokarte, Hauptbutton „Abbrechen“, „Trotzdem
  /// senden“ sekundär. Wird als `noise` markiert gesendet.
  noise,

  /// Genauigkeit über 25 m: „Senden“ gesperrt, „Nochmal messen“ ist Haupt.
  weak,

  /// Wie [weak], aber nach dem dritten Versuch ist „Trotzdem senden“ da.
  weakOverride,
}

QuickResultState evaluateQuickResult({
  required double deviationM,
  required double accuracyM,
  required int attempts,
  ReportConfig c = cfg,
}) {
  if (accuracyM > c.okMaxM) {
    return attempts >= c.quickWeakAttemptsBeforeOverride
        ? QuickResultState.weakOverride
        : QuickResultState.weak;
  }
  if (classifyDeviation(deviationM, c: c) == DeviationClass.noise) {
    return QuickResultState.noise;
  }
  return QuickResultState.ready;
}

/// Gesperrt, wenn die gespeicherte Station mehr als `presenceMaxM` entfernt
/// ist (R11/R12/R13, Z21).
bool quickTooFar(double distanceToTargetM, {ReportConfig c = cfg}) =>
    !mayReport(distanceToTargetM, c: c);

/// R12: Ergänzte Station weiter als `offTrailWarnM` vom Pfad: Rückfrage.
bool needsOffTrailConfirm(double distanceToTrailM, {ReportConfig c = cfg}) =>
    distanceToTrailM > c.offTrailWarnM;

/// R13 „Hinweis“: `closed` und `danger` nur bis `presenceMaxM` zum Pfad.
bool hintSendAllowed({
  required bool isClosedOrDanger,
  required double distanceToTrailM,
  ReportConfig c = cfg,
}) => !isClosedOrDanger || mayReport(distanceToTrailM, c: c);

/// R13 „Sonstiges“: Notiz mindestens 10 Zeichen.
bool otherNoteValid(String? note, {ReportConfig c = cfg}) =>
    (note?.trim().length ?? 0) >= c.otherNoteMinChars;
