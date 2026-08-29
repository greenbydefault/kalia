import 'package:flutter/material.dart';

import '../catalogs/icon_catalog.dart';
import 'catalog_chip.dart';

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
    return CatalogChip(
      eintrag: erlebnisEintrag(erlebnisKey),
      iconSize: iconSize,
    );
  }
}
