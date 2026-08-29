import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/catalogs/icon_catalog.dart';
import '../../../shared/widgets/show_app_modal_sheet.dart';
import '../data/species_providers.dart';
import '../domain/merkmal.dart';
import '../domain/species.dart';
import '../domain/species_beziehung.dart';
import 'species_section_title.dart';

part 'profil/stat_cards.dart';
part 'profil/merkmale_grid.dart';
part 'profil/beziehung_card.dart';
part 'profil/masse_grid.dart';
part 'profil/taxonomie_pills.dart';
part 'profil/merkmal_sheet.dart';

/// Profil-Blöcke für Flora/Fauna. Geräte zeigen nichts davon.
class SpeciesProfilView extends ConsumerWidget {
  const SpeciesProfilView({super.key, required this.species});

  final Species species;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!species.hasProfil) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final merkmaleAsync = ref.watch(merkmaleByIdProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatCards(species: species),
        const SizedBox(height: 20),
        if (species.merkmalIds.isNotEmpty) ...[
          const SpeciesSectionTitle(title: 'Merkmale'),
          const SizedBox(height: 8),
          merkmaleAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const SizedBox.shrink(),
            data: (byId) => _MerkmaleGrid(
              species: species,
              merkmale: species.merkmalIds
                  .map((id) => byId[id])
                  .whereType<Merkmal>()
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (species.nahrung.isNotEmpty) ...[
          const SpeciesSectionTitle(title: 'Nahrung'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final n in species.nahrung)
                Chip(
                  label: Text(n, style: theme.textTheme.bodySmall),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: AppColors.n100,
                  side: BorderSide.none,
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (species.beziehungen.isNotEmpty) ...[
          const SpeciesSectionTitle(title: 'Ökologische Zusammenhänge'),
          const SizedBox(height: 8),
          ...species.beziehungen.map(
            (b) => _BeziehungCard(species: species, beziehung: b),
          ),
          const SizedBox(height: 16),
        ],
        if (species.masse.isNotEmpty) ...[
          const SpeciesSectionTitle(title: 'Maße und Details'),
          const SizedBox(height: 8),
          _MasseGrid(species: species),
          const SizedBox(height: 16),
        ],
        if (species.taxonomie.isNotEmpty) ...[
          const SpeciesSectionTitle(title: 'Taxonomie'),
          const SizedBox(height: 8),
          _TaxonomiePills(taxonomie: species.taxonomie),
        ],
      ],
    );
  }
}
