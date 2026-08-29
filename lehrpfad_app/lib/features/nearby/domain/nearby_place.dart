import 'package:latlong2/latlong.dart';

import '../../../shared/catalogs/icon_catalog.dart';

/// Kuratierter Ort im Umfeld eines Trails (Café, Camping, …).
class NearbyPlace {
  final String id;
  final String name;
  final String kategorie;
  final String kurztext;
  final LatLng position;
  final String? website;
  final String? oeffnungszeiten;
  final String? openingHours;
  final String? telefon;

  const NearbyPlace({
    required this.id,
    required this.name,
    required this.kategorie,
    required this.kurztext,
    required this.position,
    this.website,
    this.oeffnungszeiten,
    this.openingHours,
    this.telefon,
  });

  String get kategorieLabel => poiKategorieEintrag(kategorie).label;

  factory NearbyPlace.fromJson(Map<String, dynamic> json) => NearbyPlace(
    id: json['id'] as String,
    name: json['name'] as String,
    kategorie: json['kategorie'] as String,
    kurztext: json['kurztext'] as String? ?? '',
    position: LatLng(
      (json['lat'] as num).toDouble(),
      (json['lon'] as num).toDouble(),
    ),
    website: json['website'] as String?,
    oeffnungszeiten: json['oeffnungszeiten'] as String?,
    openingHours: json['opening_hours'] as String?,
    telefon: json['telefon'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'kategorie': kategorie,
    'kurztext': kurztext,
    'lat': position.latitude,
    'lon': position.longitude,
    'website': website,
    'oeffnungszeiten': oeffnungszeiten,
    if (openingHours != null) 'opening_hours': openingHours,
    'telefon': telefon,
  };
}
