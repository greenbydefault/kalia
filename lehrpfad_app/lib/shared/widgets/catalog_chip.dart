import 'package:flutter/material.dart';

import '../catalogs/icon_catalog.dart';

/// Icon-plus-Label für einen [KatalogEintrag].
class CatalogChip extends StatelessWidget {
  const CatalogChip({super.key, required this.eintrag, this.iconSize = 16});

  final KatalogEintrag eintrag;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        eintrag.buildIcon(size: iconSize, color: theme.colorScheme.primary),
        const SizedBox(width: 4),
        Text(eintrag.label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
