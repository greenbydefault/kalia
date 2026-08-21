import 'package:flutter/material.dart';

import '../catalogs/icon_catalog.dart';

/// Kompakte Icon-plus-Label-Darstellung eines Erlebnisses.
/// Wird in der Stationskarte und im Karten-Overlay genutzt.
class ErlebnisChip extends StatelessWidget {
  final String erlebnisKey;
  final double iconSize;

  const ErlebnisChip({
    super.key,
    required this.erlebnisKey,
    this.iconSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eintrag = erlebnisEintrag(erlebnisKey);
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
