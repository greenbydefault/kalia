import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../shared/widgets/tag_chip.dart';
import '../../../community/presentation/add_photo_button.dart';
import '../../../community/presentation/comments_section.dart';
import '../../../community/presentation/rating_section.dart';
import '../../../nearby/data/nearby_providers.dart';
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
          Align(
            alignment: Alignment.centerLeft,
            child: AddPhotoButton(trail: trail),
          ),
          const SizedBox(height: AppSpacing.x2),
        ],
        Wrap(
          spacing: AppSpacing.x2,
          runSpacing: AppSpacing.x2,
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
        const SizedBox(height: AppSpacing.x3),
        EignungSection(trail: trail),
        if (trail.displayTags.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.x3),
          Wrap(
            spacing: AppSpacing.x3,
            runSpacing: AppSpacing.x2,
            children: [
              for (final tag in trail.displayTags) TagChip(tagKey: tag),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.x4),
        GelaufenAction(trailId: trail.id),
        const SizedBox(height: AppSpacing.x5),
        Text(trail.beschreibung, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.x5),
        Text('Stationen', style: headingStyle),
        const SizedBox(height: AppSpacing.x2),
        if (trail.isLinie) ...[
          TrailTrackView(trail: trail),
          const SizedBox(height: AppSpacing.x1),
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
              const SizedBox(height: AppSpacing.x4),
              CommentsSection(trailId: trail.id),
            ],
          ),
      ],
    );
  }
}
