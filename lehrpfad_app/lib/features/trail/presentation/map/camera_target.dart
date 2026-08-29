import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/trail.dart';
import 'trail_peek_card.dart';

/// Kameraziel: Fit auf Trail-Geometrie (Katalog, Hero, externer Einstieg).
///
/// Bounds + Padding, sodass Trail-`mapPoints` im Viewport liegen.
/// Peek ist Bottom-Padding für die Peek-Card. Tap bewegt die Kamera nicht.
class CameraTarget {
  const CameraTarget({required this.bounds, required this.padding});

  final LatLngBounds bounds;
  final EdgeInsets padding;

  static const catalogPadding = EdgeInsets.fromLTRB(48, 88, 48, 48);

  static const peekPadding = EdgeInsets.fromLTRB(
    48,
    88,
    48,
    TrailPeekCard.height + 24,
  );

  static const heroPadding = EdgeInsets.all(24);

  static EdgeInsets paddingFor({required bool peek}) =>
      peek ? peekPadding : catalogPadding;

  /// Null bei leerer Punktliste ([LatLngBounds.fromPoints] darf das nicht).
  static CameraTarget? fromPoints(
    List<LatLng> points, {
    required EdgeInsets padding,
  }) {
    if (points.isEmpty) return null;
    return CameraTarget(
      bounds: LatLngBounds.fromPoints(points),
      padding: padding,
    );
  }

  static CameraTarget? fromTrail(Trail trail, {required EdgeInsets padding}) =>
      fromPoints(trail.mapPoints, padding: padding);
}
