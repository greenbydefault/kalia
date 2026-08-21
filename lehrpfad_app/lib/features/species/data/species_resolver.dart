import '../domain/species.dart';

/// Loest Anzeigenamen aus `trail.arten` gegen den Katalog auf.
///
/// Lookup ueber [Species.nameDe] und [Species.aliases] (case-insensitive).
class SpeciesResolver {
  SpeciesResolver(List<Species> catalog) : _byName = _buildLookup(catalog);

  final Map<String, Species> _byName;

  static Map<String, Species> _buildLookup(List<Species> catalog) {
    final map = <String, Species>{};
    for (final s in catalog) {
      map[s.nameDe.toLowerCase()] = s;
      for (final alias in s.aliases) {
        map[alias.toLowerCase()] = s;
      }
    }
    return map;
  }

  /// Reihenfolge wie in [names]; Duplikate (Alias → gleiche Art) entfallen.
  List<Species> resolve(List<String> names) {
    final seen = <String>{};
    final out = <Species>[];
    for (final name in names) {
      final s = _byName[name.toLowerCase()];
      if (s == null || seen.contains(s.id)) continue;
      seen.add(s.id);
      out.add(s);
    }
    return out;
  }

  Species? byId(String id) {
    for (final s in _byName.values) {
      if (s.id == id) return s;
    }
    return null;
  }
}
