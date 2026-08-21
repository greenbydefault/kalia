import 'package:latlong2/latlong.dart';

import '../../trail/domain/station.dart';

/// Throttled UI-DTO aus dem Walk-Tracking (kein Roh-GPS-Stream).
class WalkSnapshot {
  const WalkSnapshot({
    required this.trailId,
    required this.rawPosition,
    required this.snappedPosition,
    required this.progressM,
    required this.progressRatio,
    required this.offTrack,
    required this.visitedStationIds,
    this.nextStation,
    this.heading,
    this.justVisitedStationId,
    this.showRouteProgress = true,
    this.locationError,
  });

  final String trailId;
  final LatLng rawPosition;
  final LatLng snappedPosition;
  final double progressM;
  final double progressRatio;
  final bool offTrack;
  final List<String> visitedStationIds;
  final Station? nextStation;
  final double? heading;
  final String? justVisitedStationId;
  final bool showRouteProgress;
  final String? locationError;

  int get progressPercent => (progressRatio * 100).round().clamp(0, 100);

  WalkSnapshot copyWith({
    LatLng? rawPosition,
    LatLng? snappedPosition,
    double? progressM,
    double? progressRatio,
    bool? offTrack,
    List<String>? visitedStationIds,
    Station? nextStation,
    double? heading,
    String? justVisitedStationId,
    bool? showRouteProgress,
    String? locationError,
    bool clearLocationError = false,
  }) {
    return WalkSnapshot(
      trailId: trailId,
      rawPosition: rawPosition ?? this.rawPosition,
      snappedPosition: snappedPosition ?? this.snappedPosition,
      progressM: progressM ?? this.progressM,
      progressRatio: progressRatio ?? this.progressRatio,
      offTrack: offTrack ?? this.offTrack,
      visitedStationIds: visitedStationIds ?? this.visitedStationIds,
      nextStation: nextStation ?? this.nextStation,
      heading: heading ?? this.heading,
      justVisitedStationId: justVisitedStationId ?? this.justVisitedStationId,
      showRouteProgress: showRouteProgress ?? this.showRouteProgress,
      locationError: clearLocationError
          ? null
          : (locationError ?? this.locationError),
    );
  }
}
