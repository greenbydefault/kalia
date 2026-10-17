import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../core/config/supabase_config.dart';
import '../../../../../shared/widgets/show_app_modal_sheet.dart';
import '../../../../report/presentation/report_banner.dart';
import '../../../../report/presentation/report_hub.dart';
import '../../../../report/report_copy.dart';
import '../../../domain/station.dart';
import '../../../domain/trail.dart';
import 'station_card.dart';

/// Modal-Detail zu einer Station (heutiger StationCard-Inhalt).
class StationDetailSheet extends StatelessWidget {
  const StationDetailSheet({
    super.key,
    required this.trail,
    required this.station,
  });

  final Trail trail;
  final Station station;

  static Future<void> show(BuildContext context, Trail trail, Station station) {
    return showAppModalSheet<void>(
      context: context,
      builder: (_) => StationDetailSheet(trail: trail, station: station),
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = StationCard(
      trail: trail,
      station: station,
      margin: EdgeInsets.zero,
    );
    if (!SupabaseConfig.isConfigured || kIsWeb) return card;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card,
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () {
              final root = reportNavigatorKey.currentContext;
              Navigator.of(context).pop();
              if (root != null) {
                startFixFlow(root, trail: trail, station: station);
              }
            },
            child: Text(rt('report.fix.link')),
          ),
        ),
      ],
    );
  }
}
