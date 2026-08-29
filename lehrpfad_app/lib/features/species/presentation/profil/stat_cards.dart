part of '../species_profil_view.dart';

class _StatCards extends StatelessWidget {
  const _StatCards({required this.species});

  final Species species;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            theme: theme,
            icon: gruppeEintrag(species.gruppe).icon,
            label: 'Kategorie',
            value: gruppeEintrag(species.gruppe).label,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            theme: theme,
            icon: seltenheitEintrag(species.seltenheit).icon,
            label: 'Seltenheit',
            value: seltenheitEintrag(species.seltenheit).label,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            theme: theme,
            icon: PhosphorIcons.warning,
            label: 'Gefahr',
            value: '${species.gefahr}/5 · ${gefahrLabels[species.gefahr] ?? ''}',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.theme,
    required this.icon,
    required this.label,
    required this.value,
  });

  final ThemeData theme;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.n100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PhosphorIcon(icon, size: 20, color: AppColors.inkMuted),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.inkMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
