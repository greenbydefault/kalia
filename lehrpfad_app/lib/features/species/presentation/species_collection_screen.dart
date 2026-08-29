import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/catalogs/icon_catalog.dart';
import '../data/species_providers.dart';
import '../domain/species.dart';
import 'species_category_header.dart';
import 'species_detail_sheet.dart';
import 'species_glyph.dart';

/// App-weite Sammlung: 3er-Grid, ungesehen gedimmt + Schloss.
class SpeciesCollectionScreen extends ConsumerWidget {
  const SpeciesCollectionScreen({super.key});

  static const _lockedOpacity = 0.35;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final catalogAsync = ref.watch(speciesCatalogProvider);
    final seenIds = ref.watch(sightingsProvider).asData?.value ?? {};

    return Scaffold(
      appBar: AppBar(title: const Text('Sammlung')),
      body: catalogAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Sammlung konnte nicht geladen werden.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (catalog) {
          if (catalog.isEmpty) {
            return Center(
              child: Text(
                'Noch nichts hinterlegt.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkMuted,
                ),
              ),
            );
          }

          final flora = catalog.where((s) => s.isFlora).toList();
          final fauna = catalog.where((s) => s.isFauna).toList();
          final geraete = catalog.where((s) => s.isGeraet).toList();
          final seenCount = catalog.where((s) => seenIds.contains(s.id)).length;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Text(
                    '$seenCount / ${catalog.length} gesehen',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                ),
              ),
              ..._categorySlivers(flora, seenIds, topPad: false),
              ..._categorySlivers(fauna, seenIds, topPad: flora.isNotEmpty),
              ..._categorySlivers(
                geraete,
                seenIds,
                topPad: flora.isNotEmpty || fauna.isNotEmpty,
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }

  static List<Widget> _categorySlivers(
    List<Species> items,
    Set<String> seenIds, {
    required bool topPad,
  }) {
    if (items.isEmpty) return const [];
    final kat = speciesKategorieEintrag(items.first.kategorie);
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: topPad ? 8 : 0),
          child: SpeciesCategoryHeader(
            label: kat.label,
            count: items.length,
            icon: kat.icon,
            isGeraete: items.first.isGeraet,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          ),
        ),
      ),
      _SpeciesGrid(species: items, seenIds: seenIds),
    ];
  }
}

class _SpeciesGrid extends StatelessWidget {
  const _SpeciesGrid({required this.species, required this.seenIds});

  final List<Species> species;
  final Set<String> seenIds;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.85,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final s = species[index];
          final seen = seenIds.contains(s.id);
          return _CollectionTile(
            species: s,
            seen: seen,
            onTap: () {
              if (seen) {
                SpeciesDetailSheet.show(context, s);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      s.isGeraet
                          ? 'Am Ort freischalten'
                          : 'Am Lehrpfad freischalten',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          );
        }, childCount: species.length),
      ),
    );
  }
}

class _CollectionTile extends StatelessWidget {
  const _CollectionTile({
    required this.species,
    required this.seen,
    required this.onTap,
  });

  final Species species;
  final bool seen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.n100,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Opacity(
          opacity: seen ? 1 : SpeciesCollectionScreen._lockedOpacity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: SpeciesGlyph(
              species: species,
              seen: seen,
              iconSize: 32,
              showLock: true,
            ),
          ),
        ),
      ),
    );
  }
}
