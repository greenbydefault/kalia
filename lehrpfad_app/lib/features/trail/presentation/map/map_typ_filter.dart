import '../../../../shared/catalogs/icon_catalog.dart';
import '../../domain/trail.dart';

/// Unique `typ`-Keys der [trails], in Katalog-Reihenfolge.
/// Unbekannte Keys (nicht in [typKatalog]) hängen hinten, Erstvorkommen.
List<String> typsIn(Iterable<Trail> trails) {
  final present = <String>{};
  final unknown = <String>[];
  for (final trail in trails) {
    if (!present.add(trail.typ)) continue;
    if (!typKatalog.containsKey(trail.typ)) unknown.add(trail.typ);
  }
  return [
    for (final key in typKatalog.keys)
      if (present.contains(key)) key,
    ...unknown,
  ];
}

/// [typ] == null → unverändert; sonst nur Trails dieses Typs.
List<Trail>? filterTrailsByTyp(List<Trail>? trails, String? typ) {
  if (trails == null || typ == null) return trails;
  return [for (final trail in trails) if (trail.typ == typ) trail];
}
