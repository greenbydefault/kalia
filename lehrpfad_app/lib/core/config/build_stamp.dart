import 'package:flutter/foundation.dart';

/// Kurz-SHA aus dem Vercel-Build (`--dart-define=GIT_SHA`). Lokal: `dev`.
const gitSha = String.fromEnvironment('GIT_SHA', defaultValue: 'dev');

final catalogClock = Stopwatch();
final nearbyRequested = Stopwatch();

void logBuildStamp() {
  catalogClock
    ..reset()
    ..start();
  debugPrint('build $gitSha');
}

/// „Pfade anzeigen“ bzw. Standort freigegeben.
void markNearbyRequested() {
  nearbyRequested
    ..reset()
    ..start();
}

var _nearbyLogged = false;

void logNearbyVisible() {
  if (_nearbyLogged) return;
  _nearbyLogged = true;
  final sincePlace = nearbyRequested.elapsedMilliseconds;
  debugPrint(
    'nearby list ${catalogClock.elapsedMilliseconds} ms after start, '
    '$sincePlace ms after place',
  );
}
