import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../data/report_providers.dart';
import '../data/report_recorder.dart';
import '../report_copy.dart';
import 'recording_screen.dart';
import 'review_screen.dart';

/// Schlüssel für den Navigator der App, damit das Banner (außerhalb des
/// Navigators) die Aufnahme öffnen kann.
final reportNavigatorKey = GlobalKey<NavigatorState>();

/// Anzahl der Screens, die das Banner verdecken (R2 und R4).
final reportBannerSuppressProvider = NotifierProvider<_SuppressNotifier, int>(
  _SuppressNotifier.new,
);

class _SuppressNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void inc() => state = state + 1;

  void dec() => state = state > 0 ? state - 1 : 0;
}

/// Hält das Banner für die Lebensdauer des Kindes aus.
class BannerSuppressor extends StatefulWidget {
  const BannerSuppressor({super.key, required this.child});

  final Widget child;

  @override
  State<BannerSuppressor> createState() => _BannerSuppressorState();
}

class _BannerSuppressorState extends State<BannerSuppressor> {
  late final ProviderContainer _container;

  @override
  void initState() {
    super.initState();
    _container = ProviderScope.containerOf(context, listen: false);
    Future.microtask(
      () => _container.read(reportBannerSuppressProvider.notifier).inc(),
    );
  }

  @override
  void dispose() {
    Future.microtask(
      () => _container.read(reportBannerSuppressProvider.notifier).dec(),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Setzt das Banner „Aufnahme läuft“ unter die Statusleiste, solange eine
/// Aufnahme läuft und kein Aufnahme- oder Prüfen-Screen offen ist (E-8).
class RecordingBannerHost extends ConsumerWidget {
  const RecordingBannerHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rec = ref.watch(reportRecorderProvider);
    final suppressed = ref.watch(reportBannerSuppressProvider) > 0;
    final show = rec != null && !suppressed;
    final media = MediaQuery.of(context);
    return Column(
      children: [
        if (show)
          _Banner(state: rec)
        else
          const SizedBox.shrink(key: ValueKey('no-banner')),
        Expanded(
          key: const ValueKey('app-body'),
          child: MediaQuery(
            data: show ? media.removePadding(removeTop: true) : media,
            child: child,
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.state});

  final RecorderState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = state.paused
        ? rt('report.banner.paused')
        : state.pointsOnly
        ? '${rt('report.status.recording')} · '
              '${state.stationCount} ${rt('report.rec.chip.station')}'
        : rt('report.banner.running', {
            'km': formatKm(state.lengthM),
            'n': state.stationCount,
          });
    return Material(
      color: AppColors.n900,
      child: InkWell(
        onTap: () => reportNavigatorKey.currentState?.push(
          MaterialPageRoute<void>(builder: (_) => const RecordingScreen()),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x4,
              vertical: AppSpacing.x3,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.fiber_manual_record,
                  size: 12,
                  color: AppColors.paper,
                ),
                const SizedBox(width: AppSpacing.x2),
                Expanded(
                  child: Text(
                    text,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.paper,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.paper,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// R15: Nach einem Neustart fragt die App, was mit einer unterbrochenen
/// Aufnahme passieren soll. Einmal pro App-Start.
class ReportRecoveryHost extends ConsumerStatefulWidget {
  const ReportRecoveryHost({super.key});

  @override
  ConsumerState<ReportRecoveryHost> createState() => _ReportRecoveryHostState();
}

class _ReportRecoveryHostState extends ConsumerState<ReportRecoveryHost> {
  bool _asked = false;

  void _check(List<dynamic> drafts) {
    if (_asked) return;
    final rec = ref.read(reportRecorderProvider);
    if (rec != null) {
      _asked = true;
      return;
    }
    final interrupted = ref.read(activeRecordingDraftProvider);
    if (interrupted == null) return;
    _asked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_ask(interrupted.id));
    });
  }

  Future<void> _ask(String id) async {
    final nav = reportNavigatorKey.currentState;
    final ctx = reportNavigatorKey.currentContext;
    if (nav == null || ctx == null) return;
    final choice = await showDialog<String>(
      context: ctx,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: Text(rt('report.recover.title')),
        content: Text(rt('report.recover.body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop('discard'),
            child: Text(rt('report.recover.discard')),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop('review'),
            child: Text(rt('report.recover.review')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(c).pop('continue'),
            child: Text(rt('report.recover.continue')),
          ),
        ],
      ),
    );
    if (!mounted) return;
    final rec = ref.read(reportRecorderProvider.notifier);
    switch (choice) {
      case 'continue':
        await rec.resume(id);
        unawaited(
          nav.push(
            MaterialPageRoute<void>(builder: (_) => const RecordingScreen()),
          ),
        );
      case 'review':
        final d = await rec.finishStored(id);
        if (d != null) {
          unawaited(
            nav.push(
              MaterialPageRoute<void>(
                builder: (_) => ReviewScreen(draftId: d.id),
              ),
            ),
          );
        }
      case 'discard':
        await ref.read(reportDraftsProvider.notifier).delete(id);
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final drafts = ref.watch(reportDraftsProvider);
    if (drafts.hasValue) _check(drafts.value!);
    return const SizedBox.shrink();
  }
}
