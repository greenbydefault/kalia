import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/catalogs/icon_catalog.dart';
import '../../../shared/widgets/content_carousel_style.dart';
import '../data/species_providers.dart';
import '../domain/species.dart';
import 'species_carousel.dart';
import 'species_category_header.dart';
import 'species_detail_sheet.dart';

/// Arten-/Geräte-Block (optional gefiltert nach [kategorien]).
class ArtenSection extends ConsumerWidget {
  const ArtenSection({
    super.key,
    required this.trailId,
    this.showTitle = true,
    this.title = 'Entdecken',
    this.kategorien,
    this.showCategoryHeaders = true,
  });

  final String trailId;
  final bool showTitle;
  final String title;

  /// Wenn gesetzt, nur diese Kategorien (z. B. `{flora, fauna}` oder `{geraete}`).
  final Set<String>? kategorien;
  final bool showCategoryHeaders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final headingStyle = theme.textTheme.titleMedium;
    final speciesAsync = ref.watch(trailSpeciesProvider(trailId));
    final seenIds = ref.watch(sightingsProvider).asData?.value ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Text(title, style: headingStyle),
          const SizedBox(height: 8),
        ],
        speciesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator.adaptive()),
          ),
          error: (e, _) => Text(
            'Inhalte konnten nicht geladen werden.',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.error),
          ),
          data: (species) {
            final filtered = kategorien == null
                ? species
                : species
                      .where((s) => kategorien!.contains(s.kategorie))
                      .toList();
            if (filtered.isEmpty) {
              return Text(
                'Noch nichts hinterlegt.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkMuted,
                ),
              );
            }

            final flora = filtered.where((s) => s.isFlora).toList();
            final fauna = filtered.where((s) => s.isFauna).toList();
            final geraete = filtered.where((s) => s.isGeraet).toList();

            final sections = <Widget>[];
            void addSection(List<Species> items) {
              if (items.isEmpty) return;
              if (sections.isNotEmpty) {
                sections.add(const SizedBox(height: 16));
              }
              if (showCategoryHeaders) {
                final kat = speciesKategorieEintrag(items.first.kategorie);
                sections.add(
                  SpeciesCategoryHeader(
                    label: kat.label,
                    count: items.length,
                    icon: kat.icon,
                    isGeraete: items.first.isGeraet,
                  ),
                );
                sections.add(const SizedBox(height: 8));
              }
              sections.add(
                SpeciesCarousel(
                  species: items,
                  seenIds: seenIds,
                  layout: items.first.isGeraet
                      ? ContentCarouselLayout.compact3
                      : ContentCarouselLayout.peek,
                  onTap: (s) => SpeciesDetailSheet.show(context, s),
                ),
              );
            }

            addSection(flora);
            addSection(fauna);
            addSection(geraete);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sections,
            );
          },
        ),
      ],
    );
  }
}
