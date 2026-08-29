import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/app_colors.dart';
import '../catalogs/icon_catalog.dart';
import 'typ_start_marker.dart';

/// Marker für einen Ort in der Nähe. Kleiner und invertiert zum Trail-Start.
class PoiMarker extends StatelessWidget {
  final String kategorie;
  final bool selected;
  final VoidCallback? onTap;

  const PoiMarker({
    super.key,
    required this.kategorie,
    this.selected = false,
    this.onTap,
  });

  static const size = 32.0;
  static const selectedSize = 36.0;
  static const iconPadding = 5.0;

  double get _size => selected ? selectedSize : size;

  Marker toMarker(LatLng point, {Key? key}) {
    return Marker(
      key: key,
      point: point,
      width: _size,
      height: _size,
      alignment: Alignment.center,
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    final eintrag = poiKategorieEintrag(kategorie);
    final fill = selected ? AppColors.brand : AppColors.n50;
    final fg = selected ? AppColors.n50 : AppColors.brand;
    final marker = Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.brand, width: MapMarkerStyle.borderWidth),
        boxShadow: const [
          BoxShadow(blurRadius: MapMarkerStyle.shadowBlur, color: AppColors.scrim38),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(iconPadding),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: eintrag.buildIcon(size: _size - 2 * iconPadding, color: fg),
        ),
      ),
    );

    return Semantics(
      button: onTap != null,
      label: eintrag.label,
      child: onTap == null
          ? marker
          : GestureDetector(onTap: onTap, child: marker),
    );
  }
}
