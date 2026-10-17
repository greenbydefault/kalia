import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../data/report_providers.dart';
import '../data/report_server.dart';
import '../report_copy.dart';
import 'my_reports_screen.dart';
import 'report_hub.dart';

/// E-1 und E-2: Kachel „Pfad melden“ und Eintrag „Meine Meldungen“ im
/// Konto-Tab. Der Punkt zeigt einen ungesehenen Statuswechsel (E-8).
class ReportAccountTiles extends ConsumerWidget {
  const ReportAccountTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drafts = ref.watch(reportDraftsProvider).value ?? const [];
    final unseen = drafts.any(isUnseen);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.add_location_alt_outlined),
                title: Text(rt('report.tile.title')),
                subtitle: Text(rt('report.tile.sub')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showReportHub(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.inbox_outlined),
                title: Text(rt('report.hub.mine')),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (unseen)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.circle,
                          size: 10,
                          color: AppColors.ink,
                        ),
                      ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MyReportsScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
