import '../domain/nearby_place.dart';

/// Liefert den Katalog der Orte in der Nähe (ein Load, kein N+1, kein Filter).
abstract class NearbyRepository {
  Future<List<NearbyPlace>> getCatalog();
}
