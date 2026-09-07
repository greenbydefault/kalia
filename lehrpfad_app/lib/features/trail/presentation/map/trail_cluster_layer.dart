import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/map_config.dart';
import '../../../../core/config/map_motion.dart';
import '../../../../shared/widgets/typ_start_marker.dart';
import '../../domain/trail.dart';
import 'trail_cluster_index.dart';

/// Cluster-Layer der Übersichtskarte: besitzt Index und gefloorten Zoom,
/// folgt jeder Kamerabewegung über [MapController.mapEventStream].
class TrailClusterLayer extends StatefulWidget {
  const TrailClusterLayer({
    super.key,
    required this.mapController,
    required this.trails,
    required this.selectedId,
    required this.onTrailSelected,
    required this.onClusterTap,
  });

  final MapController mapController;
  final List<Trail>? trails;
  final String? selectedId;
  final ValueChanged<Trail> onTrailSelected;
  final void Function(TrailMapCluster cluster, List<LatLng> starts)
  onClusterTap;

  @override
  State<TrailClusterLayer> createState() => _TrailClusterLayerState();
}

class _TrailClusterLayerState extends State<TrailClusterLayer> {
  StreamSubscription<MapEvent>? _sub;
  TrailClusterIndex? _index;
  int _zoom = MapConfig.defaultZoom.floor();

  @override
  void initState() {
    super.initState();
    _rebuildIndex();
    _sub = widget.mapController.mapEventStream.listen(_onMapEvent);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _commitZoom(_readZoom());
    });
  }

  @override
  void didUpdateWidget(covariant TrailClusterLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mapController != widget.mapController) {
      unawaited(_sub?.cancel());
      _sub = widget.mapController.mapEventStream.listen(_onMapEvent);
    }
    if (_idSet(oldWidget.trails) != _idSet(widget.trails) ||
        oldWidget.selectedId != widget.selectedId) {
      _rebuildIndex();
    }
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  void _onMapEvent(MapEvent event) => _commitZoom(event.camera.zoom.floor());

  void _commitZoom(int z) {
    if (!mounted || z == _zoom) return;
    setState(() => _zoom = z);
  }

  int _readZoom() {
    try {
      return widget.mapController.camera.zoom.floor();
    } catch (_) {
      return MapConfig.defaultZoom.floor();
    }
  }

  void _rebuildIndex() {
    final trails = widget.trails;
    if (trails == null) {
      _index = null;
      return;
    }
    final selectedId = widget.selectedId;
    _index = TrailClusterIndex([
      for (final trail in trails)
        if (trail.id != selectedId) trail,
    ]);
  }

  static Set<String> _idSet(List<Trail>? trails) => {
    if (trails != null)
      for (final trail in trails) trail.id,
  };

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: buildClusterMarkers(
        index: _index,
        zoom: _zoom.toDouble(),
        onTrailSelected: widget.onTrailSelected,
        onClusterTap: (cluster) {
          final starts =
              _index?.startsIn(cluster.id, count: cluster.count) ?? const [];
          widget.onClusterTap(cluster, starts);
        },
      ),
    );
  }
}

const markerAppearDuration = MapMotion.markerAppear;

/// Baut die Cluster-/Trail-Marker für einen Zoom-Level aus dem Index.
List<Marker> buildClusterMarkers({
  required TrailClusterIndex? index,
  required double zoom,
  required ValueChanged<Trail> onTrailSelected,
  required void Function(TrailMapCluster cluster) onClusterTap,
}) {
  if (index == null) return const [];
  return [
    for (final node in index.nodesAt(zoom))
      switch (node) {
        TrailMapCluster() =>
          TypStartMarker.count(
            node.count,
            onTap: () => onClusterTap(node),
          ).toMarker(
            node.center,
            key: ValueKey('c-${node.id}'),
            wrap: (child) =>
                MarkerAppear(duration: markerAppearDuration, child: child),
          ),
        TrailMapPoint() =>
          TypStartMarker.forTrail(
            node.trail,
            onTap: () => onTrailSelected(node.trail),
          ).toMarker(
            node.trail.start,
            key: ValueKey('t-${node.trail.id}'),
            wrap: (child) =>
                MarkerAppear(duration: markerAppearDuration, child: child),
          ),
      },
  ];
}

/// Marker erscheint mit Fade+Scale, statt hart aufzutauchen.
class MarkerAppear extends StatefulWidget {
  const MarkerAppear({super.key, required this.duration, required this.child});

  final Duration duration;
  final Widget child;

  @override
  State<MarkerAppear> createState() => _MarkerAppearState();
}

class _MarkerAppearState extends State<MarkerAppear>
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
