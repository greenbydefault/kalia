import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/theme/app_colors.dart';
import '../../trail/presentation/map/trail_polyline_style.dart';
import '../geo/polyline_metrics.dart';

/// Done/Remaining Polylines für Walk-Mode.
List<Polyline> walkProgressPolylines({
  required List<LatLng> route,
  required double progressM,
}) {
  if (route.length < 2) return const [];
  final metrics = PolylineMetrics.from(route);
  final done = metrics.prefixUntil(progressM);
  final rest = metrics.suffixFrom(progressM);

  return [
    if (done.length >= 2)
      Polyline(
        points: done,
        strokeWidth: TrailPolylineStyle.strokeWidth + 1,
        color: AppColors.brand,
      ),
    if (rest.length >= 2)
      Polyline(
        points: rest,
        strokeWidth: TrailPolylineStyle.strokeWidth,
        color: TrailPolylineStyle.color.withValues(alpha: 0.45),
        pattern: TrailPolylineStyle.pattern,
      ),
  ];
}
