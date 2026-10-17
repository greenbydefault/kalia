import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../trail/domain/haversine.dart';
import '../domain/user_place.dart';

const placesAsset = 'assets/seed/orte_de.json';

String _fold(String s) => s
    .toLowerCase()
    .replaceAll('ä', 'ae')
    .replaceAll('ö', 'oe')
    .replaceAll('ü', 'ue')
    .replaceAll('ß', 'ss');

/// Offline-Ortssuche (Name oder PLZ-Anfang) über die gebündelte Liste.
class PlaceIndex {
  PlaceIndex(this.places) : _names = [for (final p in places) _fold(p.name)];

  factory PlaceIndex.fromJson(String raw) {
    final rows = jsonDecode(raw) as List;
    return PlaceIndex([
      for (final r in rows)
        UserPlace(
          name: (r as List)[0] as String,
          plz: r[1] as String,
          lat: (r[2] as num).toDouble(),
          lon: (r[3] as num).toDouble(),
        ),
    ]);
  }

  final List<UserPlace> places;
  final List<String> _names;

  /// Mindestlänge, ab der „Pfade anzeigen“ auch ohne Auswahl aktiv ist.
  static const minChars = 3;

  /// Nächster Ort zur Koordinate (Reverse-Geocoding gegen die gebündelte
  /// Liste). `null`, wenn keiner innerhalb von [maxKm] liegt.
  UserPlace? nearest(LatLng point, {double maxKm = 20}) {
    UserPlace? best;
    var bestM = maxKm * 1000;
    for (final p in places) {
      // Grobe Vorauswahl, spart die Haversine-Formel für den Großteil.
      if ((p.lat - point.latitude).abs() > 0.5) continue;
      final d = haversineMeters(point, p.position);
      if (d < bestM) {
        bestM = d;
        best = p;
      }
    }
    return best;
  }

  List<UserPlace> search(String query, {int limit = 4}) {
    final q = _fold(query.trim());
    if (q.isEmpty) return const [];

    if (RegExp(r'^\d').hasMatch(q)) {
      return [
        for (final p in places)
          if (p.plz.startsWith(q)) p,
      ].take(limit).toList();
    }

    final hits = <(int, int, UserPlace)>[];
    for (var i = 0; i < places.length; i++) {
      final n = _names[i];
      final rank = n == q
          ? 0
          : n.startsWith(q)
          ? 1
          : n.contains(q)
          ? 2
          : -1;
      if (rank >= 0) hits.add((rank, n.length, places[i]));
    }
    hits.sort((a, b) {
      final r = a.$1.compareTo(b.$1);
      if (r != 0) return r;
      final l = a.$2.compareTo(b.$2);
      return l != 0 ? l : a.$3.plz.compareTo(b.$3.plz);
    });

    final seen = <String>{};
    final out = <UserPlace>[];
    for (final h in hits) {
      if (!seen.add(h.$3.name)) continue; // ein Treffer pro Ortsname
      out.add(h.$3);
      if (out.length >= limit) break;
    }
    return out;
  }
}

final placeIndexProvider = FutureProvider<PlaceIndex>((ref) async {
  return PlaceIndex.fromJson(await rootBundle.loadString(placesAsset));
});
