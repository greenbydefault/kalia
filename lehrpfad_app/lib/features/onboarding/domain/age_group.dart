/// Altersgruppe der Kinder, die mitkommen.
///
/// [maxKm] ist ein Platzhalter für „bis ca. X km“ und wird später
/// aus Daten abgeleitet.
enum AgeGroup {
  under3('Unter 3', 'Trage oder Wagen', 4),
  threeToFive('3 bis 5', 'Jahre', 3),
  sixToNine('6 bis 9', 'Jahre', 6),
  tenPlus('10 und älter', 'Jahre', 10);

  const AgeGroup(this.title, this.subtitle, this.maxKm);

  final String title;
  final String subtitle;
  final int maxKm;

  static AgeGroup? tryParse(String? raw) {
    for (final g in values) {
      if (g.name == raw) return g;
    }
    return null;
  }

  /// Kleinste empfohlene Länge über die gewählten Gruppen, sonst `null`.
  static int? minKm(Iterable<AgeGroup> groups) {
    int? min;
    for (final g in groups) {
      if (min == null || g.maxKm < min) min = g.maxKm;
    }
    return min;
  }
}
