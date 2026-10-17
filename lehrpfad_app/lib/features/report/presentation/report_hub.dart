import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../shared/widgets/show_app_modal_sheet.dart';
import '../../trail/domain/station.dart';
import '../../trail/domain/trail.dart';
import '../data/report_providers.dart';
import '../data/report_recorder.dart';
import '../domain/report_enums.dart';
import '../domain/report_models.dart';
import '../report_copy.dart';
import 'fix_screens.dart';
import 'my_reports_screen.dart';
import 'permission_screen.dart';
import 'prepare_screen.dart';
import 'recording_screen.dart';
import 'report_widgets.dart';
import 'review_screen.dart';

enum _HubChoice { resume, draft, newTrail, fix, mine }

/// R0 „Hub“: Einstieg über das Konto-Tab und die Detailseite.
Future<void> showReportHub(BuildContext context) async {
  final choice = await showAppModalSheet<_HubChoice>(
    context: context,
    builder: (_) => const _HubSheet(),
  );
  if (choice == null || !context.mounted) return;
  switch (choice) {
    case _HubChoice.resume:
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const RecordingScreen()));
    case _HubChoice.draft:
      final container = ProviderScope.containerOf(context, listen: false);
      final list = container.read(reportDraftsProvider).value ?? const [];
      final d = list.where(_isResumableDraft).firstOrNull;
      if (d != null) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => ReviewScreen(draftId: d.id)),
        );
      }
    case _HubChoice.newTrail:
      await startNewTrailFlow(context);
    case _HubChoice.fix:
      await startFixFlow(context);
    case _HubChoice.mine:
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const MyReportsScreen()));
  }
}

bool _isResumableDraft(ReportDraft d) =>
    d.kind != ReportKind.quick && d.status == DraftStatus.review;

/// Aufnahme-Funktionen laufen nur in der App (Spec 12, Web).
bool _blockedOnWeb(BuildContext context) {
  if (!kIsWeb) return false;
  showReportSnack(context, rt('report.err.web'));
  return true;
}

/// „Neuen Pfad aufnehmen“ (E-1 bis E-2): Berechtigung, Vorbereitung.
Future<void> startNewTrailFlow(BuildContext context) async {
  if (_blockedOnWeb(context)) return;
  final container = ProviderScope.containerOf(context, listen: false);
  if (container.read(reportRecorderProvider) != null) {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const RecordingScreen()));
    return;
  }
  if (!await ensureReportPermission(context)) return;
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => const PrepareScreen(kind: ReportKind.newTrail),
    ),
  );
}

/// Neuaufnahme eines bestehenden Pfads (R10 „Der Pfad verläuft anders“).
Future<void> startRevisionFlow(BuildContext context, Trail trail) async {
  if (_blockedOnWeb(context)) return;
  final container = ProviderScope.containerOf(context, listen: false);
  if (container.read(reportRecorderProvider) != null) {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const RecordingScreen()));
    return;
  }
  if (!await ensureReportPermission(context)) return;
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PrepareScreen(kind: ReportKind.revision, trail: trail),
    ),
  );
}

/// „Bestehenden Pfad korrigieren“: ohne Pfad zuerst R9, mit Pfad direkt R10.
Future<void> startFixFlow(
  BuildContext context, {
  Trail? trail,
  Station? station,
}) async {
  if (_blockedOnWeb(context)) return;
  if (!await ensureReportPermission(context)) return;
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => trail == null
          ? const PickTrailScreen()
          : station != null
          ? MoveStationScreen(trail: trail, initialStation: station)
          : FixHubScreen(trail: trail),
    ),
  );
}

class _HubSheet extends ConsumerWidget {
  const _HubSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rec = ref.watch(reportRecorderProvider);
    final drafts = ref.watch(reportDraftsProvider).value ?? const [];
    final draft = drafts.where(_isResumableDraft).firstOrNull;

    Widget tile(
      IconData icon,
      String title,
      String? sub,
      _HubChoice value, {
      bool strong = false,
    }) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon),
        title: Text(title, style: strong ? theme.textTheme.titleMedium : null),
        subtitle: sub == null ? null : Text(sub),
        onTap: () => Navigator.of(context).pop(value),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(rt('report.hub.title'), style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.x2),
        if (rec != null)
          tile(
            Icons.fiber_manual_record,
            rt('report.hub.resume_recording', {
              'km': formatKm(rec.lengthM),
              'n': rec.stationCount,
            }),
            null,
            _HubChoice.resume,
            strong: true,
          )
        else if (draft != null)
          tile(
            Icons.edit_note,
            rt('report.hub.resume_draft'),
            null,
            _HubChoice.draft,
            strong: true,
          ),
        tile(
          Icons.add_location_alt_outlined,
          rt('report.hub.new'),
          rt('report.hub.new.sub'),
          _HubChoice.newTrail,
        ),
        tile(
          Icons.edit_location_alt_outlined,
          rt('report.hub.fix'),
          rt('report.hub.fix.sub'),
          _HubChoice.fix,
        ),
        tile(
          Icons.inbox_outlined,
          rt('report.hub.mine'),
          null,
          _HubChoice.mine,
        ),
      ],
    );
  }
}
