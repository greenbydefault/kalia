import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../../core/config/map_config.dart';
import '../../../../core/config/map_motion.dart';
import '../../domain/trail.dart';
import 'camera_target.dart';
import 'map_camera_animator.dart';
import 'trail_area_style.dart';
import 'trail_overview_map.dart';
import 'trail_polyline_style.dart';

/// Mini-OSM-Karte im Hero der Trail-Detailseite: fittet beim ersten
/// Sichtbarwerden animiert auf den Trail, danach Pan/Zoom frei.
/// Kein Fade, kein Cluster.
class TrailHeroMap extends StatefulWidget {
  const TrailHeroMap({
    super.key,
    required this.trail,
    this.animateWhenVisible = false,
  });

  final Trail trail;

  /// Der Hero liegt im IndexedStack neben dem Foto-Pager und wird sofort
  /// gebaut; der animierte Fit startet erst, wenn dieses Flag true wird.
  final bool animateWhenVisible;

  @override
  State<TrailHeroMap> createState() => _TrailHeroMapState();
}

class _TrailHeroMapState extends State<TrailHeroMap>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late final MapCameraAnimator _animator = MapCameraAnimator(
    mapController: _mapController,
    vsync: this,
  );

  bool _fitScheduled = false;

  @override
  void initState() {
    super.initState();
    if (widget.animateWhenVisible) _scheduleFit();
  }

  @override
  void didUpdateWidget(covariant TrailHeroMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animateWhenVisible && !oldWidget.animateWhenVisible) {
      _scheduleFit();
    }
  }

  void _scheduleFit() {
    if (_fitScheduled) return;
    _fitScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = CameraTarget.fromTrail(
        widget.trail,
        padding: CameraTarget.heroPadding,
      );
      if (target == null) return;
      unawaited(
        _animator.flyToBounds(
          target.bounds,
          padding: target.padding,
          duration: MapMotion.fit,
          curve: MapMotion.fitCurve,
        ),
      );
    });
  }

  @override
  void dispose() {
    _animator.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trail = widget.trail;
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: trail.startOrNull ?? MapConfig.defaultCenter,
        initialZoom: MapConfig.defaultZoom,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        MapConfig.buildOsmTileLayer(),
        if (trail.isFlaeche && trail.area.length >= 3)
          PolygonLayer(
            polygons: [
              Polygon(
                points: trail.area,
                color: TrailAreaStyle.fill.withValues(
                  alpha: TrailAreaStyle.fillOpacitySelected,
                ),
                borderColor: TrailAreaStyle.border,
                borderStrokeWidth: TrailAreaStyle.borderWidthSelected,
              ),
            ],
          ),
        if (trail.isLinie && trail.route.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: trail.route,
                strokeWidth: TrailPolylineStyle.strokeWidth,
                color: TrailPolylineStyle.color,
                pattern: TrailPolylineStyle.pattern,
              ),
            ],
          ),
        MarkerLayer(
          markers: buildEndpointMarkers(
            trail: trail,
            selected: trail,
            onTrailSelected: (_) {},
          ),
        ),
      ],
    );
  }
}
