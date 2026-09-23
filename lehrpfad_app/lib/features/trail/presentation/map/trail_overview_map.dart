import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/map_config.dart';
import '../../../../core/config/map_motion.dart';
import '../../../../shared/widgets/poi_marker.dart';
import '../../../../shared/widgets/typ_start_marker.dart';
import '../../../location/user_position_provider.dart';
import '../../../nearby/domain/nearby.dart';
import '../../../trail_progress/presentation/walk_route_layers.dart';
import '../../../trail_progress/presentation/walk_user_marker.dart';
import '../../domain/trail.dart';
import 'camera_target.dart';
import 'map_camera_controller.dart';
import 'tour_map_state.dart';
import 'trail_cluster_layer.dart';
import 'trail_track_layer.dart';

/// Vollflächige Übersichtskarte: Linien-Routen und Flächen-Polygone,
/// jeweils ein Start-Marker zum Öffnen des Detail-Sheets.
///
/// Komposition aus drei Modulen: [MapCameraController] (Kartenkamera),
/// [TrailClusterLayer] (Cluster) und
/// `trail_track_layer.dart` (Polygone/Polylines).
class TrailOverviewMap extends StatefulWidget {
  final List<Trail>? trails;
  final Trail? selectedTrail;
  final ValueChanged<Trail> onTrailSelected;
  final TourMapState tour;
  final LocateTarget? locateTarget;
  final LatLng? userAnchor;
  final List<NearbyTreffer> nearbyPlaces;
  final NearbyTreffer? selectedNearby;
  final ValueChanged<NearbyTreffer>? onNearbySelected;

  /// One-Shot-Kameraziel (externe Einstiege). Tap-Selektion ist `null`.
  final String? pendingCameraTrailId;
  final VoidCallback? onPendingCameraConsumed;

  const TrailOverviewMap({
    super.key,
    required this.trails,
    required this.selectedTrail,
    required this.onTrailSelected,
    this.tour = TourMapState.empty,
    this.locateTarget,
    this.userAnchor,
    this.nearbyPlaces = const [],
    this.selectedNearby,
    this.onNearbySelected,
    this.pendingCameraTrailId,
    this.onPendingCameraConsumed,
  });

  @override
  State<TrailOverviewMap> createState() => _TrailOverviewMapState();
}

