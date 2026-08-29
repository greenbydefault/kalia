part of '../species_profil_view.dart';

class _TaxonomiePills extends StatelessWidget {
  const _TaxonomiePills({required this.taxonomie});

  final Map<String, String> taxonomie;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: taxonomieRanks.entries
          .where((e) => taxonomie[e.key]?.isNotEmpty ?? false)
          .map(
            (e) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.n100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.hairline),
              ),
              child: Text(
                '${e.value}: ${taxonomie[e.key]}',
                style: theme.textTheme.bodySmall,
              ),
            ),
          )
          .toList(),
    );
  }
}
