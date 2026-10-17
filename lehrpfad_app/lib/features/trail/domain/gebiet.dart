/// Hauptgebiet eines Eintrags (Chip-Reihe, Marker-Icon, Vorschläge).
///
/// Regeln müssen mit `tools/gebiet.py` übereinstimmen.
enum Gebiet {
  wald,
  heide,
  moor,
  kueste,
  wasser,
  spreewald,
  hof;

  /// Wire-Key im Seed (`gebiet`).
  String get key => name;

  static Gebiet? fromKey(String? key) {
    for (final g in Gebiet.values) {
      if (g.name == key) return g;
    }
    return null;
  }
}

const _typGebiet = {
  'kueste': Gebiet.kueste,
  'moor': Gebiet.moor,
  'spreewald': Gebiet.spreewald,
  'kinderbauernhof': Gebiet.hof,
  'wasserspielplatz': Gebiet.wasser,
};

const _lebensraumGebiet = {
  'heide': Gebiet.heide,
  'trockenrasen': Gebiet.heide,
  'moor': Gebiet.moor,
  'duene-strand': Gebiet.kueste,
  'salzwiese-watt': Gebiet.kueste,
  'fliessgewaesser': Gebiet.wasser,
  'see-ufer': Gebiet.wasser,
  'teich-tuempel': Gebiet.wasser,
  'hof-nutztier': Gebiet.hof,
};

/// Gebiet aus `typ` und `lebensraeume`, wenn der Seed keines trägt.
Gebiet deriveGebiet(String typ, List<String> lebensraeume) {
  final byTyp = _typGebiet[typ];
  if (byTyp != null) return byTyp;
  if (lebensraeume.isNotEmpty) {
    final byLeben = _lebensraumGebiet[lebensraeume.first];
    if (byLeben != null) return byLeben;
  }
  return Gebiet.wald;
}
