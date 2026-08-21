import 'package:flutter/material.dart';

import '../../../shared/widgets/content_carousel.dart';
import '../../../shared/widgets/content_carousel_style.dart';
import '../domain/species.dart';
import 'species_tile.dart';

/// Horizontaler Peek-/Compact-Slider für Arten und Geräte.
class SpeciesCarousel extends StatelessWidget {
  const SpeciesCarousel({
    super.key,
    required this.species,
    required this.seenIds,
    required this.onTap,
    this.layout = ContentCarouselLayout.peek,
  });

  final List<Species> species;
  final Set<String> seenIds;
  final ValueChanged<Species> onTap;
  final ContentCarouselLayout layout;

  SpeciesTileLayout get _tileLayout => switch (layout) {
        ContentCarouselLayout.peek => SpeciesTileLayout.peek,
        ContentCarouselLayout.compact3 => SpeciesTileLayout.compact,
      };

  @override
  Widget build(BuildContext context) {
    return ContentCarousel<Species>(
      items: species,
      layout: layout,
      itemBuilder: (s) => SpeciesTile(
        species: s,
        seen: seenIds.contains(s.id),
        onTap: () => onTap(s),
        layout: _tileLayout,
      ),
    );
  }
}
