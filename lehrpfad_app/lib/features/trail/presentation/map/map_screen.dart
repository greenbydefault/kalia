import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../app/theme/app_spacing.dart';

import '../../../../app/shell_tab_provider.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../shared/widgets/sheet_motion.dart';
import '../../../community/presentation/upload_fab.dart';
import '../../../location/user_position_provider.dart';
import '../../../location/visible_trails_provider.dart';
import '../../../nearby/data/nearby_providers.dart';
import '../../../nearby/domain/nearby.dart';
import '../../../nearby/presentation/nearby_peek_card.dart';
import '../../../nearby_trails/data/bezug_provider.dart';
import '../../../nearby_trails/data/karte_state.dart';
import '../../../nearby_trails/domain/bezugspunkt.dart';
import '../../../nearby_trails/domain/karte_copy.dart';
import '../../../nearby_trails/domain/karte_logik.dart';
import '../../../nearby_trails/presentation/bezug_aktionen.dart';
import '../../../nearby_trails/presentation/nearby_trails_panel.dart';
import '../../../nearby_trails/presentation/ortssuche_page.dart';
import '../../../player/data/mini_player_provider.dart';
import '../../../player/presentation/mini_player.dart';
import '../../../trail_progress/data/trail_progress_providers.dart';
import '../../../trail_progress/presentation/paused_tour_bar.dart';
import '../../../trail_progress/presentation/walk_mode_bar.dart';
import '../../../trail_progress/tracking/walk_snapshot.dart';
import '../../../trail_progress/tracking/walk_tracking_controller.dart';
import '../../data/providers.dart';
import '../../domain/trail.dart';
import '../detail/trail_detail_page.dart';
import 'locate_fab.dart';
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

  /// Höhe des Nähe-Panels in px (für den FAB-Versatz).
  final ValueNotifier<double> _panelHeight = ValueNotifier(0);

  /// Kartenmitte, wenn „In diesem Bereich suchen“ sichtbar sein soll.
  final ValueNotifier<LatLng?> _bereichMitte = ValueNotifier(null);

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
    _panelHeight.dispose();
    _bereichMitte.dispose();
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
    final trailsAsync = ref.watch(trailsProvider);
    final selected = ref.watch(selectedTrailProvider);
    final visibleTrails = ref.watch(visibleTrailsProvider);
    final activeWalk = ref.watch(activeWalkProvider).asData?.value;
    final userFix = ref.watch(userPositionProvider).fix;
    final locateTarget = ref.watch(locateTargetProvider);
    final bezug = ref.watch(aktuellerBezugProvider);
    final umkreis = ref.watch(umkreisProvider);
    final sheetHoehe = ref.watch(sheetHoeheProvider);
    final pendingCameraTrailId = ref.watch(pendingCameraTrailProvider);
    ref.watch(nearbyCatalogProvider);
    ref.watch(nearbyZeitenProvider);
    // Auch Einträge außerhalb von M (aus der Suche) dürfen offen sein.
    final selectedVisible = selected;
    final selectedNearby = ref.watch(selectedNearbyPlaceProvider);
    final nearbyPlaces = selectedVisible == null
        ? const <NearbyTreffer>[]
        : ref.watch(nearbyPlacesProvider(selectedVisible.id)).asData?.value ??
              const <NearbyTreffer>[];

    final playerExtra = ref.watch(
      miniPlayerProvider.select((s) => s == null ? 0.0 : MiniPlayerHost.height),
    );
    final onMapTab = ref.watch(shellTabIndexProvider) == 0;
    final walkTrailId = onMapTab
        ? ref.watch(walkSnapshotProvider.select((s) => s?.trailId))
        : ref.read(walkSnapshotProvider)?.trailId;
    final tourTracking = walkTrailId != null;
    final tourActive = activeWalk != null;
    final panelVisible =
        !tourTracking && !tourActive && selectedVisible == null;
    final screenH = MediaQuery.sizeOf(context).height;
    // Unterer Kartenrand für Fits: Sheet-Höhe, bei ganz wie halb.
    final mapBottomInset = !panelVisible
        ? 0.0
        : sheetHoehe == SheetHoehe.eingeklappt
        ? NearbyTrailsPanel.kopfHoehe + AppSpacing.x2
        : NearbyTrailsPanel.halbSize * screenH;

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

    ref.listen(detailAnfrageProvider, (_, _) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ref.read(selectedTrailProvider) != null) _openDetail();
      });
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

    final sheetGanz = onMapTab && panelVisible && sheetHoehe == SheetHoehe.ganz;
    return PopScope(
      canPop: selectedVisible == null && !sheetGanz,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_detailController.value > 0.001) {
          _closeDetail();
        } else if (selectedVisible != null) {
          ref.read(selectedTrailProvider.notifier).clear();
        } else if (sheetGanz) {
          ref.read(sheetHoeheProvider.notifier).set(SheetHoehe.halb);
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
                  return child!;
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
                  userFix: bezug?.quelle == BezugQuelle.gps
                      ? (userFix?.position ?? bezug?.coords)
                      : null,
                  locateTarget: locateTarget,
                  userAnchor: bezug?.coords,
                  framePlace: bezug?.quelle == BezugQuelle.suche,
                  bezugPin: bezug != null && bezug.quelle != BezugQuelle.gps
                      ? bezug.coords
                      : null,
                  umkreisM: bezug == null ? null : umkreisMeter(umkreis),
                  bottomInset: mapBottomInset,
                  onBereichSuchen: (mitte) => _bereichMitte.value = mitte,
                  onMapTap: () {
                    if (ref.read(selectedTrailProvider) != null) {
                      ref.read(selectedTrailProvider.notifier).clear();
                    }
                  },
                  onMapTab: onMapTab,
                  pendingCameraTrailId: pendingCameraTrailId,
                  onPendingCameraConsumed: () =>
                      ref.read(pendingCameraTrailProvider.notifier).clear(),
                ),
              ),
            ),
            if (!tourTracking && selectedVisible != null)
              Positioned(
                top: 0,
                left: AppSpacing.x3,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.x2),
                    child: AnimatedBuilder(
                      animation: _detailController,
                      builder: (context, child) => Opacity(
                        opacity: 1 - _peekHide.transform(_detailCurve.value),
                        child: child,
                      ),
                      child: ActionChip(
                        avatar: const PhosphorIcon(
                          PhosphorIcons.caretLeft,
                          size: 16,
                        ),
                        label: Text(kt('karte.zurueckListe')),
                        onPressed: () =>
                            ref.read(selectedTrailProvider.notifier).clear(),
                      ),
                    ),
                  ),
                ),
              ),
            if (panelVisible && onMapTab)
              _BereichSuchenButton(notifier: _bereichMitte),
            if (!tourTracking && selectedNearby != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12 + playerExtra + TrailPeekCard.height + 8,
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
            if (!tourTracking && peekTrail != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12 + playerExtra,
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
            if (!tourTracking && selectedVisible != null)
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
            if (panelVisible)
              Positioned.fill(
                child: NearbyTrailsPanel(
                  bottomInset: playerExtra,
                  onHeightChanged: (px) => _panelHeight.value = px,
                ),
              ),
            if (trailsAsync.isLoading && !panelVisible)
              const Center(child: CircularProgressIndicator()),
            if (tourTracking)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: playerExtra),
                  child: const WalkModeBar(),
                ),
              )
            else if (tourActive && walkTrail != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: playerExtra),
                  child: PausedTourBar(trail: walkTrail),
                ),
              ),
            if (!tourTracking)
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
                  return ValueListenableBuilder<double>(
                    valueListenable: _panelHeight,
                    builder: (context, panelH, _) {
                      final panel = panelVisible ? panelH : 0.0;
                      final tooHigh =
                          panel > MediaQuery.sizeOf(context).height * 0.7;
                      final off = hidden || tooHigh;
                      return Positioned(
                        right: 16,
                        // Knapp über der Sheet-Oberkante, wandert mit.
                        bottom:
                            12 +
                            playerExtra +
                            panel +
                            _peekCurve.value * (TrailPeekCard.height + extra),
                        child: Offstage(
                          offstage: off,
                          child: IgnorePointer(ignoring: off, child: child),
                        ),
                      );
                    },
                  );
                },
                child: const LocateFab(),
              ),
            // Kartenleiste: Suchen, Melden. Bei Sheet ganz offen weg.
            if (!tourTracking &&
                !(panelVisible && sheetHoehe == SheetHoehe.ganz))
              AnimatedBuilder(
                animation: _detailController,
                builder: (context, child) {
                  final hidden = _mapFade.transform(_detailCurve.value) > 0;
                  return Positioned(
                    top: 0,
                    right: AppSpacing.x4,
                    child: Offstage(
                      offstage: hidden,
                      child: IgnorePointer(ignoring: hidden, child: child),
                    ),
                  );
                },
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.x2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FloatingActionButton.small(
                          heroTag: 'suchen',
                          tooltip: kt('karte.suchen'),
                          onPressed: () => openOrtssuche(context),
                          child: const PhosphorIcon(
                            PhosphorIcons.magnifyingGlass,
                          ),
                        ),
                        if (SupabaseConfig.isConfigured) ...[
                          const SizedBox(height: AppSpacing.x2),
                          UploadFab(trail: peekTrail),
                        ],
                      ],
                    ),
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
    required this.framePlace,
    required this.onMapTab,
    required this.pendingCameraTrailId,
    required this.onPendingCameraConsumed,
    required this.bezugPin,
    required this.umkreisM,
    required this.bottomInset,
    required this.onBereichSuchen,
    required this.onMapTap,
  });

  final LatLng? bezugPin;
  final double? umkreisM;
  final double bottomInset;
  final ValueChanged<LatLng?> onBereichSuchen;
  final VoidCallback onMapTap;

  final List<Trail>? trails;
  final Trail? selectedVisible;
  final List<NearbyTreffer> nearbyPlaces;
  final NearbyTreffer? selectedNearby;
  final List<LatLng> walkRoute;
  final LatLng? userFix;
  final LocateTarget? locateTarget;
  final LatLng? userAnchor;
  final bool framePlace;
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
        framePlace: framePlace,
        pendingCameraTrailId: pendingCameraTrailId,
        onPendingCameraConsumed: onPendingCameraConsumed,
        bezugPin: bezugPin,
        umkreisM: umkreisM,
        bottomInset: bottomInset,
        onBereichSuchen: onBereichSuchen,
        onMapTap: onMapTap,
      ),
    );
  }
}

/// Kreisradius in Metern, passend zur Anfahrtsschätzung
/// (`min = km * 1,3 / 45 * 60`). `null` bei „egal“.
double? umkreisMeter(Umkreis u) {
  final min = u.minuten;
  if (min == null) return null;
  return min / 60 * 45 / 1.3 * 1000;
}

/// „In diesem Bereich suchen“, oben mittig, nur nach einer Kartengeste.
class _BereichSuchenButton extends ConsumerWidget {
  const _BereichSuchenButton({required this.notifier});

  final ValueNotifier<LatLng?> notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ValueListenableBuilder<LatLng?>(
      valueListenable: notifier,
      builder: (context, mitte, _) {
        if (mitte == null) return const SizedBox.shrink();
        return Align(
          alignment: Alignment.topCenter,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.x2),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  shape: const StadiumBorder(),
                ),
                onPressed: () {
                  notifier.value = null;
                  BezugAktionen(ref).sucheImBereich(mitte);
                },
                icon: const PhosphorIcon(
                  PhosphorIcons.magnifyingGlass,
                  size: 18,
                ),
                label: Text(kt('karte.bereichSuchen')),
              ),
            ),
          ),
        );
      },
    );
  }
}
