import 'package:latlong2/latlong.dart';

/// Vom Nutzer gewählter Startort (Ersatz für den Gerätestandort).
class UserPlace {
  const UserPlace({
    required this.name,
    required this.plz,
    required this.lat,
    required this.lon,
  });

  final String name;
  final String plz;
  final double lat;
  final double lon;

  LatLng get position => LatLng(lat, lon);

  /// „Leipzig“ bzw. „Leipzig (04109)“ für Listen.
  String get label => plz.isEmpty ? name : '$name ($plz)';

  Map<String, Object?> toJson() => {
    'name': name,
    'plz': plz,
    'lat': lat,
    'lon': lon,
  };

  factory UserPlace.fromJson(Map<String, dynamic> json) => UserPlace(
    name: json['name'] as String? ?? '',
    plz: json['plz'] as String? ?? '',
    lat: (json['lat'] as num).toDouble(),
    lon: (json['lon'] as num).toDouble(),
  );

  @override
  bool operator ==(Object other) =>
      other is UserPlace &&
      other.name == name &&
      other.plz == plz &&
      other.lat == lat &&
      other.lon == lon;

  @override
  int get hashCode => Object.hash(name, plz, lat, lon);
}
