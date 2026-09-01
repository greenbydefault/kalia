import 'package:flutter/material.dart';

import '../../../shared/widgets/content_carousel.dart';
import '../../../shared/widgets/content_carousel_style.dart';
import '../domain/nearby.dart';
import 'nearby_tile.dart';

/// Peek-Slider für Orte in der Nähe — gleiches Chrome wie Stationen/Arten.
class NearbyCarousel extends StatelessWidget {
  const NearbyCarousel({super.key, required this.treffer, required this.onTap});

  final List<NearbyTreffer> treffer;
  final ValueChanged<NearbyTreffer> onTap;

  @override
  Widget build(BuildContext context) {
    return ContentCarousel<NearbyTreffer>(
      items: treffer,
      layout: ContentCarouselLayout.peek,
      itemBuilder: (t) => NearbyTile(treffer: t, onTap: () => onTap(t)),
    );
  }
}
