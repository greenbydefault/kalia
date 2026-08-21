import 'package:flutter/material.dart';

import '../../../../../app/theme/app_spacing.dart';
import '../../../../../core/config/supabase_config.dart';
import '../../../../../shared/widgets/erlebnis_chip.dart';
import '../../../../community/presentation/add_photo_button.dart';
import '../../../../community/presentation/station_image_strip.dart';
import '../../../domain/station.dart';
import '../../../domain/trail.dart';
import 'steckbrief_table.dart';

/// Karte für eine Station innerhalb des Trail-Sheets:
/// Nummer, Titel, Erlebnisse, Kurztext, Stationsbilder und optionaler
/// Steckbrief.
class StationCard extends StatelessWidget {
  final Trail trail;
  final Station station;
  final EdgeInsetsGeometry margin;

  const StationCard({
    super.key,
    required this.trail,
    required this.station,
    this.margin = const EdgeInsets.only(bottom: AppSpacing.x3),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: margin,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: AppSpacing.x3,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    '${station.reihenfolge}',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(station.titel, style: theme.textTheme.titleSmall),
                      Text(station.thema, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                if (station.barrierefrei)
                  const Tooltip(
                    message: 'Barrierefrei',
                    child: Icon(Icons.accessible, size: 20),
                  ),
                // Stationsbezogene Uploads brauchen die DB-ID der Station
                if (SupabaseConfig.isConfigured && station.id != null)
                  AddPhotoButton(
                    trail: trail,
                    station: station,
                    iconOnly: true,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.x2),
            Wrap(
              spacing: AppSpacing.x3,
              runSpacing: AppSpacing.x1,
              children: [
                for (final e in station.erlebnisse)
                  ErlebnisChip(erlebnisKey: e),
              ],
            ),
            const SizedBox(height: AppSpacing.x2),
            Text(station.kurztext, style: theme.textTheme.bodySmall),
            if (SupabaseConfig.isConfigured && station.id != null) ...[
              const SizedBox(height: AppSpacing.x2),
              StationImageStrip(trailId: trail.id, stationId: station.id!),
            ],
            if (station.steckbrief != null) ...[
              const SizedBox(height: AppSpacing.x2),
              SteckbriefTable(steckbrief: station.steckbrief!),
            ],
          ],
        ),
      ),
    );
  }
}
