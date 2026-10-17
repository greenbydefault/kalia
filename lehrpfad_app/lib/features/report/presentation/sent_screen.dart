import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/shell_tab_provider.dart';
import '../../../app/theme/app_spacing.dart';
import '../data/report_providers.dart';
import '../domain/report_enums.dart';
import '../domain/report_models.dart';
import '../report_copy.dart';
import 'my_reports_screen.dart';
import 'report_widgets.dart';

/// R6 „Gesendet“. Drei Varianten: voll, kurz (Schnellmeldung), offline
/// beziehungsweise wartet auf Konto.
class SentScreen extends ConsumerWidget {
  const SentScreen({
    super.key,
    required this.draftId,
    this.awaitingAccount = false,
  });

  final String draftId;
  final bool awaitingAccount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final drafts = ref.watch(reportDraftsProvider).value ?? const [];
    ReportDraft? d;
    for (final x in drafts) {
      if (x.id == draftId) d = x;
    }
    final quick = d?.isQuick ?? false;
    final queued =
        awaitingAccount ||
        (d != null &&
            (d.status == DraftStatus.queued ||
                d.status == DraftStatus.uploading ||
                d.status == DraftStatus.awaitingAccount));
    final title = queued
        ? rt('report.sent.title_offline')
        : quick
        ? rt('report.sent.title_quick')
        : rt('report.sent.title');

    void done() {
      Navigator.of(context).popUntil((r) => r.isFirst);
      ref.read(shellTabIndexProvider.notifier).goTo(4);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) done();
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Icon(
                  queued ? Icons.schedule : Icons.check_circle_outline,
                  size: 64,
                ),
                const SizedBox(height: AppSpacing.section),
                Text(
                  title,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                if (!quick && !queued) ...[
                  const SizedBox(height: AppSpacing.section),
                  Text(rt('report.sent.step1')),
                  const SizedBox(height: AppSpacing.x2),
                  Text(rt('report.sent.step2')),
                  const SizedBox(height: AppSpacing.x2),
                  Text(rt('report.sent.step3')),
                ],
                const Spacer(),
                ReportPrimaryButton(
                  label: rt('report.sent.mine'),
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => const MyReportsScreen(),
                      ),
                    );
                  },
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: done,
                  child: Text(rt('report.sent.done')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
