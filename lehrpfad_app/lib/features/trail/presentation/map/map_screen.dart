import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../location/user_position_provider.dart';
import '../../../location/visible_trails_provider.dart';
import '../../../onboarding/data/onboarding_providers.dart';
import '../../../trail_progress/data/trail_progress_providers.dart';
import '../../../trail_progress/presentation/paused_tour_bar.dart';
import '../../../trail_progress/presentation/walk_mode_bar.dart';
import '../../../trail_progress/presentation/walk_route_layers.dart';
import '../../../trail_progress/presentation/walk_user_marker.dart';
import '../../../trail_progress/tracking/walk_tracking_controller.dart';
import '../../data/providers.dart';
import '../../domain/trail.dart';
import '../detail/trail_sheet.dart';
import 'locate_fab.dart';
import 'map_filters_overlay.dart';
import 'trail_overview_map.dart';

/// Startbildschirm: Übersichtskarte mit allen Trails.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  String? _lastStationPing;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walkSnapshotProvider.notifier).ensureTrackingForActiveWalk();
    });
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = ref.watch(onboardingActiveProvider);
    final trailsAsync = ref.watch(trailsProvider);
    final selected = ref.watch(selectedTrailProvider);
    final visibleTrails = ref.watch(visibleTrailsProvider);
    final snapshot = ref.watch(walkSnapshotProvider);
    final activeWalk = ref.watch(activeWalkProvider).asData?.value;
    final tourTracking = snapshot != null;
    final tourActive = activeWalk != null;
    final userFix = ref.watch(userPositionProvider).fix;
    final locateTarget = ref.watch(locateTargetProvider);
    final effectiveRadius = ref.watch(effectiveMapRadiusProvider);
    final selectedVisible =
        selected != null &&
            (visibleTrails?.any((t) => t.id == selected.id) ?? false)
        ? selected
        : null;

    ref.listen(visibleTrailsProvider, (prev, next) {
      final current = ref.read(selectedTrailProvider);
      if (current == null || next == null) return;
      if (!next.any((t) => t.id == current.id)) {
        ref.read(selectedTrailProvider.notifier).clear();
      }
    });

    ref.listen(walkSnapshotProvider, (prev, next) {
      final just = next?.justVisitedStationId;
      if (just == null || just == _lastStationPing) return;
      _lastStationPing = just;
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      final trails = trailsAsync.asData?.value;
      String label = 'Station erreicht';
      if (trails != null && next != null) {
        for (final t in trails) {
          if (t.id != next.trailId) continue;
          for (final s in t.stationen) {
            if (s.osmId.toString() == just) {
              label = 'Station: ${s.titel}';
              break;
            }
          }
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(label), duration: const Duration(seconds: 2)),
      );
    });

    final walkTrailId = snapshot?.trailId ?? activeWalk?.trailId;
    final walkRoute = _routeForWalk(
      trails: trailsAsync.asData?.value,
      selected: selected,
      trailId: walkTrailId,
    );
    final List<Polyline> walkPolylines =
        snapshot != null && walkRoute.length >= 2
        ? walkProgressPolylines(route: walkRoute, progressM: snapshot.progressM)
        : const [];
    final userMarkers = walkUserMarkers(
      tourTracking ? snapshot.rawPosition : userFix?.position,
    );
    final walkTrail = _trailById(trailsAsync.asData?.value, walkTrailId);

    return Scaffold(
      body: Stack(
        children: [
          IgnorePointer(
            ignoring: onboarding,
            child: TrailOverviewMap(
              trails: visibleTrails,
              selectedTrail: selectedVisible,
              onTrailSelected: (trail) =>
                  ref.read(selectedTrailProvider.notifier).select(trail),
              walkPolylines: walkPolylines,
              userMarkers: userMarkers,
              followPosition: snapshot?.rawPosition,
              locateTarget: locateTarget,
              userAnchor: effectiveRadius.isAll ? null : userFix?.position,
            ),
          ),
          if (!onboarding && !tourTracking && trailsAsync.value != null)
            MapFiltersOverlay(allTrails: trailsAsync.value!),
          if (!onboarding && trailsAsync.isLoading)
            const Center(child: CircularProgressIndicator()),
          if (!onboarding && trailsAsync.hasError)
            Center(
              child: Card(
                margin: const EdgeInsets.all(24),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Seed konnte nicht geladen werden:\n${trailsAsync.error}',
                  ),
                ),
              ),
            ),
          if (!onboarding && selectedVisible != null && !tourTracking)
            TrailSheet(
              trail: selectedVisible,
              onClose: () => ref.read(selectedTrailProvider.notifier).clear(),
            ),
          if (!onboarding && tourTracking)
            const Align(alignment: Alignment.bottomCenter, child: WalkModeBar())
          else if (!onboarding && tourActive && walkTrail != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: PausedTourBar(trail: walkTrail),
            ),
          if (!onboarding && !tourTracking)
            Positioned(
              right: 16,
              bottom: selectedVisible != null
                  ? MediaQuery.sizeOf(context).height * 0.32
                  : 24,
              child: const SafeArea(child: LocateFab()),
            ),
        ],
      ),
    );
  }

  List<LatLng> _routeForWalk({
    required List<Trail>? trails,
    required Trail? selected,
    required String? trailId,
  }) {
    if (trailId == null) return const [];
    if (selected?.id == trailId) return selected!.route;
    if (trails == null) return const [];
    for (final t in trails) {
      if (t.id == trailId) return t.route;
    }
    return const [];
  }

  Trail? _trailById(List<Trail>? trails, String? id) {
    if (trails == null || id == null) return null;
    for (final t in trails) {
      if (t.id == id) return t;
    }
    return null;
  }
}
