import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/connectivity/offline_provider.dart';
import '../../../shared/widgets/hint_box.dart';
import '../../auth/presentation/account_prompt_sheet.dart';
import '../../trail/data/providers.dart';
import '../../trail_progress/presentation/open_trail_on_map.dart';
import '../data/report_providers.dart';
import '../data/report_server.dart';
import '../data/report_uploader.dart';
import '../domain/report_enums.dart';
import '../domain/report_models.dart';
import '../logic/draft_transitions.dart';
import '../report_copy.dart';
import 'report_hub.dart';
import 'report_labels.dart';
import 'report_widgets.dart';
import 'review_screen.dart';

/// R8 „Meldung“: Status, Verlauf, Antwort, Zurückziehen, Wiederholen.
class ReportDetailScreen extends ConsumerStatefulWidget {
  const ReportDetailScreen({super.key, required this.draftId});

  final String draftId;

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  final _map = MapController();
  final _reply = TextEditingController();
  List<ReportEvent> _events = const [];
  List<DraftPoint> _points = const [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _map.dispose();
    _reply.dispose();
    super.dispose();
  }

  ReportDraft? get _draft {
    final list = ref.read(reportDraftsProvider).value ?? const [];
    for (final d in list) {
      if (d.id == widget.draftId) return d;
    }
    return null;
  }

  Future<void> _load() async {
    final d = _draft;
    if (d == null) return;
    final store = ref.read(reportDraftStoreProvider);
    final points = await store.points(d.id);
    List<ReportEvent> events = const [];
    if (d.serverId != null) {
      unawaited(ref.read(reportServerProvider).refresh());
      try {
        events = await ref.read(reportServerProvider).events(d.serverId!);
      } catch (_) {}
    }
    // Gesehen: Punkt in R7 verschwindet.
    final status = d.serverStatus;
    if (status != null && d.lastSeenStatus != status.name) {
      await ref
          .read(reportDraftsProvider.notifier)
          .save(
            d.copyWith(lastSeenStatus: status.name, updatedAt: d.updatedAt),
          );
    }
    if (!mounted) return;
    setState(() {
      _points = points;
      _events = events;
    });
  }

