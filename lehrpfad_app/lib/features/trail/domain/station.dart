import 'package:latlong2/latlong.dart';

import 'steckbrief.dart';

/// Eine Station entlang eines Lehrpfads.
class Station {
  /// Datenbank-ID (nur im Supabase-Modus belegt, im Seed-Modus null).
  /// Wird fuer stationsbezogene Inhalte (z. B. Bilder) benoetigt.
  final int? id;
  final int osmId;
  final LatLng position;
  final double km;
  final int reihenfolge;
  final String titel;
  final String thema;
  final String kurztext;
  final List<String> erlebnisse;
  final bool barrierefrei;
  final Steckbrief? steckbrief;

  const Station({
    this.id,
    required this.osmId,
    required this.position,
    required this.km,
    required this.reihenfolge,
    required this.titel,
    required this.thema,
    required this.kurztext,
    required this.erlebnisse,
    required this.barrierefrei,
    this.steckbrief,
  });

  factory Station.fromJson(Map<String, dynamic> json) => Station(
    id: json['id'] as int?,
    osmId: json['osmId'] as int,
    position: LatLng(
      (json['lat'] as num).toDouble(),
      (json['lon'] as num).toDouble(),
    ),
    km: (json['km'] as num).toDouble(),
    reihenfolge: json['reihenfolge'] as int,
    titel: json['titel'] as String,
    thema: json['thema'] as String,
    kurztext: json['kurztext'] as String,
    erlebnisse: (json['erlebnisse'] as List).cast<String>(),
    barrierefrei: json['barrierefrei'] as bool? ?? false,
    steckbrief: json['steckbrief'] == null
        ? null
        : Steckbrief.fromJson(json['steckbrief'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'osmId': osmId,
    'lat': position.latitude,
    'lon': position.longitude,
    'km': km,
    'reihenfolge': reihenfolge,
    'titel': titel,
    'thema': thema,
    'kurztext': kurztext,
    'erlebnisse': erlebnisse,
    'barrierefrei': barrierefrei,
    'steckbrief': steckbrief?.toJson(),
  };
}
