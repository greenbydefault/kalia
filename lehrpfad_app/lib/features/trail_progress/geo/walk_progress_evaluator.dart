import 'package:latlong2/latlong.dart';

import '../../trail/domain/station.dart';
import '../../trail/domain/trail.dart';
import 'polyline_metrics.dart';
import 'snap_to_path.dart';
import 'station_geofence.dart';

const defaultOffTrackThresholdM = 50.0;
const defaultAutoCompleteRatio = 0.95;
const defaultStartReturnRadiusM = 40.0;
const defaultAutoCompleteMinDuration = Duration(minutes: 2);

class WalkEvaluation {
  const WalkEvaluation({
    required this.snap,
    required this.progressRatio,
    required this.offTrack,
    required this.newlyVisitedStationIds,
    required this.nextStation,
    required this.shouldAutoComplete,
  });

  final SnapResult snap;
  final double progressRatio;
  final bool offTrack;
  final List<String> newlyVisitedStationIds;
  final Station? nextStation;
  final bool shouldAutoComplete;
}

WalkEvaluation evaluateWalkProgress({
  required Trail trail,
  required PolylineMetrics metrics,
  required LatLng position,
  required Set<String> visitedStationIds,
  DateTime? startedAt,
  DateTime? now,
  Duration minDuration = defaultAutoCompleteMinDuration,
  double offTrackThresholdM = defaultOffTrackThresholdM,
  double autoCompleteRatio = defaultAutoCompleteRatio,
  double startReturnRadiusM = defaultStartReturnRadiusM,
  double stationRadiusM = defaultStationGeofenceRadiusM,
}) {
  final newly = stationsEntered(
    position: position,
    stations: trail.stationen,
    alreadyVisited: visitedStationIds,
    radiusM: stationRadiusM,
  );
  final visited = {...visitedStationIds, ...newly};
  final next = nextUnvisitedStation(
    stations: trail.stationen,
    visited: visited,
  );
  final allStationsVisited =
      trail.stationen.isNotEmpty && visited.length >= trail.stationen.length;
  final guard = autoCompleteGuardPassed(
    visitedBefore: visitedStationIds,
    newlyVisited: newly,
    startedAt: startedAt,
    now: now ?? DateTime.now(),
    minDuration: minDuration,
  );

  if (trail.isFlaeche) {
    final ratio = trail.stationen.isEmpty
        ? 0.0
        : visited.length / trail.stationen.length;
    return WalkEvaluation(
      snap: SnapResult(
        snapped: position,
        distanceToPathM: 0,
        alongTrackM: 0,
        segmentIndex: 0,
      ),
      progressRatio: ratio,
      offTrack: false,
      newlyVisitedStationIds: newly,
      nextStation: next,
      shouldAutoComplete: guard && allStationsVisited,
    );
  }

  final snap = nearestPointOnPolyline(position, metrics);
  final ratio = metrics.totalLengthM <= 0
      ? 0.0
      : (snap.alongTrackM / metrics.totalLengthM).clamp(0.0, 1.0);

  final start = trail.startOrNull;
  final nearEnd = ratio >= autoCompleteRatio;
  final nearStartAgain =
      trail.rundkurs &&
      start != null &&
      ratio >= 0.7 &&
      haversineMeters(position, start) <= startReturnRadiusM;

  return WalkEvaluation(
    snap: snap,
    progressRatio: ratio,
    offTrack: snap.distanceToPathM > offTrackThresholdM,
    newlyVisitedStationIds: newly,
    nextStation: next,
    shouldAutoComplete: guard && (nearEnd || allStationsVisited || nearStartAgain),
  );
}

bool autoCompleteGuardPassed({
  required Set<String> visitedBefore,
  required List<String> newlyVisited,
  required DateTime? startedAt,
  required DateTime now,
  Duration minDuration = defaultAutoCompleteMinDuration,
}) {
  if (visitedBefore.isNotEmpty || newlyVisited.isNotEmpty) return true;
  if (startedAt != null && now.difference(startedAt) >= minDuration) {
    return true;
  }
  return false;
}
