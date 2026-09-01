import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/shell_tab_provider.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../shared/widgets/sheet_motion.dart';
import '../../../community/presentation/upload_fab.dart';
import '../../../location/user_position_provider.dart';
import '../../../location/visible_trails_provider.dart';
import '../../../nearby/data/nearby_providers.dart';
import '../../../nearby/domain/nearby.dart';
import '../../../nearby/presentation/nearby_peek_card.dart';
import '../../../onboarding/data/onboarding_providers.dart';
import '../../../trail_progress/data/trail_progress_providers.dart';
import '../../../trail_progress/presentation/paused_tour_bar.dart';
import '../../../trail_progress/presentation/walk_mode_bar.dart';
import '../../../trail_progress/tracking/walk_snapshot.dart';
import '../../../trail_progress/tracking/walk_tracking_controller.dart';
import '../../data/providers.dart';
import '../../domain/trail.dart';
import '../detail/trail_detail_page.dart';
import 'locate_fab.dart';
import 'map_filters_overlay.dart';
import 'tour_map_state.dart';
import 'trail_overview_map.dart';
import 'trail_peek_card.dart';

typedef _WalkMapBits = ({
  String? trailId,
  double? progressM,
  LatLng? rawPosition,
  String? justVisitedStationId,
});

_WalkMapBits _walkMapBits(WalkSnapshot? s) {
  if (s == null) {
    return (
      trailId: null,
      progressM: null,
      rawPosition: null,
      justVisitedStationId: null,
    );
  }
  return (
    trailId: s.trailId,
    progressM: s.progressM,
    rawPosition: s.rawPosition,
    justVisitedStationId: s.justVisitedStationId,
  );
}

