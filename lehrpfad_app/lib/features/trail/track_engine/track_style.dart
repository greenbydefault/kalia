import '../../../app/theme/app_colors.dart';

/// Zentrale Optik für den isolierten Track (Content-View).
///
/// Einzige Stelle für Track-/Contour-/Marker-Tokens — einmal ändern, überall wirksam.
abstract final class TrackStyle {
  static const background = AppColors.paper;
  static const contour = AppColors.n200;
  static const contourWidth = 1.0;
  static const track = AppColors.brand;
  static const trackWidth = 7.0;
  static const startRadius = 6.0;
  static const stationRadius = 12.0;
  static const stationHitRadius = 22.0;
  static const stationBorder = AppColors.n50;
  static const stationBorderWidth = 2.0;
  static const padding = 28.0;
  static const height = 300.0;
  static const borderRadius = 16.0;

  /// Zielpunktzahl nach Douglas-Peucker (OSM-Routen oft 100–1000+ Nodes).
  static const simplifyTarget = 120;

  /// Abstände der Terrain-Offset-Bänder in Canvas-Einheiten (nach Fit).
  static const contourOffsets = [18.0, 32.0, 48.0, 64.0, 82.0];
}
