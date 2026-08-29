import 'package:flutter/material.dart';

import '../catalogs/icon_catalog.dart';
import 'catalog_chip.dart';

/// Kompakte Icon-plus-Label-Darstellung eines Ausstattungs-Tags
/// (redaktionell oder aus Amenities abgeleitet). Wird im Trail-Sheet genutzt.
class TagChip extends StatelessWidget {
  final String tagKey;
  final double iconSize;

  const TagChip({super.key, required this.tagKey, this.iconSize = 16});

  @override
  Widget build(BuildContext context) {
    return CatalogChip(eintrag: tagEintrag(tagKey), iconSize: iconSize);
  }
}
