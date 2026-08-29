part of '../species_profil_view.dart';

class _MerkmaleGrid extends StatelessWidget {
  const _MerkmaleGrid({required this.species, required this.merkmale});

  final Species species;
  final List<Merkmal> merkmale;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: merkmale
          .map((m) => _MerkmalCard(species: species, merkmal: m))
          .toList(),
    );
  }
}

class _MerkmalCard extends StatelessWidget {
  const _MerkmalCard({required this.species, required this.merkmal});

  final Species species;
  final Merkmal merkmal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _MerkmalSheet.show(context, merkmal),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.n100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            PhosphorIcon(
              merkmal.iconEintrag.icon,
              size: 24,
              color: AppColors.ink,
            ),
            const SizedBox(height: 6),
            Text(
              merkmal.nameDe,
              style: theme.textTheme.labelSmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
