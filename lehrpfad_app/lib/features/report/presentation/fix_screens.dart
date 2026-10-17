import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/widgets/hint_box.dart';
import '../../../shared/widgets/show_app_modal_sheet.dart';
import '../../trail/data/providers.dart';
import '../../trail/domain/station.dart';
import '../../trail/domain/trail.dart';
import '../../trail_progress/tracking/location_service.dart';
import '../domain/report_enums.dart';
import '../logic/geo.dart';
import '../logic/quick_result.dart';
import '../report_config.dart';
import '../report_copy.dart';
import 'quick_common.dart';
import 'report_hub.dart';
import 'report_widgets.dart';

// ── R9 Pfad wählen ───────────────────────────────────────────────

class PickTrailScreen extends ConsumerStatefulWidget {
  const PickTrailScreen({super.key});

  @override
  ConsumerState<PickTrailScreen> createState() => _PickTrailScreenState();
}

class _PickTrailScreenState extends ConsumerState<PickTrailScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '';
  double? _lat;
  double? _lng;
  bool _locating = true;

  @override
  void initState() {
    super.initState();
    unawaited(_locate());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    final p = await ref.read(locationServiceProvider).currentPosition();
    if (!mounted) return;
    setState(() {
      _lat = p?.latitude;
      _lng = p?.longitude;
      _locating = false;
    });
  }

  void _onQuery(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = v.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trails = ref.watch(trailsProvider).value ?? const <Trail>[];
    final searching = _query.length >= 2;

    final rows = <({Trail trail, double? dist})>[];
    for (final t in trails) {
      final s = t.startOrNull;
      double? d;
      if (_lat != null && s != null) {
        d = distanceM(_lat!, _lng!, s.latitude, s.longitude);
      }
      if (searching) {
        if (t.name.toLowerCase().contains(_query.toLowerCase())) {
          rows.add((trail: t, dist: d));
        }
      } else if (d != null && d <= cfg.nearbyTrailsRadiusKm * 1000) {
        rows.add((trail: t, dist: d));
      }
    }
    rows.sort((a, b) => (a.dist ?? 1e12).compareTo(b.dist ?? 1e12));

    return Scaffold(
      appBar: AppBar(title: Text(rt('report.pick.title'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: TextField(
              controller: _search,
              onChanged: _onQuery,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: rt('report.pick.search'),
              ),
            ),
          ),
          if (!_locating && _lat == null && !searching)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: Text(
                rt('report.pick.no_location'),
                style: theme.textTheme.bodySmall,
              ),
            ),
          Expanded(
            child: rows.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.page),
                      child: _locating && !searching
                          ? const CircularProgressIndicator()
                          : Text(
                              searching
                                  ? rt('report.pick.empty_search')
                                  : rt('report.pick.empty_near'),
                              textAlign: TextAlign.center,
                            ),
                    ),
                  )
                : ListView.builder(
                    itemCount: rows.length > 50 ? 50 : rows.length,
                    itemBuilder: (_, i) {
                      final r = rows[i];
                      return ListTile(
                        title: Text(r.trail.name),
                        subtitle: r.dist == null
                            ? null
                            : Text(
                                rt('report.pick.distance', {
                                  'd': kmShort(r.dist!),
                                }),
                              ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => FixHubScreen(trail: r.trail),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── R10 Korrektur wählen ─────────────────────────────────────────

class FixHubScreen extends StatelessWidget {
  const FixHubScreen({super.key, required this.trail});

  final Trail trail;

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final rows = <(String, IconData, VoidCallback)>[
      if (trail.isFlaeche) ...[
        (
          rt('report.fix.place'),
          Icons.open_with,
          () =>
              _push(context, MoveStationScreen(trail: trail, placeMode: true)),
        ),
      ] else ...[
        (
          rt('report.fix.move'),
          Icons.open_with,
          () => _push(context, MoveStationScreen(trail: trail)),
        ),
        (
          rt('report.fix.add'),
          Icons.add_location_alt_outlined,
          () => _push(context, AddPointScreen(trail: trail)),
        ),
        (
          rt('report.fix.hint'),
          Icons.warning_amber_outlined,
          () => _push(context, HintScreen(trail: trail)),
        ),
        (rt('report.fix.route'), Icons.route, () => _routeInfo(context)),
        (
          rt('report.fix.parking'),
          Icons.local_parking,
          () => _push(context, AddPointScreen(trail: trail, parking: true)),
        ),
      ],
      (
        rt('report.fix.other'),
        Icons.chat_bubble_outline,
        () => _push(context, HintScreen(trail: trail, other: true)),
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(rt('report.fix.title', {'name': trail.name}))),
      body: ListView(
        children: [
          for (final r in rows)
            ListTile(
              leading: Icon(r.$2),
              title: Text(r.$1),
              trailing: const Icon(Icons.chevron_right),
              onTap: r.$3,
            ),
        ],
      ),
    );
  }

  Future<void> _routeInfo(BuildContext context) async {
    final go = await showAppModalSheet<bool>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            rt('report.fix.route_info.title'),
            style: Theme.of(ctx).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.x3),
          Text(rt('report.fix.route_info.body')),
          const SizedBox(height: AppSpacing.stack),
          ReportPrimaryButton(
            label: rt('report.fix.route_info.go'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (go == true && context.mounted) {
      await startRevisionFlow(context, trail);
    }
  }
}

// ── R11 Station verschieben ──────────────────────────────────────

class MoveStationScreen extends ConsumerStatefulWidget {
  const MoveStationScreen({
    super.key,
    required this.trail,
    this.placeMode = false,
    this.initialStation,
  });

  final Trail trail;

  /// Vorbelegte Station (Einstieg aus der Stationsansicht, E-6).
  final Station? initialStation;

  /// `true` bei Flächen: es gibt nur den Ort selbst, keine Stationen.
  final bool placeMode;

  @override
  ConsumerState<MoveStationScreen> createState() => _MoveStationScreenState();
}

class _MoveStationScreenState extends ConsumerState<MoveStationScreen>
    with QuickFlowState<MoveStationScreen> {
  Station? _station;
  bool _preselected = false;
  final _note = TextEditingController();
  final _map = MapController();

  @override
  void initState() {
    super.initState();
    _station = widget.initialStation;
    _preselected = widget.initialStation != null;
    startWatching();
  }

  @override
  void dispose() {
    stopWatching();
    _note.dispose();
    _map.dispose();
    super.dispose();
  }

  /// Ohne Vorwahl: die nächste Station innerhalb von 150 m (Spec 5.3).
  void _preselectNearest() {
    final f = fix;
    if (_preselected || f == null || widget.placeMode) return;
    _preselected = true;
    Station? best;
    var bestD = 150.0;
    for (final st in widget.trail.stationen) {
      final d = distanceM(
        st.position.latitude,
        st.position.longitude,
        f.position.latitude,
        f.position.longitude,
      );
      if (d <= bestD) {
        bestD = d;
        best = st;
      }
    }
    if (best != null) _station = best;
  }

  /// Gespeicherte Position und Ziel-ID des Punkts.
  ({double lat, double lng, String target})? get _target {
    if (widget.placeMode) {
      final s = widget.trail.startOrNull;
      if (s == null) return null;
      return (
        lat: s.latitude,
        lng: s.longitude,
        target: 'trail:${widget.trail.id}',
      );
    }
    final st = _station;
    if (st == null || st.id == null) return null;
    return (
      lat: st.position.latitude,
      lng: st.position.longitude,
      target: 'station:${st.id}',
    );
  }

  double? get _distToTarget {
    final t = _target;
    final f = fix;
    if (t == null || f == null) return null;
    return distanceM(t.lat, t.lng, f.position.latitude, f.position.longitude);
  }

  QuickResultState? get _result {
    final t = _target;
    final m = measured;
    if (t == null || m == null) return null;
    return evaluateQuickResult(
      deviationM: distanceM(t.lat, t.lng, m.lat, m.lng),
      accuracyM: m.accuracyM,
      attempts: attempts,
    );
  }

  Future<void> _send() async {
    final t = _target;
    final m = measured;
    if (t == null || m == null) return;
    final note = _note.text.trim();
    await submitQuick(
      intent: QuickIntent.movePoint,
      trail: widget.trail,
      note: note.isEmpty ? null : note,
      point: buildPoint(
        type: widget.placeMode ? PointType.start : PointType.station,
        avg: m,
        targetPointId: t.target,
        note: note.isEmpty ? null : note,
        oldLat: t.lat,
        oldLng: t.lng,
        lowAccuracy: m.accuracyM > cfg.okMaxM,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    _preselectNearest();
    final target = _target;
    final dist = _distToTarget;
    final tooFar = dist != null && quickTooFar(dist);
    final result = _result;
    final m = measured;

    final f = fix;
    final stations = [...widget.trail.stationen]
      ..sort((a, b) {
        if (f == null) return a.reihenfolge.compareTo(b.reihenfolge);
        double d(Station x) => distanceM(
          x.position.latitude,
          x.position.longitude,
          f.position.latitude,
          f.position.longitude,
        );
        return d(a).compareTo(d(b));
      });

    final children = <Widget>[
      SizedBox(
        height: 220,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.x3),
          child: ReportMap(
            controller: _map,
            existingRoute: widget.trail.route,
            user: fix?.position,
            center: target == null
                ? (fix?.position ?? widget.trail.startOrNull)
                : LatLng(target.lat, target.lng),
            extraMarkers: [
              for (final st in widget.trail.stationen)
                Marker(
                  point: st.position,
                  width: 30,
                  height: 30,
                  child: GestureDetector(
                    onTap: widget.placeMode
                        ? null
                        : () => setState(() {
                            _station = st;
                            measured = null;
                            attempts = 0;
                          }),
                    child: _StationDot(
                      number: st.reihenfolge,
                      selected: identical(st, _station),
                    ),
                  ),
                ),
              if (measured != null)
                Marker(
                  point: LatLng(measured!.lat, measured!.lng),
                  width: 30,
                  height: 30,
                  child: const Icon(Icons.place, size: 30),
                ),
            ],
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.stack),
      Row(
        children: [SignalPill(level: level, accuracyM: fix?.accuracyM)],
      ),
      const SizedBox(height: AppSpacing.stack),
    ];

    if (!widget.placeMode && _station == null) {
      children.add(
        Text(rt('report.move.pick'), style: theme.textTheme.bodyMedium),
      );
      for (final s in stations) {
        children.add(
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(radius: 16, child: Text('${s.reihenfolge}')),
            title: Text(s.titel),
            onTap: () => setState(() {
              _station = s;
              measured = null;
              attempts = 0;
            }),
          ),
        );
      }
    } else {
      if (!widget.placeMode) {
        children.add(
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_station!.titel),
            trailing: TextButton(
              onPressed: () => setState(() {
                _station = null;
                measured = null;
                attempts = 0;
              }),
              child: Text(rt('report.common.cancel')),
            ),
          ),
        );
        if (_station!.id == null) {
          children.add(Text(rt('report.err.invalid_payload')));
        }
      }
      if (dist != null) {
        children.add(
          Text(
            rt('report.move.distance', {'d': dist.round()}),
            style: theme.textTheme.bodyMedium,
          ),
        );
      }
      if (tooFar) {
        children.add(const SizedBox(height: AppSpacing.x2));
        children.add(HintBox(child: Text(rt('report.move.too_far'))));
      }
      if (m != null && result != null) {
        final dev = distanceM(target!.lat, target.lng, m.lat, m.lng);
        children.add(const SizedBox(height: AppSpacing.stack));
        children.add(
          HintBox(
            child: Text(switch (result) {
              QuickResultState.noise => rt('report.move.noise', {
                'd': dev.round(),
              }),
              QuickResultState.weak || QuickResultState.weakOverride => rt(
                'report.move.weak',
                {'a': m.accuracyM.round()},
              ),
              QuickResultState.ready =>
                '${dev.round()} m · '
                    '${rt('report.marker.accuracy', {'a': m.accuracyM.round()})}',
            }),
          ),
        );
        if (result == QuickResultState.ready ||
            result == QuickResultState.noise ||
            result == QuickResultState.weakOverride) {
          children.add(const SizedBox(height: AppSpacing.stack));
          children.add(
            TextField(
              controller: _note,
              maxLength: cfg.quickNoteMaxChars,
              decoration: InputDecoration(labelText: rt('report.move.note')),
            ),
          );
          children.add(
            QuickPhotoRow(
              label: rt('report.move.photo'),
              count: photoCount,
              onAdd: addPhoto,
            ),
          );
        }
      }
    }

    Widget? bottom;
    if (target != null && _station != null || widget.placeMode) {
      final canMeasure = !measuring && !tooFar && hasGoodEnoughSignal;
      Widget measureBtn(String label) => ReportPrimaryButton(
        label: measuring ? rt('report.rec.measuring') : label,
        loading: false,
        onPressed: canMeasure ? () => measure() : null,
      );
      Widget secondary(String label, VoidCallback onTap) => TextButton(
        style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        onPressed: sending ? null : onTap,
        child: Text(label),
      );
      bottom = switch (result) {
        null => measureBtn(rt('report.move.cta')),
        QuickResultState.ready => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReportPrimaryButton(
              label: rt('report.move.send'),
              loading: sending,
              onPressed: _send,
            ),
            secondary(rt('report.move.remeasure'), () => measure()),
          ],
        ),
        QuickResultState.noise => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReportPrimaryButton(
              label: rt('report.common.cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            secondary(rt('report.move.send_anyway'), _send),
          ],
        ),
        QuickResultState.weak => measureBtn(rt('report.move.remeasure')),
        QuickResultState.weakOverride => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            measureBtn(rt('report.move.remeasure')),
            secondary(rt('report.move.send_anyway'), _send),
          ],
        ),
      };
    }

    return Scaffold(
      appBar: AppBar(title: Text(rt('report.move.title'))),
      body: QuickBody(bottom: bottom, children: children),
    );
  }
}

