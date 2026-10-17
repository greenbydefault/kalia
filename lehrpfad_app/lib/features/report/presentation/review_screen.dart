import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../shared/widgets/hint_box.dart';
import '../../auth/presentation/account_prompt_sheet.dart';
import '../../nearby_trails/domain/karte_copy.dart';
import '../../trail/data/providers.dart';
import '../../trail/domain/trail.dart';
import '../data/report_providers.dart';
import '../data/report_recorder.dart';
import '../data/report_uploader.dart';
import '../domain/report_enums.dart';
import '../domain/report_models.dart';
import '../logic/geo.dart';
import '../logic/review_logic.dart';
import '../logic/track_metrics.dart';
import '../report_config.dart';
import '../report_copy.dart';
import 'marker_sheet.dart';
import 'recording_screen.dart';
import 'report_banner.dart';
import 'report_widgets.dart';
import 'sent_screen.dart';

/// R4 „Prüfen“: Karte, Zusammenfassung, Hinweise, Formular, Kürzen,
/// Punkteliste, Einreichen.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key, required this.draftId});

  final String draftId;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final _map = MapController();
  final _scroll = ScrollController();
  final _nameKey = GlobalKey();
  final _areaKey = GlobalKey();
  final _markersKey = GlobalKey();
  final _name = TextEditingController();
  final _note = TextEditingController();

  ReportDraft? _draft;
  List<DraftPoint> _points = const [];
  TrackSegments _segments = const [];
  int _photoCount = 0;
  List<ReviewFieldError> _errors = const [];
  bool _submitting = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    final d = _draft;
    if (d != null && !_submitting) {
      unawaited(ref.read(reportDraftStoreProvider).saveDraft(d));
    }
    _map.dispose();
    _scroll.dispose();
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final store = ref.read(reportDraftStoreProvider);
    final d = await store.load(widget.draftId);
    if (d == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final points = await store.points(d.id);
    final fixes = await store.fixes(d.id);
    final photos = await store.photos(d.id);
    if (!mounted) return;
    setState(() {
      _draft = d;
      _points = points;
      _segments = segmentsFromFixes(fixes);
      _photoCount = photos.length;
      _name.text = d.title ?? '';
      _note.text = d.note ?? '';
    });
  }

  Future<void> _reloadPoints() async {
    final d = _draft;
    if (d == null) return;
    final store = ref.read(reportDraftStoreProvider);
    final points = await store.points(d.id);
    final photos = await store.photos(d.id);
    if (!mounted) return;
    setState(() {
      _points = points;
      _photoCount = photos.length;
    });
  }

  void _edit(ReportDraft Function(ReportDraft) f) {
    final d = _draft;
    if (d == null) return;
    setState(() => _draft = f(d));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final cur = _draft;
      if (cur != null) {
        unawaited(ref.read(reportDraftsProvider.notifier).save(cur));
      }
    });
  }

  TrackSegments get _trimmed => trimTrack(
    _segments,
    startM: _draft?.trimStartM ?? 0,
    endM: _draft?.trimEndM ?? 0,
  );

  bool get _pointsOnly => _draft?.mode == RecordingMode.pointsOnly;

  double get _lengthM {
    if (_pointsOnly || _segments.isEmpty) {
      return markerChainLengthM([
        for (final p in _points) TrackPoint(p.lat, p.lng),
      ]);
    }
    return trackLengthM(_trimmed);
  }

  List<ReviewMarker> get _markers => [
    for (final p in _points)
      ReviewMarker(type: p.type, number: p.number, lowAccuracy: p.lowAccuracy),
  ];

  Future<void> _submit() async {
    final d = _draft;
    if (d == null || _submitting) return;
    final errors = validateForSubmit(
      kind: d.kind,
      title: d.title,
      area: d.area,
      trackLengthM: _lengthM,
      markerCount: _points.length,
    );
    setState(() => _errors = errors);
    if (errors.isNotEmpty) {
      final key = switch (errors.first) {
        ReviewFieldError.nameTooShort => _nameKey,
        ReviewFieldError.areaMissing => _areaKey,
        ReviewFieldError.tooShort => _markersKey,
      };
      final ctx = key.currentContext;
      if (ctx != null) {
        await Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 250),
        );
      }
      return;
    }
    setState(() => _submitting = true);
    _debounce?.cancel();
    final uploader = ref.read(reportUploaderProvider);
    final signedIn = await requireAccountIfNeeded();
    if (!mounted) return;
    final saved = _draft!.copyWith(justFinished: false);
    await ref.read(reportDraftsProvider.notifier).save(saved);
    final submitted = await uploader.submit(saved);
    if (!mounted) return;
    if (!signedIn) {
      showReportSnack(context, rt('report.account.saved'));
    }
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => SentScreen(
          draftId: submitted.id,
          awaitingAccount: submitted.status == DraftStatus.awaitingAccount,
        ),
      ),
    );
  }

  /// Konto erst jetzt, mit Begründung (R5). `false`, wenn abgelehnt.
  Future<bool> requireAccountIfNeeded() {
    return requireAccount(context, reason: rt('report.account.body'));
  }

  Future<void> _continueRecording() async {
    final d = _draft;
    if (d == null) return;
    await ref
        .read(reportRecorderProvider.notifier)
        .resume(d.id, dropAutoEnd: true);
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const RecordingScreen()),
    );
  }

  Future<void> _saveAsDraft() async {
    final d = _draft;
    if (d == null) return;
    _debounce?.cancel();
    await ref.read(reportDraftsProvider.notifier).save(d);
    if (!mounted) return;
    showReportSnack(context, rt('report.review.draft_saved'));
    Navigator.of(context).pop();
  }

  Future<void> _discard() async {
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
    if (ok != true || !mounted) return;
    _submitting = true;
    await ref.read(reportDraftsProvider.notifier).delete(widget.draftId);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _openMarker(DraftPoint p) {
    final store = ref.read(reportDraftStoreProvider);
    return showMarkerSheet(
      context,
      point: p,
      onSave: (np) async {
        await store.savePoint(np);
        await _reloadPoints();
      },
      onDelete: () async {
        await store.deletePoint(p.draftId, p.id);
        await _renumberStored();
        await _reloadPoints();
      },
    );
  }

  Future<void> _renumberStored() async {
    final store = ref.read(reportDraftStoreProvider);
    final points = await store.points(widget.draftId);
    final nums = renumberStations(
      [for (final p in points) ReviewMarker(type: p.type, number: p.number)],
      manual: {
        for (var i = 0; i < points.length; i++)
          if (points[i].numberManual) i,
      },
    );
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      if (p.type == PointType.station && p.number != nums[i]) {
        await store.savePoint(p.copyWith(number: nums[i]));
      }
    }
  }

  Trail? _duplicate(List<Trail> trails) {
    final d = _draft;
    if (d == null || d.kind != ReportKind.newTrail || d.dupDismissed) {
      return null;
    }
    final start =
        _points.where((p) => p.type == PointType.start).firstOrNull ??
        _points.firstOrNull;
    if (start == null) return null;
    Trail? best;
    var bestD = cfg.duplicateClientRadiusM;
    for (final t in trails) {
      final s = t.startOrNull;
      if (s == null) continue;
      final dist = distanceM(start.lat, start.lng, s.latitude, s.longitude);
      if (dist <= bestD) {
        bestD = dist;
        best = t;
      }
    }
    return best;
  }

  Future<void> _asRevision(Trail t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(rt('report.review.dup.confirm', {'name': t.name})),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(rt('report.common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(rt('report.review.dup.yes')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    _edit(
      (d) => d.copyWith(
        kind: ReportKind.revision,
        targetTrailId: t.id,
        targetTrailName: t.name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = _draft;
    final theme = Theme.of(context);
    if (d == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final trails = ref.watch(trailsProvider).value ?? const <Trail>[];
    final dup = _duplicate(trails);
    final hints = computeReviewHints(
      markers: _markers,
      trackLengthM: _lengthM,
      gapM: _pointsOnly ? 0 : largestGapM(_trimmed),
    );
    final isNew = d.kind == ReportKind.newTrail;
    final approx = _pointsOnly ? '${rt('report.review.approx')} ' : '';
    final km = '$approx${formatKm(_lengthM)}';
    final stationCount = _points
        .where((p) => p.type == PointType.station)
        .length;

    return BannerSuppressor(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            d.kind == ReportKind.revision
                ? rt('report.title.revision', {'name': d.targetTrailName ?? ''})
                : rt('report.review.title'),
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'discard') unawaited(_discard());
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'discard',
                  child: Text(rt('report.review.menu.discard')),
                ),
              ],
            ),
          ],
        ),
        body: ListView(
          controller: _scroll,
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            SizedBox(
              height: 240,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.x3),
                child: ReportMap(
                  controller: _map,
                  segments: _trimmed,
                  points: _points,
                  onPointTap: _openMarker,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.stack),
            Text(
              rt('report.review.summary', {
                'km': km,
                'n': stationCount,
                'p': _photoCount,
              }),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.x3),
            for (final h in hints.hints)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.x2),
                child: HintBox(
                  child: Text(switch (h) {
                    ReviewHint.h1TooShort => rt('report.review.h1'),
                    ReviewHint.h2NoStation => rt('report.review.h2'),
                    ReviewHint.h3Inaccurate => rt('report.review.h3', {
                      'n': hints.inaccurateCount,
                    }),
                    ReviewHint.h4Gap => rt('report.review.h4', {
                      'd': hints.gapM.round(),
                    }),
                    ReviewHint.h5DupNumbers => rt('report.review.h5'),
                  }),
                ),
              ),
            if (dup != null) ...[
              const SizedBox(height: AppSpacing.x2),
              HintBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(rt('report.review.dup.title', {'name': dup.name})),
                    const SizedBox(height: AppSpacing.x3),
                    FilledButton(
                      onPressed: () => _asRevision(dup),
                      child: Text(rt('report.review.dup.yes')),
                    ),
                    TextButton(
                      onPressed: () =>
                          _edit((d) => d.copyWith(dupDismissed: true)),
                      child: Text(rt('report.review.dup.no')),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.section),
            if (isNew) ...[
              TextField(
                key: _nameKey,
                controller: _name,
                maxLength: cfg.titleMaxChars,
                decoration: InputDecoration(
                  labelText: rt('report.review.name'),
                  errorText: _errors.contains(ReviewFieldError.nameTooShort)
                      ? rt('report.review.name.error')
                      : null,
                ),
                onChanged: (v) => _edit((d) => d.copyWith(title: v)),
              ),
              const SizedBox(height: AppSpacing.stack),
              Column(
                key: _areaKey,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rt('report.review.area'),
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  Wrap(
                    spacing: AppSpacing.chip,
                    runSpacing: AppSpacing.chip,
                    children: [
                      for (final a in reportAreas)
                        ChoiceChip(
                          label: Text(kt('gebiet.$a')),
                          selected: d.area == a,
                          onSelected: (_) => _edit((d) => d.copyWith(area: a)),
                        ),
                    ],
                  ),
                  if (_errors.contains(ReviewFieldError.areaMissing))
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.x2),
                      child: Text(
                        rt('report.review.area.error'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.stack),
            ],
            if (d.kind != ReportKind.quick) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(rt('report.review.loop')),
                value: d.isLoop ?? false,
                onChanged: (v) => _edit((d) => d.copyWith(isLoop: v)),
              ),
              Text(
                rt('report.review.stroller'),
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.x2),
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: 'yes',
                    label: Text(rt('report.review.stroller.yes')),
                  ),
                  ButtonSegment(
                    value: 'no',
                    label: Text(rt('report.review.stroller.no')),
                  ),
                  ButtonSegment(
                    value: 'unknown',
                    label: Text(rt('report.review.stroller.unknown')),
                  ),
                ],
                selected: {d.stroller},
                onSelectionChanged: (v) =>
                    _edit((d) => d.copyWith(stroller: v.first)),
              ),
              const SizedBox(height: AppSpacing.stack),
            ],
            TextField(
              controller: _note,
              maxLength: cfg.noteMaxChars,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(labelText: rt('report.review.note')),
              onChanged: (v) => _edit((d) => d.copyWith(note: v)),
            ),
            if (!_pointsOnly && _segments.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.section),
              _TrimCard(
                startM: d.trimStartM,
                endM: d.trimEndM,
                totalM: trackLengthM(_segments),
                onChanged: (s, e) =>
                    _edit((d) => d.copyWith(trimStartM: s, trimEndM: e)),
              ),
            ],
            const SizedBox(height: AppSpacing.section),
            Text(
              rt('report.review.markers'),
              key: _markersKey,
              style: theme.textTheme.titleMedium,
            ),
            if (_errors.contains(ReviewFieldError.tooShort))
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.x2),
                child: Text(
                  rt('report.review.too_short'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            for (final p in _points)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: SizedBox(
                  width: 34,
                  height: 34,
                  child: PointDot(point: p),
                ),
                title: Text(markerLabel(p)),
                subtitle: Text(
                  rt('report.marker.accuracy', {'a': p.accuracyM.round()}),
                ),
                trailing: p.lowAccuracy
                    ? Chip(label: Text(rt('report.marker.inaccurate')))
                    : null,
                onTap: () => _openMarker(p),
              ),
            const SizedBox(height: AppSpacing.section),
            Text(rt('report.review.legal'), style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.stack),
            ReportPrimaryButton(
              label: rt('report.review.submit'),
              loading: _submitting,
              onPressed: _submit,
            ),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _saveAsDraft,
              child: Text(rt('report.review.save_draft')),
            ),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _continueRecording,
              child: Text(rt('report.review.continue_recording')),
            ),
            const SizedBox(height: AppSpacing.x4),
          ],
        ),
      ),
    );
  }
}

