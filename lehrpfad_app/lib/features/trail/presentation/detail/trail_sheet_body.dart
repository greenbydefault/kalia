import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../shared/widgets/tag_chip.dart';
import '../../../community/presentation/add_photo_button.dart';
import '../../../community/presentation/comments_section.dart';
import '../../../community/presentation/rating_section.dart';
import '../../../community/presentation/trail_image_carousel.dart';
import '../../../species/data/species_providers.dart';
import '../../../species/presentation/arten_section.dart';
import '../../../trail_progress/presentation/gelaufen_action.dart';
import '../../domain/trail.dart';
import '../../track_engine/trail_track_view.dart';
import 'navigation_sheet.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (SupabaseConfig.isConfigured) ...[
          TrailImageCarousel(trailId: trail.id),
          const SizedBox(height: AppSpacing.x2),
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
              FactChip(icon: Icons.route, label: '${trail.laengeKm} km'),
            FactChip(icon: Icons.schedule, label: '~${trail.dauerMin} Min'),
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
        SheetAccordionSection(
          title: 'Anreise & Infos',
          children: [
            if (trail.oeffnungszeiten != null &&
                trail.oeffnungszeiten!.isNotEmpty) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const PhosphorIcon(PhosphorIcons.clock, size: 22),
                title: const Text('Öffnungszeiten'),
                subtitle: Text(trail.oeffnungszeiten!),
              ),
              const SizedBox(height: AppSpacing.x2),
            ],
            if (trail.eintrittPreise != null &&
                trail.eintrittPreise!.isNotEmpty) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: PhosphorIcon(
                  trail.eintritt
                      ? PhosphorIcons.ticket
                      : PhosphorIcons.currencyEur,
                  size: 22,
                ),
                title: Text(trail.eintritt ? 'Eintritt' : 'Preise'),
                subtitle: Text(trail.eintrittPreise!),
              ),
              const SizedBox(height: AppSpacing.x2),
            ],
            if (trail.besuchshinweise != null &&
                trail.besuchshinweise!.isNotEmpty) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const PhosphorIcon(PhosphorIcons.info, size: 22),
                title: const Text('Vor dem Besuch'),
                subtitle: Text(trail.besuchshinweise!),
              ),
              const SizedBox(height: AppSpacing.x2),
            ],
            if (trail.website != null && trail.website!.isNotEmpty) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const PhosphorIcon(PhosphorIcons.globe, size: 22),
                title: const Text('Website'),
                onTap: () => _openWebsite(trail.website!),
              ),
              const SizedBox(height: AppSpacing.x2),
            ],
            Text(trail.anreise, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.x3),
            if (trail.startOrNull != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: () => NavigationSheet.show(context, trail),
                  icon: const PhosphorIcon(
                    PhosphorIcons.navigationArrow,
                    size: 18,
                  ),
                  label: const Text('Navigation starten'),
                ),
              ),
              const SizedBox(height: AppSpacing.x3),
            ],
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.account_balance_outlined),
              title: Text(trail.betreiber),
              subtitle: Text('Start: ${trail.startName}'),
            ),
          ],
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

Future<void> _openWebsite(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
