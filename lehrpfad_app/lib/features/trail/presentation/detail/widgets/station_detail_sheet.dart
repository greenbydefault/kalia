import 'package:flutter/material.dart';

import '../../../../../shared/widgets/show_app_modal_sheet.dart';
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
    return StationCard(trail: trail, station: station, margin: EdgeInsets.zero);
  }
}
