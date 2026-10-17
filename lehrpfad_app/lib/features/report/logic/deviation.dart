import '../report_config.dart';
import 'geo.dart';

enum DeviationClass { noise, borderline, candidate }

/// Abweichung zwischen neuer und gespeicherter Position desselben Punkts
/// (Spec 6.4): unter 20 m Rauschen, 20 bis unter 25 m grenzwertig, ab 25 m
/// Korrekturvorschlag.
DeviationClass classifyDeviation(double deviationM, {ReportConfig c = cfg}) {
  if (deviationM < c.noiseMaxM) return DeviationClass.noise;
  if (deviationM < c.candidateMinM) return DeviationClass.borderline;
  return DeviationClass.candidate;
}

class ReportPos {
  const ReportPos({
    required this.userId,
    required this.targetPointId,
    required this.lat,
    required this.lng,
  });

  final String userId;
  final String targetPointId;
  final double lat;
  final double lng;
}

/// Konsens: zwei Meldungen verschiedener Nutzer zum selben Zielpunkt,
/// höchstens `consensusRadiusM` auseinander. Derselbe Nutzer zweimal zählt
/// nicht.
bool isConsensus(ReportPos a, ReportPos b, {ReportConfig c = cfg}) =>
    a.userId != b.userId &&
    a.targetPointId == b.targetPointId &&
    distanceM(a.lat, a.lng, b.lat, b.lng) <= c.consensusRadiusM;

/// Anwesenheit: Melden nur aus höchstens `presenceMaxM` Abstand zum Ziel.
bool mayReport(double distanceToTargetM, {ReportConfig c = cfg}) =>
    distanceToTargetM <= c.presenceMaxM;
