import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/config/map_config.dart';
import '../../../shared/widgets/show_app_modal_sheet.dart';
import '../data/report_recorder.dart';
import '../domain/report_enums.dart';
import '../domain/report_models.dart';
import '../report_config.dart';
import '../report_copy.dart';
import 'marker_sheet.dart';
import 'report_banner.dart';
import 'report_widgets.dart';
import 'review_screen.dart';

enum _EndChoice { review, keepGoing, discard }

/// R2 „Aufnahme“: Karte, Marker setzen, Pause, Beenden.
class RecordingScreen extends ConsumerStatefulWidget {
  const RecordingScreen({super.key});

  @override
  ConsumerState<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends ConsumerState<RecordingScreen>
    with WidgetsBindingObserver {
  final _map = MapController();
  StreamSubscription<RecorderEvent>? _events;
  bool _follow = true;
  bool _mapReady = false;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _events = ref.read(reportRecorderProvider.notifier).events.listen(_onEvent);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _mapReady = true;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _events?.cancel();
    _map.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref
        .read(reportRecorderProvider.notifier)
        .setForeground(state == AppLifecycleState.resumed);
  }

  ReportRecorder get _rec => ref.read(reportRecorderProvider.notifier);

  void _onEvent(RecorderEvent e) {
    if (!mounted) return;
    switch (e.type) {
      case RecorderEventType.markerSet:
        final p = e.point!;
        if (p.type == PointType.hint) {
          unawaited(_openMarker(p));
        } else {
          _setSnack(p);
        }
      case RecorderEventType.noFix:
        showReportSnack(context, rt('report.rec.no_fix'));
      case RecorderEventType.markerLimit:
        showReportSnack(context, rt('report.rec.marker_limit'));
      case RecorderEventType.trackFull:
        showReportSnack(context, rt('report.rec.track_full'));
      case RecorderEventType.backgroundFailed:
        showReportSnack(context, rt('report.prep.bg_fail'));
      case RecorderEventType.lowAccuracy:
      case RecorderEventType.gpsBack:
        break;
    }
  }