class _TrailOverviewMapState extends State<TrailOverviewMap>
    with TickerProviderStateMixin {
  late final MapCameraController _camera = MapCameraController(
    vsync: this,
    isMounted: () => mounted,
    onFadeReset: _resetTrackFade,
    onFadeStart: _startTrackFade,
  );

  late final AnimationController _trackFadeController = AnimationController(
    duration: MapMotion.trackFade,
    vsync: this,
  )..addListener(_onTrackFade);

  double _trackOpacity = 0;

  @override
  void initState() {
    super.initState();
    if (widget.selectedTrail != null) _trackOpacity = 1;
  }

  @override
  void dispose() {
    _camera.dispose();
    _trackFadeController.dispose();
    super.dispose();
  }

  void _onTrackFade() {
    if (mounted) setState(() => _trackOpacity = _trackFadeController.value);
  }

  void _resetTrackFade() {
    _trackFadeController.stop();
    setState(() => _trackOpacity = 0);
  }

  void _startTrackFade() {
    unawaited(_trackFadeController.forward(from: 0));
  }

  MapCameraInputs _inputs(TrailOverviewMap w) => MapCameraInputs(
    selected: w.selectedTrail,
    trails: w.trails,
    pendingCameraTrailId: w.pendingCameraTrailId,
    followPosition: w.tour.followPosition,
    locateTarget: w.locateTarget,
    userAnchor: w.userAnchor,
  );

  @override
  void didUpdateWidget(covariant TrailOverviewMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _camera.apply(
      current: _inputs(widget),
      previous: _inputs(oldWidget),
      onPendingConsumed: widget.onPendingCameraConsumed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final trails = widget.trails;
    final selectedTrail = widget.selectedTrail;
    final allPoints = trails != null
        ? MapCameraController.allPoints(trails, anchor: widget.userAnchor)
        : <LatLng>[if (widget.userAnchor != null) widget.userAnchor!];
    final inWalk = widget.tour.hasProgress;
    final walkPolylines = inWalk
        ? walkProgressPolylines(
            route: widget.tour.route,
            progressM: widget.tour.progressM!,
          )
        : const <Polyline>[];
    final userMarkers = walkUserMarkers(widget.tour.markerPosition);

    final flaechen = trails?.where((t) => t.isFlaeche).toList() ?? const [];
    final selectedFlaeche = selectedTrail != null && selectedTrail.isFlaeche
        ? selectedTrail
        : null;
    final selectedLinie = selectedTrail != null && selectedTrail.isLinie
        ? selectedTrail
        : null;

    final areaPolygons = buildAreaPolygons(
      flaechen: flaechen,
      selectedFlaeche: selectedFlaeche,
      trackOpacity: _trackOpacity,
    );
    final selectedTrack = buildSelectedTrackPolyline(
      selectedLinie: selectedLinie,
      inWalk: inWalk,
      trackOpacity: _trackOpacity,
    );

    return FlutterMap(
      mapController: _camera.mapController,
      options: MapOptions(
        initialCenter: MapConfig.defaultCenter,
        initialZoom: MapConfig.defaultZoom,
        interactionOptions: MapConfig.interactionOptions,
        initialCameraFit: allPoints.isNotEmpty
            ? CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(allPoints),
                padding: CameraTarget.catalogPadding,
              )
            : null,
        onPositionChanged: (_, hasGesture) {
          if (hasGesture) _camera.onUserGesture();
        },
      ),
      children: [
        MapConfig.buildOsmTileLayer(),
        if (trails != null) ...[
          if (areaPolygons.isNotEmpty) PolygonLayer(polygons: areaPolygons),
          if (selectedTrack != null) PolylineLayer(polylines: [selectedTrack]),
          if (inWalk) PolylineLayer(polylines: walkPolylines),
          TrailClusterLayer(
            mapController: _camera.mapController,
            trails: trails,
            selectedId: selectedTrail?.id,
            onTrailSelected: widget.onTrailSelected,
            onClusterTap: (cluster, starts) =>
                _camera.expandCluster(cluster, starts),
          ),
          if (selectedTrail != null)
            MarkerLayer(
              markers: buildEndpointMarkers(
                trail: selectedTrail,
                selected: selectedTrail,
                onTrailSelected: widget.onTrailSelected,
              ),
            ),
          if (selectedTrail != null && widget.nearbyPlaces.isNotEmpty)
            MarkerLayer(
              markers: [
                for (final treffer in widget.nearbyPlaces)
                  PoiMarker(
                    kategorie: treffer.place.kategorie,
                    selected:
                        widget.selectedNearby?.place.id == treffer.place.id,
                    onTap: widget.onNearbySelected == null
                        ? null
                        : () => widget.onNearbySelected!(treffer),
                  ).toMarker(
                    treffer.place.position,
                    key: ValueKey('p-${treffer.place.id}'),
                  ),
              ],
            ),
          if (userMarkers.isNotEmpty) MarkerLayer(markers: userMarkers),
        ],
      ],
    );
  }
}

/// Start-Marker (bzw. A/B bei ausgewähltem A→B-Trail).
List<Marker> buildEndpointMarkers({
  required Trail trail,
  required Trail? selected,
  required ValueChanged<Trail> onTrailSelected,
}) {
  final start = trail.startOrNull;
  if (start == null) return const [];
  final showAb = selected?.id == trail.id && trail.end != null;
  if (!showAb) {
    return [
      TypStartMarker.forTrail(
        trail,
        onTap: () => onTrailSelected(trail),
      ).toMarker(start, key: ValueKey('s-${trail.id}')),
    ];
  }
  return [
    TypStartMarker.letter(
      'A',
      onTap: () => onTrailSelected(trail),
    ).toMarker(start, key: ValueKey('s-${trail.id}')),
    TypStartMarker.letter(
      'B',
      inverted: true,
      onTap: () => onTrailSelected(trail),
    ).toMarker(trail.end!, key: ValueKey('e-${trail.id}')),
  ];
}
