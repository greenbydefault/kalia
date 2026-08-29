part of '../species_profil_view.dart';

/// Mini-Sheet zu einem Merkmal: Beschreibung + andere Arten mit dem Badge.
class _MerkmalSheet extends ConsumerWidget {
  const _MerkmalSheet({required this.merkmal});

  final Merkmal merkmal;

  static Future<void> show(BuildContext context, Merkmal merkmal) {
    return showAppModalSheet<void>(
      context: context,
      builder: (_) => _MerkmalSheet(merkmal: merkmal),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final catalogAsync = ref.watch(speciesCatalogProvider);

    final andere =
        catalogAsync.asData?.value
            .where(
              (s) =>
                  s.hasProfil &&
                  s.merkmalIds.contains(merkmal.id) &&
                  s.id != merkmal.id,
            )
            .toList() ??
        [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            PhosphorIcon(
              merkmal.iconEintrag.icon,
              size: 32,
              color: AppColors.ink,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                merkmal.nameDe,
                style: theme.textTheme.headlineSmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(merkmal.beschreibung, style: theme.textTheme.bodyMedium),
        if (andere.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Auch bei:', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ...andere.take(5).map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('· ${s.nameDe}', style: theme.textTheme.bodyMedium),
            ),
          ),
        ],
      ],
    );
  }
}
