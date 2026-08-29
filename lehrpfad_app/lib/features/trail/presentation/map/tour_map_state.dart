import 'package:latlong2/latlong.dart';

/// Tour-Overlay der Übersichtskarte: Route, Fortschritt, Marker, Follow.
class TourMapState {
  const TourMapState({
    this.route = const [],
    this.progressM,
    this.rawPosition,
    this.tracking = false,
    this.idlePosition,
  });

  static const empty = TourMapState();

  final List<LatLng> route;
  final double? progressM;
  final LatLng? rawPosition;
  final bool tracking;
  final LatLng? idlePosition;

  bool get hasProgress => progressM != null && route.length >= 2;

  LatLng? get markerPosition => tracking ? rawPosition : idlePosition;

  LatLng? get followPosition => rawPosition;
}