  Future<void> _withdraw(ReportDraft d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(rt('report.detail.withdraw.title')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(rt('report.common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(rt('report.detail.withdraw.yes')),
          ),
        ],
      ),
    );
    if (ok != true || d.serverId == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(reportServerProvider).withdraw(d.serverId!);
      await ref.read(reportServerProvider).refresh();
      await _load();
    } catch (_) {
      if (mounted) showReportSnack(context, rt('report.list.refresh_error'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendReply(ReportDraft d) async {
    final text = _reply.text.trim();
    if (text.isEmpty || d.serverId == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(reportServerProvider).reply(d.serverId!, text);
      _reply.clear();
      if (mounted) showReportSnack(context, rt('report.detail.reply.sent'));
      await _load();
    } catch (_) {
      if (mounted) showReportSnack(context, rt('report.list.refresh_error'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit(ReportDraft d) async {
    final next = nextDraftStatus(d.status, DraftEvent.edit) ?? d.status;
    await ref
        .read(reportDraftsProvider.notifier)
        .save(d.copyWith(status: next, clearFailure: true));
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => ReviewScreen(draftId: d.id)),
    );
  }

  Future<void> _login(ReportDraft d) async {
    final ok = await requireAccount(context, reason: rt('report.account.body'));
    if (ok) await ref.read(reportUploaderProvider).retry(d.id);
  }

  String _eventLabel(ReportEvent e) {
    const known = {
      'submitted',
      'in_review',
      'needs_info',
      'user_reply',
      'decided',
      'withdrawn',
    };
    return known.contains(e.event)
        ? rt('report.detail.event.${e.event}')
        : e.event;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(reportDraftsProvider);
    final d = _draft;
    final theme = Theme.of(context);
    final offline = ref.watch(offlineProvider);
    if (d == null) {
      return Scaffold(
        appBar: AppBar(title: Text(rt('report.detail.title'))),
        body: Center(child: Text(rt('report.detail.gone'))),
      );
    }

    final status = d.serverStatus;
    String? statusText;
    if (d.status == DraftStatus.submitted) {
      statusText = switch (status) {
        null ||
        SubmissionStatus.submitted => rt('report.status.text.submitted'),
        SubmissionStatus.inReview => rt('report.status.text.in_review'),
        SubmissionStatus.needsInfo => rt('report.status.text.needs_info'),
        SubmissionStatus.approved =>
          d.kind == ReportKind.newTrail
              ? rt('report.status.text.approved_new')
              : rt('report.status.text.approved'),
        SubmissionStatus.partiallyApproved => rt('report.status.text.partial', {
          'note': d.decisionNote ?? '',
        }).trim(),
        SubmissionStatus.rejected => rt(
          decisionReasonKey(d.decisionReason ?? DecisionReason.other),
          {'note': d.decisionNote ?? ''},
        ).trim(),
        SubmissionStatus.withdrawn => rt('report.status.text.withdrawn'),
      };
    }

    final photoDone = d.photosExpected - d.photosMissing;
    final canWithdraw =
        d.status == DraftStatus.submitted &&
        (status == null || status == SubmissionStatus.submitted);
    final trails = ref.watch(trailsProvider).value ?? const [];
    final target = d.targetTrailId == null
        ? null
        : trails.where((t) => t.id == d.targetTrailId).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(reportTitle(d))),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          if (_points.isNotEmpty)
            SizedBox(
              height: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.x3),
                child: ReportMap(
                  controller: _map,
                  points: _points,
                  interactive: false,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.stack),
          Row(
            children: [
              Chip(label: Text(reportStatusLabel(d))),
              const Spacer(),
              Text(formatDate(d.createdAt), style: theme.textTheme.bodySmall),
            ],
          ),
          if (statusText != null) ...[
            const SizedBox(height: AppSpacing.x2),
            Text(statusText, style: theme.textTheme.bodyMedium),
          ],
          if (d.status == DraftStatus.failed && d.failureCode != null) ...[
            const SizedBox(height: AppSpacing.x2),
            HintBox(child: Text(_failText(d.failureCode!))),
          ],
          if (status == SubmissionStatus.needsInfo &&
              d.serverQuestion != null) ...[
            const SizedBox(height: AppSpacing.stack),
            HintBox(child: Text(d.serverQuestion!)),
            const SizedBox(height: AppSpacing.x3),
            TextField(
              controller: _reply,
              minLines: 2,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: rt('report.detail.reply.label'),
              ),
            ),
            ReportPrimaryButton(
              label: rt('report.detail.reply.send'),
              loading: _busy,
              onPressed: offline ? null : () => _sendReply(d),
            ),
          ],
          if (d.photosMissing > 0) ...[
            const SizedBox(height: AppSpacing.stack),
            Text(
              rt('report.detail.photos_uploaded', {
                'n': photoDone,
                'm': d.photosExpected,
              }),
              style: theme.textTheme.bodySmall,
            ),
            TextButton(
              onPressed: () => ref.read(reportUploaderProvider).retry(d.id),
              child: Text(rt('report.detail.photos_resend')),
            ),
          ],
          const SizedBox(height: AppSpacing.section),
          if (_events.isNotEmpty) ...[
            Text(
              rt('report.detail.history'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.x2),
            for (final e in _events)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(_eventLabel(e)),
                subtitle: Text(
                  '${formatDate(e.at.toLocal())} ${formatTime(e.at.toLocal())}'
                  '${_eventText(e)}',
                ),
              ),
            const SizedBox(height: AppSpacing.stack),
          ],
          if (d.status == DraftStatus.awaitingAccount)
            ReportPrimaryButton(
              label: rt('report.detail.relogin.cta'),
              onPressed: () => _login(d),
            ),
          if (d.status == DraftStatus.failed) ...[
            ReportPrimaryButton(
              label: rt('report.detail.edit'),
              onPressed: () => _edit(d),
            ),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => ref.read(reportUploaderProvider).retry(d.id),
              child: Text(rt('report.detail.retry')),
            ),
          ],
          if (d.status == DraftStatus.queued)
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => ref.read(reportUploaderProvider).retry(d.id),
              child: Text(rt('report.detail.retry')),
            ),
          if (status == SubmissionStatus.approved && target != null)
            ReportPrimaryButton(
              label: rt('report.detail.open_trail'),
              onPressed: () {
                Navigator.of(context).popUntil((r) => r.isFirst);
                openTrailOnMap(context, ref, target, detail: true);
              },
            ),
          if (status == SubmissionStatus.rejected ||
              status == SubmissionStatus.withdrawn)
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => showReportHub(context),
              child: Text(rt('report.detail.again')),
            ),
          if (canWithdraw)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.x2),
              child: Column(
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: offline || _busy ? null : () => _withdraw(d),
                    child: Text(rt('report.detail.withdraw')),
                  ),
                  if (offline)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.x2),
                      child: Text(
                        rt('report.detail.withdraw.offline'),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _eventText(ReportEvent e) {
    final text = e.payload['text'] ?? e.payload['question'];
    return text is String && text.isNotEmpty ? '\n$text' : '';
  }

  String _failText(String code) {
    final key = 'report.err.$code';
    return reportTexte.containsKey(key)
        ? rt(key)
        : rt('report.err.invalid_payload');
  }
}
