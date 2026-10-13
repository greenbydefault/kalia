import 'package:latlong2/latlong.dart';

import '../../location/map_radius.dart';
import '../presentation/map/map_typ_filter.dart';
import 'eignung_score.dart';
import 'trail.dart';

/// „Kurze Wege“, wenn im Onboarding niemand gewählt wurde.
const defaultShortKm = 5;

/// Kinderwagen-Näherung aus Tags und Barrierefreiheit (kein eigenes Feld).
bool isStrollerFriendly(Trail t) {
  final tags = t.alleTags;
  if (tags.contains('kinderwagentauglich') ||
      tags.contains('rollstuhltauglich')) {
    return true;
  }
  return scoreEignungen(t).barriere.level >= 4;
}

/// Der eine Katalogfilter für Karte und „Nächste Wege“:
/// Typ × Umkreis × Länge × Kinderwagen.
///
/// - [typ] `null`: alle Typen.
/// - [radius] gilt nur mit [anchor]; ohne Anker bleibt alles.
/// - [lengthOn]: Flächen oder `laengeKm <= maxKm` (sonst [defaultShortKm]).
/// - [strollerOn]: nur [isStrollerFriendly].
List<Trail> filterCatalog(
  List<Trail> trails, {
  String? typ,
  MapRadius radius = MapRadius.all,
  LatLng? anchor,
  int? maxKm,
  bool lengthOn = false,
  bool strollerOn = false,
}) {
  final cap = maxKm ?? defaultShortKm;
  final byTypAndRadius = filterTrailsByRadius(
    filterTrailsByTyp(trails, typ) ?? const [],
    radius: radius,
    user: anchor,
  );
  return [
    for (final t in byTypAndRadius)
      if ((!lengthOn || t.isFlaeche || t.laengeKm <= cap) &&
          (!strollerOn || isStrollerFriendly(t)))
        t,
  ];
}