class _StationDot extends StatelessWidget {
  const _StationDot({required this.number, required this.selected});

  final int number;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected
            ? AppColors.brand
            : Theme.of(context).colorScheme.surface,
        border: Border.all(color: AppColors.brand, width: 2),
      ),
      child: Center(
        child: Text(
          '$number',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: selected ? AppColors.paper : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

// ── R12 Station oder Parkplatz ergänzen ──────────────────────────

class AddPointScreen extends ConsumerStatefulWidget {
  const AddPointScreen({super.key, required this.trail, this.parking = false});

  final Trail trail;
  final bool parking;

  @override
  ConsumerState<AddPointScreen> createState() => _AddPointScreenState();
}

class _AddPointScreenState extends ConsumerState<AddPointScreen>
    with QuickFlowState<AddPointScreen> {
  final _note = TextEditingController();
  final _title = TextEditingController();

  @override
  void initState() {
    super.initState();
    startWatching();
  }

  @override
  void dispose() {
    stopWatching();
    _note.dispose();
    _title.dispose();
    super.dispose();
  }

  double? get _distToTrail {
    final f = fix;
    if (f == null) return null;
    return distanceToTrailM(
      widget.trail,
      f.position.latitude,
      f.position.longitude,
    );
  }

  Future<void> _send() async {
    final m = measured;
    if (m == null) return;
    final off = needsOffTrailConfirm(
      distanceToTrailM(widget.trail, m.lat, m.lng),
    );
    if (off && !widget.parking) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text(rt('report.add.offtrail')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(rt('report.common.cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(rt('report.add.offtrail.yes')),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    final note = _note.text.trim();
    final title = _title.text.trim();
    await submitQuick(
      intent: QuickIntent.addPoint,
      trail: widget.trail,
      note: note.isEmpty ? null : note,
      point: buildPoint(
        type: widget.parking ? PointType.parking : PointType.station,
        avg: m,
        title: title.isEmpty ? null : title,
        note: note.isEmpty ? null : note,
        lowAccuracy: m.accuracyM > cfg.okMaxM,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dist = _distToTrail;
    final tooFar = dist != null && quickTooFar(dist);
    final m = measured;
    final weak = m != null && m.accuracyM > cfg.okMaxM;
    final override = weak && attempts >= cfg.quickWeakAttemptsBeforeOverride;
    final canMeasure = !measuring && !tooFar && hasGoodEnoughSignal;

    final children = <Widget>[
      Row(
        children: [SignalPill(level: level, accuracyM: fix?.accuracyM)],
      ),
      const SizedBox(height: AppSpacing.stack),
      if (tooFar) HintBox(child: Text(rt('report.add.too_far'))),
      if (m != null) ...[
        HintBox(
          child: Text(
            weak
                ? rt('report.move.weak', {'a': m.accuracyM.round()})
                : rt('report.marker.accuracy', {'a': m.accuracyM.round()}),
          ),
        ),
        if (!weak || override) ...[
          const SizedBox(height: AppSpacing.stack),
          if (!widget.parking)
            TextField(
              controller: _title,
              maxLength: cfg.titleMaxChars,
              decoration: InputDecoration(labelText: rt('report.marker.title')),
            ),
          TextField(
            controller: _note,
            maxLength: cfg.quickNoteMaxChars,
            decoration: InputDecoration(labelText: rt('report.move.note')),
          ),
          QuickPhotoRow(
            label: rt('report.move.photo'),
            count: photoCount,
            onAdd: addPhoto,
          ),
        ],
      ],
    ];

    final Widget bottom;
    if (m == null || (weak && !override)) {
      bottom = ReportPrimaryButton(
        label: measuring
            ? rt('report.rec.measuring')
            : m == null
            ? (widget.parking
                  ? rt('report.add.parking.cta')
                  : rt('report.add.cta'))
            : rt('report.move.remeasure'),
        onPressed: canMeasure ? () => measure() : null,
      );
    } else {
      bottom = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReportPrimaryButton(
            label: rt('report.move.send'),
            loading: sending,
            onPressed: _send,
          ),
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: canMeasure ? () => measure() : null,
            child: Text(rt('report.move.remeasure')),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.parking
              ? rt('report.add.parking.title')
              : rt('report.add.title'),
        ),
      ),
      body: QuickBody(bottom: bottom, children: children),
    );
  }
}

// ── R13 Hinweis und „Etwas anderes“ ──────────────────────────────

class HintScreen extends ConsumerStatefulWidget {
  const HintScreen({super.key, required this.trail, this.other = false});

  final Trail trail;

  /// `true` bei „Etwas anderes melden“.
  final bool other;

  @override
  ConsumerState<HintScreen> createState() => _HintScreenState();
}

class _HintScreenState extends ConsumerState<HintScreen>
    with QuickFlowState<HintScreen> {
  final _note = TextEditingController();
  HintKind? _kind;
  bool _tryNote = false;

  @override
  void initState() {
    super.initState();
    startWatching();
    _note.addListener(() => setState(() {}));
    // Beim Öffnen startet die Mittelung (Spec 5.5).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(measure());
    });
  }

  @override
  void dispose() {
    stopWatching();
    _note.dispose();
    super.dispose();
  }

  HintKind get _effectiveKind => widget.other ? HintKind.other : _kind!;

  bool get _closedOrDanger =>
      !widget.other && (_kind == HintKind.closed || _kind == HintKind.danger);

  double? get _distToTrail {
    final f = fix;
    if (f == null) return null;
    return distanceToTrailM(
      widget.trail,
      f.position.latitude,
      f.position.longitude,
    );
  }

  Future<void> _send() async {
    setState(() => _tryNote = true);
    if (!widget.other && _kind == null) return;
    final note = _note.text.trim();
    if (widget.other && !otherNoteValid(note)) return;
    final dist = _distToTrail;
    if (dist != null &&
        !hintSendAllowed(
          isClosedOrDanger: _closedOrDanger,
          distanceToTrailM: dist,
        )) {
      return;
    }
    final avg = measured ?? await measure();
    if (avg == null || !mounted) return;
    await submitQuick(
      intent: widget.other ? QuickIntent.other : QuickIntent.hint,
      trail: widget.trail,
      note: note.isEmpty ? null : note,
      point: buildPoint(
        type: PointType.hint,
        avg: avg,
        hintKind: _effectiveKind,
        note: note.isEmpty ? null : note,
        lowAccuracy: avg.accuracyM > cfg.okMaxM,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dist = _distToTrail;
    final blocked =
        dist != null &&
        !hintSendAllowed(
          isClosedOrDanger: _closedOrDanger,
          distanceToTrailM: dist,
        );
    final noteBad =
        widget.other && _tryNote && !otherNoteValid(_note.text.trim());

    final children = <Widget>[
      Row(
        children: [SignalPill(level: level, accuracyM: fix?.accuracyM)],
      ),
      if (fix?.accuracyM != null) ...[
        const SizedBox(height: AppSpacing.x2),
        Text(
          rt('report.hintform.location', {'a': fix!.accuracyM!.round()}),
          style: theme.textTheme.bodySmall,
        ),
      ],
      const SizedBox(height: AppSpacing.stack),
      if (!widget.other) ...[
        Text(rt('report.hintform.kind'), style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.x2),
        Wrap(
          spacing: AppSpacing.chip,
          runSpacing: AppSpacing.chip,
          children: [
            for (final k in HintKind.values)
              ChoiceChip(
                label: Text(hintKindLabel(k)),
                selected: _kind == k,
                onSelected: (_) => setState(() => _kind = k),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.stack),
      ],
      TextField(
        controller: _note,
        minLines: 2,
        maxLines: 5,
        maxLength: cfg.hintNoteMaxChars,
        decoration: InputDecoration(
          labelText: rt('report.move.note'),
          errorText: noteBad ? rt('report.hintform.note_required') : null,
        ),
      ),
      QuickPhotoRow(
        label: rt('report.move.photo'),
        count: photoCount,
        onAdd: addPhoto,
      ),
      if (blocked) ...[
        const SizedBox(height: AppSpacing.x2),
        HintBox(child: Text(rt('report.hintform.too_far'))),
      ],
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.other
              ? rt('report.hintform.other.title')
              : rt('report.hintform.title'),
        ),
      ),
      body: QuickBody(
        bottom: ReportPrimaryButton(
          label: measuring
              ? rt('report.rec.measuring')
              : rt('report.move.send'),
          loading: sending,
          onPressed: measuring || blocked || !hasGoodEnoughSignal
              ? null
              : _send,
        ),
        children: children,
      ),
    );
  }
}
