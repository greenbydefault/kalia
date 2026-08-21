import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/map_config.dart';
import '../../../../shared/widgets/typ_start_marker.dart';
import '../../../location/user_position_provider.dart';
import '../../domain/trail.dart';
import 'map_camera_animator.dart';
import 'trail_area_style.dart';
import 'trail_cluster_index.dart';
import 'trail_polyline_style.dart';

/// Vollflächige Übersichtskarte: Linien-Routen und Flächen-Polygone,
/// jeweils ein Start-Marker zum Öffnen des Detail-Sheets.
class TrailOverviewMap extends StatefulWidget {
  final List<Trail>? trails;
  final Trail? selectedTrail;
  final ValueChanged<Trail> onTrailSelected;
  final List<Polyline> walkPolylines;
  final List<Marker> userMarkers;
  final LatLng? followPosition;
  final LocateTarget? locateTarget;
  final LatLng? userAnchor;

  const TrailOverviewMap({
    super.key,
    required this.trails,
    required this.selectedTrail,
    required this.onTrailSelected,
    this.walkPolylines = const [],
    this.userMarkers = const [],
    this.followPosition,
    this.locateTarget,
    this.userAnchor,
  });

  @override
  State<TrailOverviewMap> createState() => _TrailOverviewMapState();
}

