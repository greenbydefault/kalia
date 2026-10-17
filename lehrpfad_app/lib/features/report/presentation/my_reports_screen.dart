import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/config/supabase_config.dart';
import '../../auth/data/auth_providers.dart';
import '../../auth/presentation/account_prompt_sheet.dart';
import '../data/report_providers.dart';
import '../data/report_recorder.dart';
import '../data/report_server.dart';
import '../data/report_uploader.dart';
import '../domain/report_enums.dart';
import '../domain/report_models.dart';
import '../report_copy.dart';
import 'recording_screen.dart';
import 'report_detail_screen.dart';
import 'report_hub.dart';
import 'report_labels.dart';
import 'report_widgets.dart';
import 'review_screen.dart';

/// R7 „Meine Meldungen“: Entwürfe, In Bearbeitung, Abgeschlossen.
class MyReportsScreen extends ConsumerStatefulWidget {
  const MyReportsScreen({super.key});

  @override
  ConsumerState<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends ConsumerState<MyReportsScreen> {
  bool _refreshFailed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh(silent: true));
  }

  Future<void> _refresh({bool silent = false}) async {
    if (!SupabaseConfig.isConfigured) return;
    if (ref.read(authStateProvider).value == null) return;
    unawaited(ref.read(reportUploaderProvider).flush());
    final ok = await ref.read(reportServerProvider).refresh();
    if (!mounted) return;
    setState(() => _refreshFailed = !ok);
    if (!ok && !silent) {
      showReportSnack(context, rt('report.list.refresh_error'));
    }
  }

  Future<void> _open(ReportDraft d) async {
    final nav = Navigator.of(context);
    switch (d.status) {
      case DraftStatus.recording:
      case DraftStatus.paused:
        final rec = ref.read(reportRecorderProvider);
        if (rec == null || rec.draft.id != d.id) {
          await ref.read(reportRecorderProvider.notifier).resume(d.id);
        }
        if (!mounted) return;
        await nav.push(
          MaterialPageRoute<void>(builder: (_) => const RecordingScreen()),
        );
      case DraftStatus.review:
        await nav.push(
          MaterialPageRoute<void>(builder: (_) => ReviewScreen(draftId: d.id)),
        );
      case DraftStatus.awaitingAccount:
      case DraftStatus.queued:
      case DraftStatus.uploading:
      case DraftStatus.failed:
      case DraftStatus.submitted:
        await nav.push(
          MaterialPageRoute<void>(
            builder: (_) => ReportDetailScreen(draftId: d.id),
          ),
        );
    }
  }

  Future<void> _delete(ReportDraft d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(rt('report.list.delete.title')),
        content: Text(rt('report.list.delete.body')),
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
    if (ok != true) return;
    final rec = ref.read(reportRecorderProvider);
    if (rec != null && rec.draft.id == d.id) {
      await ref.read(reportRecorderProvider.notifier).discard();
    } else {
      await ref.read(reportDraftsProvider.notifier).delete(d.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final drafts = ref.watch(reportDraftsProvider).value ?? const [];
    final signedIn =
        SupabaseConfig.isConfigured &&
        ref.watch(authStateProvider).value != null;
    final groups = {
      for (final g in ReportGroup.values)
        g: [
          for (final d in drafts)
            if (reportGroup(d) == g) d,
        ],
    };
    DateTime? checked;
    for (final d in drafts) {
      final c = d.serverCheckedAt;
      if (c != null && (checked == null || c.isAfter(checked))) checked = c;
    }

    final children = <Widget>[];
    if (!signedIn && SupabaseConfig.isConfigured) {
      children.add(
        Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.stack),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(rt('report.list.login_card')),
                const SizedBox(height: AppSpacing.x3),
                FilledButton(
                  onPressed: () async {
                    final ok = await requireAccount(
                      context,
                      reason: rt('report.list.login_card'),
                    );
                    if (ok) unawaited(_refresh());
                  },
                  child: Text(rt('report.detail.relogin.cta')),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (checked != null && _refreshFailed) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.x2),
          child: Text(
            rt('report.list.stale', {'time': formatTime(checked)}),
            style: theme.textTheme.bodySmall,
          ),
        ),
      );
    }

    void section(ReportGroup g, String titleKey) {
      final list = groups[g]!;
      if (list.isEmpty) return;
      children.add(
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.x2,
            bottom: AppSpacing.x2,
          ),
          child: Text(rt(titleKey), style: theme.textTheme.titleMedium),
        ),
      );
      for (final d in list) {
        final row = _Row(draft: d, onTap: () => _open(d));
        children.add(
          g == ReportGroup.drafts
              ? Dismissible(
                  key: ValueKey('d-${d.id}'),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    await _delete(d);
                    return false;
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: AppSpacing.x4),
                    color: AppColors.n200,
                    child: const Icon(Icons.delete_outline),
                  ),
                  child: row,
                )
              : row,
        );
      }
    }

    section(ReportGroup.drafts, 'report.list.drafts');
    section(ReportGroup.open, 'report.list.open');
    section(ReportGroup.done, 'report.list.done');

    if (drafts.isEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.section),
          child: Column(
            children: [
              Text(
                rt('report.list.empty'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.stack),
              FilledButton(
                onPressed: () => showReportHub(context),
                child: Text(rt('report.list.empty.cta')),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(rt('report.list.title'))),
      body: RefreshIndicator(
        onRefresh: () => _refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.page),
          children: children,
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.draft, required this.onTap});

  final ReportDraft draft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unseen = isUnseen(draft);
    final sub = draft.isLocalDraft && draft.status == DraftStatus.review
        ? rt('report.list.draft_old', {'date': formatDate(draft.updatedAt)})
        : formatDate(draft.createdAt);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      title: Text(
        reportTitle(draft),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(sub),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (unseen)
            const Padding(
              padding: EdgeInsets.only(right: AppSpacing.x2),
              child: Icon(Icons.circle, size: 10, color: AppColors.ink),
            ),
          Chip(
            label: Text(reportStatusLabel(draft)),
            labelStyle: theme.textTheme.labelMedium,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
