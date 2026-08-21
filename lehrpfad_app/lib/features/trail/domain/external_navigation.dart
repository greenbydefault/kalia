import 'package:latlong2/latlong.dart';

import 'amenity.dart';
import 'trail.dart';

/// Ziel für externe Navigation (Parkplatz oder Trail-Start).
class AnreiseDestination {
  final LatLng position;
  final String label;
  final bool isParking;

  const AnreiseDestination({
    required this.position,
    required this.label,
    required this.isParking,
  });
}

enum MapProvider { googleMaps, appleMaps, openStreetMap }

const _distance = Distance();

/// Nächster Parkplatz zu [Trail.start], sonst der Startpunkt.
///
/// `null` wenn der Trail keine Geometrie hat.
AnreiseDestination? navigationDestinationFor(Trail trail) {
  final start = trail.startOrNull;
  if (start == null) return null;

  Amenity? nearest;
  var nearestM = double.infinity;
  for (final amenity in trail.amenities) {
    if (amenity.kategorie != 'parking') continue;
    final meters = _distance.as(
      LengthUnit.Meter,
      start,
      amenity.position,
    );
    if (meters < nearestM) {
      nearestM = meters;
      nearest = amenity;
    }
  }

  if (nearest != null) {
    final name = nearest.name?.trim();
    return AnreiseDestination(
      position: nearest.position,
      label: (name != null && name.isNotEmpty) ? name : trail.startName,
      isParking: true,
    );
  }

  return AnreiseDestination(
    position: start,
    label: trail.startName,
    isParking: false,
  );
}

/// `startName, Region` — für die Zwischenablage.
String copyAddressLabel(Trail trail) {
  return [
    trail.startName,
    trail.region,
  ].map((s) => s.trim()).where((s) => s.isNotEmpty).join(', ');
}

String formatLatLng(LatLng point) {
  return '${point.latitude.toStringAsFixed(5)}, '
      '${point.longitude.toStringAsFixed(5)}';
}

/// Directions-URL ohne `origin` — die Karten-App setzt den Standort.
Uri directionsUri(MapProvider provider, LatLng destination) {
  final dest = '${destination.latitude},${destination.longitude}';
  switch (provider) {
    case MapProvider.googleMaps:
      return Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'destination': dest,
        'travelmode': 'driving',
      });
    case MapProvider.appleMaps:
      return Uri.https('maps.apple.com', '/', {
        'daddr': dest,
        'dirflg': 'd',
      });
    case MapProvider.openStreetMap:
      return Uri.https('www.openstreetmap.org', '/directions', {
        'engine': 'fossgis_osrm_car',
        'route': ';$dest',
      });
  }
}
