import 'package:latlong2/latlong.dart';

/// Infrastruktur-Punkt entlang der Route (WC, Bank, Parkplatz, ...).
class Amenity {
  final int osmId;
  final LatLng position;
  final String kategorie;
  final String? name;

  const Amenity({
    required this.osmId,
    required this.position,
    required this.kategorie,
    this.name,
  });

  factory Amenity.fromJson(Map<String, dynamic> json) => Amenity(
    osmId: json['osmId'] as int,
    position: LatLng(
      (json['lat'] as num).toDouble(),
      (json['lon'] as num).toDouble(),
    ),
    kategorie: json['kategorie'] as String,
    name: json['name'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'osmId': osmId,
    'lat': position.latitude,
    'lon': position.longitude,
    'kategorie': kategorie,
    'name': name,
  };
}
