import 'package:latlong2/latlong.dart';

import '../domain/trail.dart';

/// Datenzugriff auf Lehrpfade. Die UI kennt nur dieses Interface;
/// Implementierungen (Seed-Assets, später Supabase) sind austauschbar.
abstract interface class TrailRepository {
  Future<List<Trail>> getTrails({LatLng? near, double? radiusKm});
}
