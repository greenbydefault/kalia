import 'package:flutter_map/flutter_map.dart';

import '../../domain/trail.dart';
import 'trail_area_style.dart';
import 'trail_polyline_style.dart';

/// Flächen-Polygone aller Flächen-Trails. Der ausgewählte Trail wird
/// mit [trackOpacity] eingefaded, der Rest liegt konstant darunter.
List<Polygon> buildAreaPolygons({
  required List<Trail> flaechen,
  required Trail? selectedFlaeche,
  required double trackOpacity,
}) {
  return [
    for (final trail in flaechen)
      if (trail.area.length >= 3)
        Polygon(
          points: trail.area,
          color: TrailAreaStyle.fill.withValues(
            alpha: trail.id == selectedFlaeche?.id
                ? TrailAreaStyle.fillOpacitySelected *
                      (trackOpacity <= 0 ? 1.0 : trackOpacity)
                : TrailAreaStyle.fillOpacityOverview,
          ),
          borderColor: TrailAreaStyle.border.withValues(
            alpha: trail.id == selectedFlaeche?.id
                ? (trackOpacity <= 0 ? 1.0 : trackOpacity)
                : 0.7,
          ),
          borderStrokeWidth: trail.id == selectedFlaeche?.id
              ? TrailAreaStyle.borderWidthSelected
              : TrailAreaStyle.borderWidthOverview,
        ),
  ];
}

/// Route des ausgewählten Linien-Trails, eingefaded via [trackOpacity].
/// Null, wenn gerade ein Walk läuft (dann zeigt der Walk-Layer).
Polyline? buildSelectedTrackPolyline({
  required Trail? selectedLinie,
  required bool inWalk,
  required double trackOpacity,
}) {
  if (selectedLinie == null || inWalk || selectedLinie.route.length < 2) {
    return null;
  }
  return Polyline(
    points: selectedLinie.route,
    strokeWidth: TrailPolylineStyle.strokeWidth,
    color: TrailPolylineStyle.color.withValues(alpha: trackOpacity),
    pattern: TrailPolylineStyle.pattern,
  );
}