/// Startbildschirm: Übersichtskarte mit allen Trails.
///
/// Auswahl-Flow: Tap auf Trail → Peek-Card unten, Kartenkamera fittet
/// die Trail-Geometrie (Peek als Padding). Tap auf die Card → Detail
/// slidet von rechts rein; die Karte bleibt hinter dem Detail liegen
/// und wird bei voller Deckung geparkt (TickerMode aus, Kamera-State
/// bleibt erhalten).
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with TickerProviderStateMixin {
  String? _lastStationPing;
  Trail? _cachedPeekTrail;
  bool _mapParked = false;

  late final AnimationController _detailController = AnimationController(
    vsync: this,
    duration: SheetMotion.enter,
    reverseDuration: SheetMotion.exit,
  )..addStatusListener(_onDetailStatus);

  late final AnimationController _peekController = AnimationController(
    vsync: this,
    duration: SheetMotion.size,
    reverseDuration: SheetMotion.exit,
  );

  late final CurvedAnimation _detailCurve = CurvedAnimation(
    parent: _detailController,
    curve: SheetMotion.enterCurve,
    reverseCurve: SheetMotion.exitCurve,
  );

  late final CurvedAnimation _peekCurve = CurvedAnimation(
    parent: _peekController,
    curve: SheetMotion.enterCurve,
    reverseCurve: SheetMotion.exitCurve,
  );

  /// Ab 40% der Detail-Transition: Karte rutscht leicht nach unten,
  /// Locate-FAB wird ausgeblendet.
  static const _mapFade = Interval(0.4, 1.0);

  /// Peek-Card verschwindet in der ersten Phase der Detail-Transition.
  static const _peekHide = Interval(0.0, 0.3);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walkSnapshotProvider.notifier).ensureTrackingForActiveWalk();
    });
  }

  @override
  void dispose() {
    _detailCurve.dispose();
    _peekCurve.dispose();
    _detailController.dispose();
    _peekController.dispose();
    super.dispose();
  }

  void _onDetailStatus(AnimationStatus status) {
    final parked = status == AnimationStatus.completed;
    if (parked != _mapParked && mounted) {
      setState(() => _mapParked = parked);
    }
  }

  void _openDetail() => _detailController.forward();

  void _closeDetail() => _detailController.reverse();

  void _onTourStarted() {
    _detailController.value = 0;
    ref.read(selectedTrailProvider.notifier).clear();
  }

  void _onDetailDragUpdate(DragUpdateDetails details) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= 0) return;
    _detailController.value =
        (_detailController.value - details.delta.dx / width).clamp(0.0, 1.0);
  }

  void _onDetailDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity > 400 || _detailController.value < 0.6) {
      _detailController.reverse();
    } else {
      _detailController.forward();
    }
  }

  void _onPeekDragUpdate(DragUpdateDetails details) {
    _peekController.value =
        (_peekController.value - details.delta.dy / TrailPeekCard.height).clamp(
          0.0,
          1.0,
        );
  }

  void _onPeekDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity > 300 || _peekController.value < 0.5) {
      ref.read(selectedTrailProvider.notifier).clear();
    } else {
      _peekController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = ref.watch(onboardingActiveProvider);
    final trailsAsync = ref.watch(trailsProvider);
    final selected = ref.watch(selectedTrailProvider);
    final visibleTrails = ref.watch(visibleTrailsProvider);
    final activeWalk = ref.watch(activeWalkProvider).asData?.value;
    final userFix = ref.watch(userPositionProvider).fix;
    final locateTarget = ref.watch(locateTargetProvider);
    final effectiveRadius = ref.watch(effectiveMapRadiusProvider);
    final pendingCameraTrailId = ref.watch(pendingCameraTrailProvider);
    ref.watch(nearbyCatalogProvider);
    final selectedVisible =
        selected != null &&
            (visibleTrails?.any((t) => t.id == selected.id) ?? false)
        ? selected
        : null;
    final selectedNearby = ref.watch(selectedNearbyPlaceProvider);
    final nearbyPlaces = selectedVisible == null
        ? const <NearbyTreffer>[]
        : ref.watch(nearbyPlacesProvider(selectedVisible.id)).asData?.value ??
              const <NearbyTreffer>[];

    final onMapTab = ref.watch(shellTabIndexProvider) == 0;
    final walkTrailId = onMapTab
        ? ref.watch(walkSnapshotProvider.select((s) => s?.trailId))
        : ref.read(walkSnapshotProvider)?.trailId;
    final tourTracking = walkTrailId != null;
    final tourActive = activeWalk != null;

    final peekTrail =
        selectedVisible ??
        (_peekController.value > 0 ? _cachedPeekTrail : null);

    ref.listen(selectedTrailProvider, (prev, next) {
      final prevId = prev?.id;
      final nextId = next?.id;
      if (next != null) _cachedPeekTrail = next;
      if (prevId != nextId) {
        ref.read(selectedNearbyPlaceProvider.notifier).clear();
      }
      if (nextId == null) {
        _detailController.value = 0;
        _peekController.reverse();
      } else if (prevId == null) {
        _peekController.forward(from: 0);
      } else if (prevId != nextId) {
        // Trailwechsel bei offener Card: Inhalt tauscht, Card bleibt.
        _detailController.value = 0;
        if (_peekController.value < 1) _peekController.forward();
      }
    });

    ref.listen(visibleTrailsProvider, (prev, next) {
      final current = ref.read(selectedTrailProvider);
      if (current == null || next == null) return;
      if (!next.any((t) => t.id == current.id)) {
        ref.read(selectedTrailProvider.notifier).clear();
        ref.read(pendingCameraTrailProvider.notifier).clear();
      }
    });

    ref.listen(walkSnapshotProvider.select((s) => s?.justVisitedStationId), (
      prev,
      just,
    ) {
      if (ref.read(shellTabIndexProvider) != 0) return;
      if (just == null || just == _lastStationPing) return;
      _lastStationPing = just;
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      final trails = trailsAsync.asData?.value;
      String label = 'Station erreicht';
      final trailId = walkTrailId;
      if (trails != null && trailId != null) {
        for (final t in trails) {
          if (t.id != trailId) continue;
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

    final resolvedWalkTrailId = walkTrailId ?? activeWalk?.trailId;
    final walkRoute = _routeForWalk(
      trails: trailsAsync.asData?.value,
      selected: selected,
      trailId: resolvedWalkTrailId,
    );
    final walkTrail = _trailById(
      trailsAsync.asData?.value,
      resolvedWalkTrailId,
    );

    return PopScope(
      canPop: selectedVisible == null,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_detailController.value > 0.001) {
          _closeDetail();
        } else {
          ref.read(selectedTrailProvider.notifier).clear();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            AnimatedBuilder(
              animation: _detailController,
              builder: (context, child) {
                final t = _detailCurve.value;
                if (t <= 0.001) {
                  return IgnorePointer(ignoring: onboarding, child: child);
                }
                final fadeT = _mapFade.transform(t);
                return IgnorePointer(
                  ignoring: true,
                  child: Transform.translate(
                    offset: Offset(0, fadeT * 28),
                    child: child,
                  ),
                );
              },
              child: TickerMode(
                enabled: !_mapParked,
                child: _WalkMapLayer(
                  trails: visibleTrails,
                  selectedVisible: selectedVisible,
                  nearbyPlaces: nearbyPlaces,
                  selectedNearby: selectedNearby,
                  walkRoute: walkRoute,
                  userFix: userFix?.position,
                  locateTarget: locateTarget,
                  userAnchor: effectiveRadius.isAll ? null : userFix?.position,
                  onMapTab: onMapTab,
                  pendingCameraTrailId: pendingCameraTrailId,
                  onPendingCameraConsumed: () =>
                      ref.read(pendingCameraTrailProvider.notifier).clear(),
                ),
              ),
            ),
            if (!onboarding &&
                !tourTracking &&
                selectedVisible == null &&
                trailsAsync.value != null)
              MapFiltersOverlay(allTrails: trailsAsync.value!),
            if (!onboarding && !tourTracking && selectedNearby != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12 + TrailPeekCard.height + 8,
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _peekController,
                    _detailController,
                  ]),
                  builder: (context, _) {
                    final enter = _peekCurve.value;
                    final vis =
                        enter * (1 - _peekHide.transform(_detailCurve.value));
                    if (vis <= 0.001) return const SizedBox.shrink();
                    return Opacity(
                      opacity: vis,
                      child: NearbyPeekCard(
                        key: ValueKey(selectedNearby.place.id),
                        treffer: selectedNearby,
                        onClose: () => ref
                            .read(selectedNearbyPlaceProvider.notifier)
                            .clear(),
                      ),
                    );
                  },
                ),
              ),
            if (!onboarding && !tourTracking && peekTrail != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _peekController,
                    _detailController,
                  ]),
                  builder: (context, _) {
                    final enter = _peekCurve.value;
                    final vis =
                        enter * (1 - _peekHide.transform(_detailCurve.value));
                    if (vis <= 0.001) return const SizedBox.shrink();
                    return Opacity(
                      opacity: vis,
                      child: FractionalTranslation(
                        translation: Offset(0, (1 - enter) * 0.3),
                        child: TrailPeekCard(
                          key: ValueKey(peekTrail.id),
                          trail: peekTrail,
                          onOpen: _openDetail,
                          onClose: () =>
                              ref.read(selectedTrailProvider.notifier).clear(),
                          onTourStarted: _onTourStarted,
                          onVerticalDragUpdate: _onPeekDragUpdate,
                          onVerticalDragEnd: _onPeekDragEnd,
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (!onboarding && !tourTracking && selectedVisible != null)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _detailController,
                  builder: (context, child) {
                    final t = _detailCurve.value;
                    if (t <= 0.001) return const SizedBox.shrink();
                    return FractionalTranslation(
                      translation: Offset(1 - t, 0),
                      child: child!,
                    );
                  },
                  child: RepaintBoundary(
                    child: TrailDetailPage(
                      key: ValueKey(selectedVisible.id),
                      trail: selectedVisible,
                      onClose: _closeDetail,
                      onTourStarted: _onTourStarted,
                      onHorizontalDragUpdate: _onDetailDragUpdate,
                      onHorizontalDragEnd: _onDetailDragEnd,
                    ),
                  ),
                ),
              ),
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
            if (!onboarding && tourTracking)
              const Align(
                alignment: Alignment.bottomCenter,
                child: WalkModeBar(),
              )
            else if (!onboarding && tourActive && walkTrail != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: PausedTourBar(trail: walkTrail),
              ),
            if (!onboarding && !tourTracking)
              AnimatedBuilder(
                animation: Listenable.merge([
                  _peekController,
                  _detailController,
                ]),
                builder: (context, child) {
                  final hidden = _mapFade.transform(_detailCurve.value) > 0;
                  final extra = selectedNearby != null
                      ? NearbyPeekCard.height + 8
                      : 0;
                  return Positioned(
                    right: 16,
                    bottom:
                        24 + _peekCurve.value * (TrailPeekCard.height + extra),
                    child: Offstage(
                      offstage: hidden,
                      child: IgnorePointer(ignoring: hidden, child: child),
                    ),
                  );
                },
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (SupabaseConfig.isConfigured) ...[
                        UploadFab(trail: peekTrail),
                        const SizedBox(height: 8),
                      ],
                      const LocateFab(),
                    ],
                  ),
                ),
              ),
          ],
        ),
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