/// Kürzen von Anfang und Ende in 10-m-Schritten (Spec 4.5).
class _TrimCard extends StatelessWidget {
  const _TrimCard({
    required this.startM,
    required this.endM,
    required this.totalM,
    required this.onChanged,
  });

  final double startM;
  final double endM;
  final double totalM;
  final void Function(double start, double end) onChanged;

  double get _max =>
      math.min(cfg.trimMaxM, math.max(0.0, totalM - cfg.minTrackLengthM));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return HintBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            rt('report.review.trim.title'),
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(
            rt('report.review.trim.body'),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.x3),
          _row(
            context,
            rt('report.review.trim.start'),
            startM,
            (v) => onChanged(v, endM),
          ),
          _row(
            context,
            rt('report.review.trim.end'),
            endM,
            (v) => onChanged(startM, v),
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    double value,
    ValueChanged<double> set,
  ) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(
          tooltip: '−${cfg.trimStepM.round()} m',
          onPressed: value <= 0
              ? null
              : () => set(math.max(0, value - cfg.trimStepM)),
          icon: const Icon(Icons.remove_circle_outline),
        ),
        SizedBox(
          width: 56,
          child: Text(formatMeters(value), textAlign: TextAlign.center),
        ),
        IconButton(
          tooltip: '+${cfg.trimStepM.round()} m',
          onPressed: value + cfg.trimStepM > _max
              ? null
              : () => set(value + cfg.trimStepM),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}