  void _setSnack(DraftPoint p) {
    final text = p.lowAccuracy
        ? rt('report.rec.low_accuracy', {'a': p.accuracyM.round()})
        : p.type == PointType.station
        ? rt('report.rec.snack.station', {'n': p.number ?? ''})
        : rt('report.rec.snack.other', {'typ': pointTypeLabel(p.type)});
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: cfg.undoSnackbarS),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text),
            Wrap(
              spacing: AppSpacing.x2,
              children: [
                if (p.type == PointType.station)
                  _SnackAction(
                    label: rt('report.rec.snack.photo'),
                    onTap: () {
                      messenger.hideCurrentSnackBar();
                      unawaited(
                        capturePointPhoto(
                          context,
                          ref,
                          draftId: p.draftId,
                          pointId: p.id,
                        ),
                      );
                    },
                  ),
                _SnackAction(
                  label: rt('report.rec.snack.details'),
                  onTap: () {
                    messenger.hideCurrentSnackBar();
                    unawaited(_openMarker(p));
                  },
                ),
                _SnackAction(
                  label: rt('report.rec.snack.undo'),
                  onTap: () {
                    messenger.hideCurrentSnackBar();
                    unawaited(_rec.deletePoint(p.id));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMarker(DraftPoint p) {
    return showMarkerSheet(
      context,
      point: p,
      onSave: _rec.updatePoint,
      onDelete: () async {
        final removed = await _rec.deletePoint(p.id);
        if (removed != null && mounted) _undoDeleteSnack(removed);
      },
      onRemeasure: p.type == PointType.start
          ? null
          : () => _rec.remeasure(p.id),
      reload: () async {
        final s = ref.read(reportRecorderProvider);
        if (s == null) return null;
        for (final q in s.points) {
          if (q.id == p.id) return q;
        }
        return null;
      },
    );
  }

  void _undoDeleteSnack(DraftPoint removed) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: cfg.undoSnackbarS),
        content: Text(rt('report.common.delete')),
        action: SnackBarAction(
          label: rt('report.rec.snack.undo'),
          onPressed: () => unawaited(_rec.restorePoint(removed)),
        ),
      ),
    );
  }

  Future<void> _end() async {
    final choice = await showAppModalSheet<_EndChoice>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            rt('report.rec.end.title'),
            style: Theme.of(ctx).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.stack),
          ReportPrimaryButton(
            label: rt('report.rec.end.review'),
            onPressed: () => Navigator.of(ctx).pop(_EndChoice.review),
          ),
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: () => Navigator.of(ctx).pop(_EndChoice.keepGoing),
            child: Text(rt('report.rec.end.continue')),
          ),
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: () => Navigator.of(ctx).pop(_EndChoice.discard),
            child: Text(rt('report.rec.end.discard')),
          ),
        ],
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case _EndChoice.review:
        _leaving = true;
        final draft = await _rec.finish();
        if (!mounted) return;
        if (draft == null) {
          Navigator.of(context).pop();
          return;
        }
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => ReviewScreen(draftId: draft.id),
          ),
        );
      case _EndChoice.discard:
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(rt('report.rec.discard.title')),
            content: Text(rt('report.rec.discard.body')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(rt('report.common.cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(rt('report.common.delete')),
              ),
            ],
          ),
        );
        if (ok == true && mounted) {
          _leaving = true;
          await _rec.discard();
          if (mounted) Navigator.of(context).pop();
        }
      case _EndChoice.keepGoing:
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(reportRecorderProvider);
    ref.listen(reportRecorderProvider, (prev, next) {
      if (next == null) return;
      final fix = next.fix;
      if (_follow && _mapReady && fix != null && fix != prev?.fix) {
        _map.move(fix.position, _map.camera.zoom);
      }
    });
    if (s == null) {
      if (!_leaving) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_leaving) Navigator.of(context).maybePop();
        });
      }
      return const Scaffold(body: SizedBox.shrink());
    }
    final theme = Theme.of(context);
    final user = s.fix?.position;
    final segments = _rec.segments;

    return BannerSuppressor(
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: ReportMap(
                controller: _map,
                segments: segments,
                points: s.points,
                user: user,
                center: user ?? _lastPoint(s.points),
                zoom: MapConfig.locateZoom,
                onPointTap: _openMarker,
                onUserGesture: () {
                  if (_follow) setState(() => _follow = false);
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.x3),
                child: Column(
                  children: [
                    Row(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.x3,
                              vertical: AppSpacing.x2,
                            ),
                            child: Text(
                              s.pointsOnly
                                  ? '${rt('report.rec.chip.station')} ${s.stationCount}'
                                  : rt('report.rec.stats', {
                                      'km': formatKm(s.lengthM),
                                      'n': s.stationCount,
                                    }),
                              style: theme.textTheme.labelLarge,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.x2),
                        SignalPill(
                          level: s.signal,
                          accuracyM: s.fix?.accuracyM,
                        ),
                        const Spacer(),
                        FilledButton.tonal(
                          onPressed: _end,
                          child: Text(rt('report.rec.end')),
                        ),
                      ],
                    ),
                    if (s.noGps) ...[
                      const SizedBox(height: AppSpacing.x2),
                      _Banner(text: rt('report.rec.no_signal_banner')),
                    ],
                    if (s.paused) ...[
                      const SizedBox(height: AppSpacing.x2),
                      _Banner(text: rt('report.rec.paused_label')),
                    ],
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomPanel(
                state: s,
                follow: _follow,
                onRecenter: () {
                  setState(() => _follow = true);
                  final p = user;
                  if (p != null) _map.move(p, MapConfig.locateZoom);
                },
                onSet: () => _rec.setPoint(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

LatLng? _lastPoint(List<DraftPoint> points) =>
    points.isEmpty ? null : LatLng(points.last.lat, points.last.lng);

class _SnackAction extends StatelessWidget {
  const _SnackAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        minimumSize: const Size(48, 40),
      ),
      onPressed: onTap,
      child: Text(label),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Text(text, style: theme.textTheme.bodyMedium),
      ),
    );
  }
}

class _BottomPanel extends ConsumerWidget {
  const _BottomPanel({
    required this.state,
    required this.follow,
    required this.onRecenter,
    required this.onSet,
  });

  final RecorderState state;
  final bool follow;
  final VoidCallback onRecenter;
  final VoidCallback onSet;

  static const _types = [
    PointType.station,
    PointType.waypoint,
    PointType.parking,
    PointType.hint,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rec = ref.read(reportRecorderProvider.notifier);
    final s = state;
    final canSet = !s.measuring && !s.markerLimit && !s.noGps && s.fix != null;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.x6),
        ),
        boxShadow: const [BoxShadow(blurRadius: 16, color: Colors.black26)],
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.x4,
        AppSpacing.x3,
        AppSpacing.x4,
        AppSpacing.x3 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!follow)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRecenter,
                icon: const Icon(Icons.my_location),
                label: Text(rt('report.rec.recenter')),
              ),
            ),
          Wrap(
            spacing: AppSpacing.chip,
            children: [
              for (final t in _types)
                ChoiceChip(
                  label: Text(rt('report.rec.chip.${t.name}')),
                  selected: s.nextType == t,
                  onSelected: s.measuring ? null : (_) => rec.selectType(t),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          SizedBox(
            height: 76,
            child: FilledButton(
              onPressed: canSet ? onSet : null,
              child: s.measuring
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            value: s.measureProgress == 0
                                ? null
                                : s.measureProgress,
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.x3),
                        Text(rt('report.rec.measuring')),
                      ],
                    )
                  : Text(
                      rt('report.rec.set.${s.nextType.name}'),
                      style: theme.textTheme.titleMedium,
                    ),
            ),
          ),
          if (!s.pointsOnly)
            TextButton.icon(
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => s.paused ? rec.resumeAfterPause() : rec.pause(),
              icon: Icon(s.paused ? Icons.play_arrow : Icons.pause),
              label: Text(
                s.paused ? rt('report.rec.resume') : rt('report.rec.pause'),
              ),
            ),
        ],
      ),
    );
  }
}
