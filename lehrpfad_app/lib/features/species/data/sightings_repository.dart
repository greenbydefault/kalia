import '../domain/fund.dart';

/// Persistierte Funde (gesehene Arten/Geräte).
abstract class SightingsRepository {
  Future<Map<String, Fund>> getFunde();

  /// Persistiert [funde] (kompletter Stand, last-wins) und synced die
  /// geänderte [speciesId] remote (soft-fail). Fehlt die ID in [funde],
  /// geht ein Delete raus, sonst ein Upsert.
  Future<void> applyChange({
    required Map<String, Fund> funde,
    required String speciesId,
  });
}
