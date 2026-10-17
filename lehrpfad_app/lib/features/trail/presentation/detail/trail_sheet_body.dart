import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../shared/widgets/tag_chip.dart';
import '../../../community/presentation/add_photo_button.dart';
import '../../../community/presentation/comments_section.dart';
import '../../../community/presentation/rating_section.dart';
import '../../../nearby/data/nearby_providers.dart';
import '../../../nearby_trails/domain/karte_copy.dart';
import '../../../report/presentation/report_hub.dart';
import '../../../nearby/presentation/nearby_section.dart';
import '../../../species/data/species_providers.dart';
import '../../../species/presentation/arten_section.dart';
import '../../../trail_progress/presentation/gelaufen_action.dart';
import '../../domain/trail.dart';
import '../../track_engine/trail_track_view.dart';
import 'widgets/anreise_section.dart';
import 'widgets/eignung_section.dart';
import 'widgets/fact_chip.dart';
import 'widgets/sheet_accordion_section.dart';
import 'widgets/station_carousel.dart';
import 'widgets/station_detail_sheet.dart';

/// Expanded-Inhalt des Trail-Sheets (Fakten, Track, Accordions, Community).
class TrailSheetBody extends ConsumerWidget {
  const TrailSheetBody({super.key, required this.trail});

  final Trail trail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final headingStyle = theme.textTheme.titleMedium;
    final species = ref.watch(trailSpeciesProvider(trail.id)).asData?.value;
    final hasArten = species?.any((s) => s.isFlora || s.isFauna) ?? false;
    final hasGeraete = species?.any((s) => s.isGeraet) ?? false;
    final nearby = ref.watch(nearbyPlacesProvider(trail.id)).asData?.value;
    final hasNearby = nearby != null && nearby.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (SupabaseConfig.isConfigured) ...[
          Wrap(
            spacing: AppSpacing.chip,
            runSpacing: AppSpacing.chip,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AddPhotoButton(trail: trail),
              if (!kIsWeb)
                TextButton.icon(
                  onPressed: () => startFixFlow(context, trail: trail),
                  icon: const Icon(Icons.flag_outlined),
                  label: Text(kt('karte.melden')),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.stack),
        ],
        Wrap(
          spacing: AppSpacing.chip,
          runSpacing: AppSpacing.chip,
          children: [
            if (trail.isFlaeche)
              const FactChip(icon: Icons.park_outlined, label: 'Platz')
            else
              FactChip(icon: Icons.route, label: trail.laengeLabel),
            FactChip(icon: Icons.schedule, label: trail.dauerLabel),
            FactChip(icon: Icons.place_outlined, label: trail.region),
            FactChip(icon: Icons.signpost_outlined, label: trail.markierung),
          ],
        ),
        const SizedBox(height: AppSpacing.stack),
        EignungSection(trail: trail),
        if (trail.displayTags.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.stack),
          Wrap(
            spacing: AppSpacing.chip,
            runSpacing: AppSpacing.chip,
            children: [
              for (final tag in trail.displayTags) TagChip(tagKey: tag),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.stack),
        GelaufenAction(trailId: trail.id),
        const SizedBox(height: AppSpacing.section),
        Text(trail.beschreibung, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.section),
        Text('Stationen', style: headingStyle),
        const SizedBox(height: AppSpacing.afterHeading),
        if (trail.isLinie) ...[
          TrailTrackView(trail: trail),
          const SizedBox(height: AppSpacing.afterHeading),
        ],
        SheetAccordionSection(
          title: 'Stationen',
          subtitle: '${trail.stationen.length} Stationen',
          children: [
            StationCarousel(
              stations: trail.stationen,
              onTap: (station) =>
                  StationDetailSheet.show(context, trail, station),
            ),
          ],
        ),
        if (hasArten)
          SheetAccordionSection(
            title: 'Artenvielfalt',
            children: [
              ArtenSection(
                trailId: trail.id,
                showTitle: false,
                kategorien: const {'flora', 'fauna'},
              ),
            ],
          ),
        if (hasGeraete)
          SheetAccordionSection(
            title: 'Geräte',
            children: [
              ArtenSection(
                trailId: trail.id,
                showTitle: false,
                showCategoryHeaders: false,
                kategorien: const {'geraete'},
              ),
            ],
          ),
        AnreiseSection(trail: trail),
        if (hasNearby)
          SheetAccordionSection(
            title: 'In der Nähe',
            subtitle: '${nearby.length} Orte',
            children: [NearbySection(trailId: trail.id)],
          ),
        if (SupabaseConfig.isConfigured)
          SheetAccordionSection(
            title: 'Bewertungen & Kommentare',
            children: [
              RatingSection(trailId: trail.id),
              const SizedBox(height: AppSpacing.stack),
              CommentsSection(trailId: trail.id),
            ],
          ),
      ],
    );
  }
}
