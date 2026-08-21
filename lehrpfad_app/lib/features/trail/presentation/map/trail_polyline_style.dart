import 'package:flutter_map/flutter_map.dart';

import '../../../../app/theme/app_colors.dart';

/// Einheitlicher Stil für Trail-Routen-Linien in beiden Karten.
abstract final class TrailPolylineStyle {
  static const color = AppColors.brand;
  static const strokeWidth = 4.0;
  static final pattern = StrokePattern.dashed(segments: const [12, 8]);
}
