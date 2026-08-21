import 'package:flutter/material.dart';

import '../catalogs/icon_catalog.dart';

/// Kompakte Icon-plus-Label-Darstellung eines Ausstattungs-Tags
/// (redaktionell oder aus Amenities abgeleitet). Wird im Trail-Sheet genutzt.
class TagChip extends StatelessWidget {
  final String tagKey;
  final double iconSize;

  const TagChip({super.key, required this.tagKey, this.iconSize = 16});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eintrag = tagEintrag(tagKey);
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
