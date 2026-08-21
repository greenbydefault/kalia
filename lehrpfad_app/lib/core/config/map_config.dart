import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Zentrale Karten-Konfiguration: Tile-Server, User-Agent und
/// Default-Ausschnitt. Hier wird später auch Offline-Caching (z. B. FMTC)
/// oder ein eigener Tile-Server eingehängt, ohne die Screens anzufassen.
abstract final class MapConfig {
  static const tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const userAgentPackageName = 'de.greenbydefault.lehrpfad_app';

  /// Fallback-Ausschnitt (Müritz-Region), solange keine Trails geladen sind.
  static const defaultCenter = LatLng(53.114, 13.02);
  static const defaultZoom = 13.0;

  /// Zoom beim FAB „Meinen Standort“ — Straßen-/Nachbarschaftsebene.
  static const locateZoom = 16.0;

  static TileLayer buildOsmTileLayer() {
    return TileLayer(
      urlTemplate: tileUrl,
      userAgentPackageName: userAgentPackageName,
    );
  }
}
