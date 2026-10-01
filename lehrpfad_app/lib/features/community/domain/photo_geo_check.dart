import 'package:latlong2/latlong.dart';

import '../../location/proximity.dart';
import '../../trail/domain/trail.dart';

/// Bis zu dieser Distanz zum Trail gilt ein Foto-Ort als "grob in der
/// Gegend" (GPS-Drift, Zoom-Fotos von Weitem, Parkplatz am Eingang).
const photoGeoNearRadiusM = 2000.0;

/// Vorpruefung fuer die Moderation: passt der GPS-Ort aus dem Foto zum
/// gewaehlten Trail? Nur ein Hinweis, nie eine Freigabe. Die Koordinaten
/// selbst werden nicht gespeichert, nur dieser Wert (siehe [dbValue]).
enum PhotoGeoCheck {
  /// GPS liegt am Trail (Route/Flaeche plus Puffer).
  match('match'),

  /// GPS da, aber nur grob in der Gegend.
  near('near'),

  /// GPS liegt klar woanders.
  far('far'),

  /// Kein GPS im Foto oder Trail ohne Geometrie.
  none('none');

  const PhotoGeoCheck(this.dbValue);
  final String dbValue;

  /// `null` (Altbestand ohne Pruefung) bleibt `null`; unbekannte Werte
  /// fallen auf [none].
  static PhotoGeoCheck? parse(String? value) {
    if (value == null) return null;
    for (final c in values) {
      if (c.dbValue == value) return c;
    }
    return none;
  }

  /// Bewertet [photoPosition] gegen die Geometrie von [trail].
  /// [photoPosition] ist fluechtig und wird nicht weitergegeben.
  static PhotoGeoCheck evaluate(Trail trail, LatLng? photoPosition) {
    if (photoPosition == null) return none;
    final d = distanceToTrailM(trail, photoPosition);
    if (d == null) return none;
    if (d <= onSiteRadiusM(trail)) return match;
    if (d <= photoGeoNearRadiusM) return near;
    return far;
  }
}