class _WalkMapLayer extends ConsumerWidget {
  const _WalkMapLayer({
    required this.trails,
    required this.selectedVisible,
    required this.nearbyPlaces,
    required this.selectedNearby,
    required this.walkRoute,
    required this.userFix,
    required this.locateTarget,
    required this.userAnchor,
    required this.onMapTab,
    required this.pendingCameraTrailId,
    required this.onPendingCameraConsumed,
  });

  final List<Trail>? trails;
  final Trail? selectedVisible;
  final List<NearbyTreffer> nearbyPlaces;
  final NearbyTreffer? selectedNearby;
  final List<LatLng> walkRoute;
  final LatLng? userFix;
  final LocateTarget? locateTarget;
  final LatLng? userAnchor;
  final bool onMapTab;
  final String? pendingCameraTrailId;
  final VoidCallback onPendingCameraConsumed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bits = onMapTab
        ? ref.watch(walkSnapshotProvider.select(_walkMapBits))
        : _walkMapBits(ref.read(walkSnapshotProvider));
    return RepaintBoundary(
      child: TrailOverviewMap(
        trails: trails,
        selectedTrail: selectedVisible,
        onTrailSelected: (trail) =>
            ref.read(selectedTrailProvider.notifier).select(trail),
        nearbyPlaces: nearbyPlaces,
        selectedNearby: selectedNearby,
        onNearbySelected: (treffer) =>
            ref.read(selectedNearbyPlaceProvider.notifier).select(treffer),
        tour: TourMapState(
          route: walkRoute,
          progressM: bits.progressM,
          rawPosition: bits.rawPosition,
          tracking: bits.trailId != null,
          idlePosition: userFix,
        ),
        locateTarget: locateTarget,
        userAnchor: userAnchor,
        pendingCameraTrailId: pendingCameraTrailId,
        onPendingCameraConsumed: onPendingCameraConsumed,
      ),
    );
  }
}
