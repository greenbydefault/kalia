import '../report_config.dart';

enum SignalLevel { good, mid, weak, none }

/// Signal-Anzeige (Spec 3.5). Kein Fix seit mehr als `noSignalAfterS`
/// Sekunden (oder noch nie) = „Kein GPS“.
SignalLevel signalLevel({
  required double? accuracyM,
  double? secondsSinceFix,
  ReportConfig c = cfg,
}) {
  if (accuracyM == null) return SignalLevel.none;
  if (secondsSinceFix != null && secondsSinceFix > c.noSignalAfterS) {
    return SignalLevel.none;
  }
  if (accuracyM <= c.goodMaxM) return SignalLevel.good;
  if (accuracyM <= c.okMaxM) return SignalLevel.mid;
  return SignalLevel.weak;
}

/// Start und Messung verlangen Genauigkeit bis `okMaxM`.
bool signalAllowsStart(double? accuracyM, {ReportConfig c = cfg}) =>
    accuracyM != null && accuracyM <= c.okMaxM;

/// „Trotzdem starten“ erscheint nach `startOverrideAfterS`, solange die
/// Genauigkeit über `okMaxM` liegt (R1).
bool showStartAnyway({
  required double? accuracyM,
  required double secondsSinceOpen,
  ReportConfig c = cfg,
}) =>
    !signalAllowsStart(accuracyM, c: c) &&
    secondsSinceOpen >= c.startOverrideAfterS;

/// Schnellmeldungen (R11 bis R13) verlangen mindestens Signal „Mittel“.
bool signalAllowsQuick(double? accuracyM, {ReportConfig c = cfg}) =>
    signalAllowsStart(accuracyM, c: c);
