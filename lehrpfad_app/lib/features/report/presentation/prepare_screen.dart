import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../shared/widgets/hint_box.dart';
import '../../../shared/widgets/show_app_modal_sheet.dart';
import '../../trail/domain/trail.dart';
import '../../trail_progress/tracking/location_service.dart';
import '../data/report_recorder.dart';
import '../domain/report_enums.dart';
import '../logic/geo.dart';
import '../logic/signal.dart';
import '../report_config.dart';
import '../report_copy.dart';
import 'permission_screen.dart';
import 'recording_screen.dart';
import 'report_widgets.dart';

/// R1 „Vorbereitung“: Signal abwarten, Modus erklären, Aufnahme starten.
/// Mit [trail] ist es die Neuaufnahme eines bestehenden Pfads.
class PrepareScreen extends ConsumerStatefulWidget {
  const PrepareScreen({super.key, required this.kind, this.trail});

  final ReportKind kind;
  final Trail? trail;

  @override
  ConsumerState<PrepareScreen> createState() => _PrepareScreenState();
}

class _PrepareScreenState extends ConsumerState<PrepareScreen> {
  StreamSubscription<LocationFix>? _sub;
  Timer? _tick;
  LocationFix? _fix;
  DateTime _lastFix = DateTime.now();
  final DateTime _opened = DateTime.now();
  double _sinceOpen = 0;
  double _sinceFix = 0;
  bool _starting = false;
  final RecordingMode _mode = RecordingMode.trackAndPoints;

  @override
  void initState() {
    super.initState();
    _sub = ref
        .read(locationServiceProvider)
        .watchFixes(LocationProfile.pointFix)
        .listen((f) {
          if (!mounted) return;
          setState(() {
            _fix = f;
            _lastFix = DateTime.now();
          });
        }, onError: (_) {});
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final now = DateTime.now();
      setState(() {
        _sinceOpen = now.difference(_opened).inMilliseconds / 1000;
        _sinceFix = now.difference(_lastFix).inMilliseconds / 1000;
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  double? get _acc => _fix?.accuracyM;

  SignalLevel get _level =>
      signalLevel(accuracyM: _acc, secondsSinceFix: _sinceFix);

  Future<void> _start({required bool anyway}) async {
    if (_starting) return;
    setState(() => _starting = true);
    await maybeShowBatteryHint(context);
    if (!mounted) return;
    final trail = widget.trail;
    await ref
        .read(reportRecorderProvider.notifier)
        .start(
          kind: widget.kind,
          mode: _mode,
          targetTrailId: trail?.id,
          targetTrailName: trail?.name,
          lowAccuracyStart: anyway || !signalAllowsStart(_acc),
        );
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const RecordingScreen()),
    );
  }

  void _modeHelp() {
    showAppModalSheet<void>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            rt('report.prep.mode_help_track'),
            style: Theme.of(ctx).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.x3),
          Text(
            rt('report.prep.mode_help_points'),
            style: Theme.of(ctx).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.stack),
          ReportPrimaryButton(
            label: rt('report.prep.understood'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trail = widget.trail;
    final ready = signalAllowsStart(_acc) && _sinceFix <= cfg.noSignalAfterS;
    final anyway =
        !ready &&
        _fix != null &&
        showStartAnyway(accuracyM: _acc, secondsSinceOpen: _sinceOpen);

    double? farM;
    final start = trail?.startOrNull;
    if (start != null && _fix != null) {
      final d = distanceM(
        _fix!.position.latitude,
        _fix!.position.longitude,
        start.latitude,
        start.longitude,
      );
      if (d > cfg.revisionStartWarnM) farM = d;
    }

    return Scaffold(
      appBar: AppBar(title: Text(rt('report.prep.title'))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (trail != null) ...[
                Text(
                  rt('report.prep.revision_start', {'name': trail.name}),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.x3),
              ] else ...[
                for (final k in const [
                  'report.prep.tip1',
                  'report.prep.tip2',
                  'report.prep.tip3',
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.x3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(
                            top: 2,
                            right: AppSpacing.x2,
                          ),
                          child: Icon(Icons.check, size: 18),
                        ),
                        Expanded(child: Text(rt(k))),
                      ],
                    ),
                  ),
              ],
              if (farM != null)
                HintBox(
                  child: Text(
                    rt('report.prep.far_warning', {'d': farM.round()}),
                  ),
                ),
              const SizedBox(height: AppSpacing.stack),
              Row(
                children: [SignalPill(level: _level, accuracyM: _acc)],
              ),
              const SizedBox(height: AppSpacing.stack),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _mode == RecordingMode.trackAndPoints
                          ? rt('report.prep.mode_track')
                          : rt('report.prep.mode_points'),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: _modeHelp,
                    child: Text(rt('report.prep.mode_help')),
                  ),
                ],
              ),
              const Spacer(),
              if (ready)
                ReportPrimaryButton(
                  label: rt('report.prep.start'),
                  height: 64,
                  loading: _starting,
                  onPressed: () => _start(anyway: false),
                )
              else if (anyway)
                ReportPrimaryButton(
                  label: rt('report.prep.start_anyway'),
                  height: 64,
                  loading: _starting,
                  onPressed: () => _start(anyway: true),
                )
              else
                ReportPrimaryButton(
                  label: rt('report.prep.searching'),
                  height: 64,
                  onPressed: null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