class _TrailOverviewMapState extends State<TrailOverviewMap>
    with TickerProviderStateMixin {
  final _mapController = MapController();

  late final MapCameraAnimator _cameraAnimator = MapCameraAnimator(
    mapController: _mapController,
    vsync: this,
  );

  late final AnimationController _trackFadeController = AnimationController(
    duration: _trackFadeDuration,
    vsync: this,
  )..addListener(_onTrackFade);

  static const _trackFadeDuration = Duration(milliseconds: 450);
  static const _fitPadding = EdgeInsets.fromLTRB(48, 88, 48, 48);
  static const _markerAppearDuration = Duration(milliseconds: 200);

  double _trackOpacity = 0;
  Object? _flyToken;
  int _boundsFitGen = 0;
  bool _followPaused = false;
  int _clusterZoom = MapConfig.defaultZoom.floor();
  TrailClusterIndex? _clusterIndex;

  @override
  void initState() {
    super.initState();
    if (widget.selectedTrail != null) _trackOpacity = 1;
    _rebuildClusterIndex();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncClusterZoom(_mapController.camera.zoom);
    });
  }

  @override
  void dispose() {
    _cameraAnimator.dispose();
    _trackFadeController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onTrackFade() {
    if (mounted) setState(() => _trackOpacity = _trackFadeController.value);
  }

  @override
  void didUpdateWidget(covariant TrailOverviewMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_idSet(oldWidget.trails) != _idSet(widget.trails) ||
        oldWidget.selectedTrail?.id != widget.selectedTrail?.id) {
      _rebuildClusterIndex();
    }
    final locate = widget.locateTarget;
    final locateChanged =
        locate != null && locate != oldWidget.locateTarget;

    final selected = widget.selectedTrail;
    if (selected == null) {
      final deselected = oldWidget.selectedTrail != null;
      if (deselected) {
        _flyToken = null;
        _cameraAnimator.cancel();
        _trackFadeController.stop();
        _trackOpacity = 0;
      }
      final oldIds = _idSet(oldWidget.trails);
      final newIds = _idSet(widget.trails);
      if (!deselected &&
          !locateChanged &&
          oldIds != newIds &&
          newIds.isNotEmpty) {
        final gen = ++_boundsFitGen;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || widget.selectedTrail != null) return;
          if (gen != _boundsFitGen) return;
          final pts = _allPoints(
            widget.trails!,
            anchor: widget.userAnchor,
          );
          if (pts.isEmpty) return;
          unawaited(
            _cameraAnimator.flyToBounds(
              LatLngBounds.fromPoints(pts),
              padding: _fitPadding,
            ),
          );
        });
      }
    } else if (selected.id != oldWidget.selectedTrail?.id) {
      _followPaused = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || widget.selectedTrail?.id != selected.id) return;
        unawaited(_flyToTrail(selected));
      });
    }

    final follow = widget.followPosition;
    if (follow != null &&
        !_followPaused &&
        follow != oldWidget.followPosition) {
      _mapController.move(follow, _mapController.camera.zoom);
    }

    if (locate != null && locateChanged) {
      _followPaused = true;
      _boundsFitGen++;
      final zoom = _mapController.camera.zoom < MapConfig.locateZoom
          ? MapConfig.locateZoom
          : _mapController.camera.zoom;
      unawaited(_cameraAnimator.flyTo(locate.position, zoom));
    }
  }

  void _rebuildClusterIndex() {
    final trails = widget.trails;
    if (trails == null) {
      _clusterIndex = null;
      return;
    }
    final selectedId = widget.selectedTrail?.id;
    _clusterIndex = TrailClusterIndex([
      for (final trail in trails)
        if (trail.id != selectedId) trail,
    ]);
  }

  void _syncClusterZoom(double zoom) {
    final z = zoom.floor();
    if (z == _clusterZoom) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || z == _clusterZoom) return;
      setState(() => _clusterZoom = z);
    });
  }

  static Set<String> _idSet(List<Trail>? trails) => {
    if (trails != null)
      for (final trail in trails) trail.id,
  };

  static List<LatLng> _allPoints(List<Trail> trails, {LatLng? anchor}) => [
    for (final trail in trails) ...trail.mapPoints,
    ?anchor,
  ];

  List<Marker> _endpointMarkers(Trail trail, Trail? selected) {
    final start = trail.startOrNull;
    if (start == null) return const [];
    final showAb = selected?.id == trail.id && trail.end != null;
    if (!showAb) {
      return [
        TypStartMarker(
          typ: trail.typ,
          onTap: () => widget.onTrailSelected(trail),
        ).toMarker(start, key: ValueKey('s-${trail.id}')),
      ];
    }
    return [
      TypStartMarker.letter(
        'A',
        onTap: () => widget.onTrailSelected(trail),
      ).toMarker(start, key: ValueKey('s-${trail.id}')),
      TypStartMarker.letter(
        'B',
        inverted: true,
        onTap: () => widget.onTrailSelected(trail),
      ).toMarker(trail.end!, key: ValueKey('e-${trail.id}')),
    ];
  }

  List<Marker> _clusterMarkers() {
    final index = _clusterIndex;
    if (index == null) return const [];
    return [
      for (final node in index.nodesAt(_clusterZoom.toDouble()))
        switch (node) {
          TrailMapCluster() => TypStartMarker.count(
            node.count,
            onTap: () {
              _followPaused = true;
              unawaited(
                _cameraAnimator.flyTo(
                  node.center,
                  node.expansionZoom.toDouble(),
                ),
              );
            },
          ).toMarker(
            node.center,
            key: ValueKey('c-${node.id}'),
            wrap: (child) => _MarkerAppear(
              duration: _markerAppearDuration,
              child: child,
            ),
          ),
          TrailMapPoint() => TypStartMarker(
            typ: node.trail.typ,
            onTap: () => widget.onTrailSelected(node.trail),
          ).toMarker(
            node.trail.start,
            key: ValueKey('t-${node.trail.id}'),
            wrap: (child) => _MarkerAppear(
              duration: _markerAppearDuration,
              child: child,
            ),
          ),
        },
    ];
  }

  Future<void> _flyToTrail(Trail trail) async {
    final token = Object();
    _flyToken = token;

    _trackFadeController.stop();
    setState(() => _trackOpacity = 0);

    final pts = trail.mapPoints;
    if (pts.isEmpty) return;

    await _cameraAnimator.flyToBounds(
      LatLngBounds.fromPoints(pts),
      padding: _fitPadding,
    );

    if (!mounted || !identical(_flyToken, token)) return;
    unawaited(_trackFadeController.forward(from: 0));
  }

  @override
  Widget build(BuildContext context) {
    final trails = widget.trails;
    final selectedTrail = widget.selectedTrail;
    final allPoints = trails != null
        ? _allPoints(trails, anchor: widget.userAnchor)
        : <LatLng>[
            if (widget.userAnchor != null) widget.userAnchor!,
          ];
    final inWalk = widget.walkPolylines.isNotEmpty;

    final flaechen = trails?.where((t) => t.isFlaeche).toList() ?? const [];
    final selectedFlaeche = selectedTrail != null && selectedTrail.isFlaeche
        ? selectedTrail
        : null;
    final selectedLinie = selectedTrail != null && selectedTrail.isLinie
        ? selectedTrail
        : null;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: MapConfig.defaultCenter,
        initialZoom: MapConfig.defaultZoom,
        initialCameraFit: allPoints.isNotEmpty
            ? CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(allPoints),
                padding: _fitPadding,
              )
            : null,
        onPositionChanged: (camera, hasGesture) {
          if (hasGesture && widget.followPosition != null) {
            _followPaused = true;
          }
          _syncClusterZoom(camera.zoom);
        },
      ),
      children: [
        MapConfig.buildOsmTileLayer(),
        if (trails != null) ...[
          if (flaechen.isNotEmpty)
            PolygonLayer(
              polygons: [
                for (final trail in flaechen)
                  if (trail.area.length >= 3)
                    Polygon(
                      points: trail.area,
                      color: TrailAreaStyle.fill.withValues(
                        alpha: trail.id == selectedFlaeche?.id
                            ? TrailAreaStyle.fillOpacitySelected *
                                  (_trackOpacity <= 0 ? 1.0 : _trackOpacity)
                            : TrailAreaStyle.fillOpacityOverview,
                      ),
                      borderColor: TrailAreaStyle.border.withValues(
                        alpha: trail.id == selectedFlaeche?.id
                            ? (_trackOpacity <= 0 ? 1.0 : _trackOpacity)
                            : 0.7,
                      ),
                      borderStrokeWidth: trail.id == selectedFlaeche?.id
                          ? TrailAreaStyle.borderWidthSelected
                          : TrailAreaStyle.borderWidthOverview,
                    ),
              ],
            ),
          if (selectedLinie != null &&
              !inWalk &&
              selectedLinie.route.length >= 2)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: selectedLinie.route,
                  strokeWidth: TrailPolylineStyle.strokeWidth,
                  color: TrailPolylineStyle.color.withValues(
                    alpha: _trackOpacity,
                  ),
                  pattern: TrailPolylineStyle.pattern,
                ),
              ],
            ),
          if (inWalk) PolylineLayer(polylines: widget.walkPolylines),
          MarkerLayer(markers: _clusterMarkers()),
          if (selectedTrail != null)
            MarkerLayer(
              markers: _endpointMarkers(selectedTrail, selectedTrail),
            ),
          if (widget.userMarkers.isNotEmpty)
            MarkerLayer(markers: widget.userMarkers),
        ],
      ],
    );
  }
}

class _MarkerAppear extends StatefulWidget {
  const _MarkerAppear({
    super.key,
    required this.duration,
    required this.child,
  });

  final Duration duration;
  final Widget child;

  @override
  State<_MarkerAppear> createState() => _MarkerAppearState();
}

class _MarkerAppearState extends State<_MarkerAppear>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: ScaleTransition(
        scale: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
        child: widget.child,
      ),
    );
  }
}
