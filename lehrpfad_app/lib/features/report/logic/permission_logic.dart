import '../domain/report_enums.dart';

/// Plattformneutraler Stand der Standort-Berechtigung (Spec 3.2).
enum ReportPermission { notDetermined, denied, deniedForever, whileInUse }

/// Varianten von R14 „Berechtigung erklären“ (Keys `report.perm.*`).
enum PermVariant { off, pre, denied, settings, precise }

class PermSnapshot {
  const PermSnapshot({
    required this.serviceEnabled,
    required this.permission,
    required this.precise,
  });

  final bool serviceEnabled;
  final ReportPermission permission;

  /// iOS reduced / Android coarse = `false`.
  final bool precise;
}

/// Prüfreihenfolge 3.4, Schritte 1 bis 3. `null` = alles erlaubt.
PermVariant? permissionGate(PermSnapshot s) {
  if (!s.serviceEnabled) return PermVariant.off;
  switch (s.permission) {
    case ReportPermission.notDetermined:
      return PermVariant.pre;
    case ReportPermission.denied:
      return PermVariant.denied;
    case ReportPermission.deniedForever:
      return PermVariant.settings;
    case ReportPermission.whileInUse:
      break;
  }
  if (!s.precise) return PermVariant.precise;
  return null;
}

class ModeDecision {
  const ModeDecision.mode(RecordingMode this.mode) : blockedBy = null;
  const ModeDecision.blocked(PermVariant this.blockedBy) : mode = null;

  final RecordingMode? mode;
  final PermVariant? blockedBy;

  bool get isBlocked => blockedBy != null;
}

/// Modus-Entscheidung (Spec 13.2, M1 bis M4 und 3.4 Schritt 4).
///
/// - erteilt und Dienst startet: `trackAndPoints`
/// - erteilt, Dienst startet nicht oder Benachrichtigung (Android 13+)
///   abgelehnt: `pointsOnly`
/// - nur ungefähr oder nicht erteilt: gesperrt mit passender R14-Variante
ModeDecision decideRecordingMode({
  required PermSnapshot permission,
  required bool serviceStarted,
  bool notificationsDenied = false,
}) {
  final gate = permissionGate(permission);
  if (gate != null) return ModeDecision.blocked(gate);
  if (!serviceStarted || notificationsDenied) {
    return const ModeDecision.mode(RecordingMode.pointsOnly);
  }
  return const ModeDecision.mode(RecordingMode.trackAndPoints);
}
