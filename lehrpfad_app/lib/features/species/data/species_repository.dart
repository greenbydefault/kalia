import '../domain/merkmal.dart';
import '../domain/species.dart';

/// Liefert den Artenkatalog (ein Load, kein N+1).
abstract class SpeciesRepository {
  Future<List<Species>> getCatalog();

  /// Merkmale-Katalog (Badges) — einmalig, kein N+1.
  Future<List<Merkmal>> getMerkmale();
}
