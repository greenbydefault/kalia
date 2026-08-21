import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/theme/app_colors.dart';

/// User-Position als Map-Marker.
List<Marker> walkUserMarkers(LatLng? position) {
  if (position == null) return const [];
  return [
    Marker(
      point: position,
      width: 28,
      height: 28,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.brand,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(blurRadius: 8, color: AppColors.scrim38)],
        ),
      ),
    ),
  ];
}
