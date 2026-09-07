import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/app_colors.dart';
import '../../features/trail/domain/trail.dart';
import '../catalogs/icon_catalog.dart';

/// Maße für Map-Bubbles. Einmal ändern, Chrome + Hitbox folgen.
abstract final class MapMarkerStyle {
  static const size = 32.0;
  static const borderWidth = 2.0;
  static const iconPadding = 4.0;
  static const shadowBlur = 8.0;
  static const iconSize = size - 2 * borderWidth - 2 * iconPadding;
  static const letterScale = 0.85;

  static const poiSize = 26.0;
  static const poiSelectedSize = 30.0;
  static const poiIconPadding = 3.0;
}

/// Start-/Trail-Marker: Brand-Kreis + Typ-Icon aus [typKatalog].
///
/// Einzige Stelle für Trail-Marker-Chrome. Orte in der Nähe: `PoiMarker`.
/// A/B-Endpunkte: [TypStartMarker.letter]. Cluster: [TypStartMarker.count].
class TypStartMarker extends StatelessWidget {
  final String? typ;
  final String? letter;
  final int? count;
  final bool inverted;
  final bool eintritt;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;

  const TypStartMarker({
    super.key,
    required String this.typ,
    this.eintritt = false,
    this.onTap,
    this.size = MapMarkerStyle.size,
    this.iconSize = MapMarkerStyle.iconSize,
  }) : letter = null,
       count = null,
       inverted = false;

  /// Einzige Stelle für Trail-Startpins. Nächster Paid-Trail: `eintritt: true`.
  factory TypStartMarker.forTrail(
    Trail trail, {
    Key? key,
    VoidCallback? onTap,
    double size = MapMarkerStyle.size,
    double iconSize = MapMarkerStyle.iconSize,
  }) {
    return TypStartMarker(
      key: key,
      typ: trail.typ,
      eintritt: trail.eintritt,
      onTap: onTap,
      size: size,
      iconSize: iconSize,
    );
  }

  const TypStartMarker.letter(
    String this.letter, {
    super.key,
    this.inverted = false,
    this.onTap,
    this.size = MapMarkerStyle.size,
    this.iconSize = MapMarkerStyle.iconSize,
  }) : typ = null,
       count = null,
       eintritt = false;

  const TypStartMarker.count(
    int this.count, {
    super.key,
    this.onTap,
    this.size = MapMarkerStyle.size,
    this.iconSize = MapMarkerStyle.iconSize,
  }) : typ = null,
       letter = null,
       inverted = false,
       eintritt = false;

  /// Hitbox = [size]. Optional [wrap] für Appear-Animation.
  Marker toMarker(
    LatLng point, {
    Key? key,
    Widget Function(Widget child)? wrap,
  }) {
    return Marker(
      key: key,
      point: point,
      width: size,
      height: size,
      alignment: Alignment.center,
      child: wrap == null ? this : wrap(this),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fill = inverted ? AppColors.n50 : AppColors.brand;
    final fg = inverted ? AppColors.brand : AppColors.n50;
    final border = eintritt
        ? AppColors.eintrittRing
        : (inverted ? AppColors.brand : AppColors.n50);

    final Widget inner;
    if (count != null) {
      inner = _letterBox('$count', fg);
    } else if (letter != null) {
      inner = _letterBox(letter!, fg);
    } else {
      inner = typEintrag(typ!).buildIcon(size: iconSize, color: fg);
    }

    final marker = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: MapMarkerStyle.borderWidth),
        boxShadow: const [
          BoxShadow(blurRadius: MapMarkerStyle.shadowBlur, color: AppColors.scrim38),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(MapMarkerStyle.iconPadding),
        child: FittedBox(fit: BoxFit.scaleDown, child: inner),
      ),
    );

    return Semantics(
      button: onTap != null,
      label: _semanticsLabel,
      child: onTap == null
          ? marker
          : GestureDetector(onTap: onTap, child: marker),
    );
  }

  Widget _letterBox(String text, Color fg) {
    return SizedBox.square(
      dimension: iconSize,
      child: FittedBox(
        child: Text(
          text,
          style: TextStyle(
            color: fg,
            fontSize: iconSize * MapMarkerStyle.letterScale,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }

  String get _semanticsLabel {
    if (count != null) return '$count Orte';
    if (letter == 'B') return 'Ziel';
    if (letter == 'A') return 'Start';
    return typEintrag(typ!).label;
  }
}
