import 'dart:async';

import '../../trail_progress/tracking/location_service.dart';
import '../logic/averaging.dart';
import '../report_config.dart';

/// Misst einen Punkt (Spec 6.2): sammelt Fixes über das Profil `pointFix`,
/// mindestens `avgMinS`, höchstens `avgMaxS`, und mittelt sie.
///
/// Liefert `null`, wenn während der ganzen Messung kein Fix kam (Z6).
Future<Averaged?> measurePoint(
  LocationService location, {
  void Function(double progress)? onProgress,
  ReportConfig c = cfg,
  Duration tick = const Duration(milliseconds: 200),
}) async {
  final fixes = <Fix>[];
  final done = Completer<void>();
  final watch = Stopwatch()..start();

  StreamSubscription<LocationFix>? sub;
  Timer? timer;

  void finish() {
    if (!done.isCompleted) done.complete();
  }

  sub = location
      .watchFixes(LocationProfile.pointFix)
      .listen(
        (f) {
          fixes.add(
            Fix(f.position.latitude, f.position.longitude, f.accuracyM ?? 50),
          );
        },
        onError: (_) {
          // Weitermessen; ohne Fix endet es mit null.
        },
      );

  timer = Timer.periodic(tick, (_) {
    final elapsed = watch.elapsedMilliseconds / 1000;
    onProgress?.call((elapsed / c.avgMaxS).clamp(0.0, 1.0));
    final usable = fixes.where((f) => f.accuracyM <= c.trackFixMaxAccM).length;
    if (averagingDone(elapsedS: elapsed, usableFixes: usable, c: c)) finish();
  });

  await done.future;
  timer.cancel();
  await sub.cancel();
  onProgress?.call(1);
  return averageFixes(fixes, c: c);
}
