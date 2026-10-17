import 'dart:math' as math;

import '../report_config.dart';

class Fix {
  const Fix(this.lat, this.lng, this.accuracyM);

  final double lat;
  final double lng;
  final double accuracyM;
}

class Averaged {
  const Averaged({
    required this.lat,
    required this.lng,
    required this.accuracyM,
    required this.fixCount,
    required this.lowAccuracy,
  });

  final double lat;
  final double lng;
  final double accuracyM;
  final int fixCount;
  final bool lowAccuracy;
}

/// Mittelung eines Punkts (Spec 6.2): Gewicht = 1 / Genauigkeit².
///
/// Zu wenige brauchbare Fixes: bester Einzel-Fix. Leere Liste (kein Signal
/// während der ganzen Messung) liefert `null`, die UI zeigt dann
/// `report.rec.no_fix` und legt keinen Marker an.
Averaged? averageFixes(List<Fix> fixes, {ReportConfig c = cfg}) {
  if (fixes.isEmpty) return null;
  final usable = fixes.where((f) => f.accuracyM <= c.trackFixMaxAccM).toList();
  if (usable.length < c.avgMinFixes) {
    final best = fixes.reduce((a, b) => a.accuracyM <= b.accuracyM ? a : b);
    return Averaged(
      lat: best.lat,
      lng: best.lng,
      accuracyM: best.accuracyM,
      fixCount: 1,
      lowAccuracy: best.accuracyM > c.okMaxM,
    );
  }
  var sw = 0.0;
  var slat = 0.0;
  var slng = 0.0;
  for (final f in usable) {
    // Genauigkeit 0 würde das Gewicht sprengen, Untergrenze 1 m.
    final acc = math.max(f.accuracyM, 1.0);
    final w = 1 / (acc * acc);
    sw += w;
    slat += w * f.lat;
    slng += w * f.lng;
  }
  final acc = math.sqrt(1 / sw);
  return Averaged(
    lat: slat / sw,
    lng: slng / sw,
    accuracyM: acc,
    fixCount: usable.length,
    lowAccuracy: acc > c.okMaxM,
  );
}

/// Ist die Mittelung fertig? Mindestens [ReportConfig.avgMinS] vergangen
/// und mindestens [ReportConfig.avgMinFixes] brauchbare Fixes, spätestens
/// nach [ReportConfig.avgMaxS].
bool averagingDone({
  required double elapsedS,
  required int usableFixes,
  ReportConfig c = cfg,
}) {
  if (elapsedS >= c.avgMaxS) return true;
  return elapsedS >= c.avgMinS && usableFixes >= c.avgMinFixes;
}
