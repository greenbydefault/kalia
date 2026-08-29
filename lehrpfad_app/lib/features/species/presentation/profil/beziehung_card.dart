part of '../species_profil_view.dart';

class _BeziehungCard extends ConsumerWidget {
  const _BeziehungCard({required this.species, required this.beziehung});

  final Species species;
  final SpeciesBeziehung beziehung;

  static const _typLabels = {
    'frisst': 'Frisst',
    'bestaeubt': 'Bestäubt',
    'wohnt_an': 'Findet Schutz bei',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final catalogAsync = ref.watch(speciesCatalogProvider);

    final targetName = beziehung.isKatalogArt
        ? catalogAsync.asData?.value
                .where((s) => s.id == beziehung.toSpeciesId)
                .firstOrNull
                ?.nameDe ??
            beziehung.nameDe
        : beziehung.nameDe;

    final targetLat = beziehung.isKatalogArt
        ? catalogAsync.asData?.value
                .where((s) => s.id == beziehung.toSpeciesId)
                .firstOrNull
                ?.nameLat ??
            beziehung.nameLat
        : beziehung.nameLat;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.n100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.n200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _typLabels[beziehung.typ] ?? beziehung.typ,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            targetName,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (targetLat.isNotEmpty)
            Text(
              targetLat,
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.inkMuted,
              ),
            ),
          if (beziehung.kurztext.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(beziehung.kurztext, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
