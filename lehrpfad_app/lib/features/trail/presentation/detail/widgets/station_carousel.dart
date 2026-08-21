import 'package:flutter/material.dart';

import '../../../../../shared/widgets/content_carousel.dart';
import '../../../../../shared/widgets/content_carousel_style.dart';
import '../../../domain/station.dart';
import 'station_tile.dart';

/// Peek-Slider für Stationen — gleiches Chrome wie Arten/Geräte.
class StationCarousel extends StatelessWidget {
  const StationCarousel({
    super.key,
    required this.stations,
    required this.onTap,
  });

  final List<Station> stations;
  final ValueChanged<Station> onTap;

  @override
  Widget build(BuildContext context) {
    return ContentCarousel<Station>(
      items: stations,
      layout: ContentCarouselLayout.peek,
      itemBuilder: (station) => StationTile(
        station: station,
        onTap: () => onTap(station),
      ),
    );
  }
}
