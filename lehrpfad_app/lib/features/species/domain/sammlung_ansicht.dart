import '../../../shared/catalogs/icon_catalog.dart';
import 'fund.dart';
import 'species.dart';

/// Abgeleitete Ansicht des Sammlung-Tabs. Rein, ohne Flutter/Riverpod.
class SammlungAnsicht {
  const SammlungAnsicht({
    required this.fundeGesamt,
    required this.fundeWoche,
    required this.fundeJeKategorie,
    required this.gruppen,
    required this.zuletzt,
    required this.funde,
    required this.offen,
  });

  /// Alle Funde im Katalog (Kopf-Zähler).
  final int fundeGesamt;

  /// Funde mit Datum ≤ 7 Tage.
  final int fundeWoche;

  /// Funde je Kategorie (`flora` / `fauna` / `geraete`), nie „x von y“.
  final Map<String, int> fundeJeKategorie;

  /// Gruppen-Keys der aktiven Kategorie, in Katalog-Reihenfolge.
  final List<String> gruppen;

  /// Neueste Funde der Kategorie (max. [zuletztMax]); leer bei Gruppen-Filter.
  final List<Species> zuletzt;

  /// Funde im aktuellen Filter, neueste zuerst, ohne Datum hinten.
  final List<Species> funde;

  /// Offene Einträge im aktuellen Filter in Katalog-Reihenfolge.
  final List<Species> offen;

  static const zuletztMax = 5;

  bool get hatFunde => fundeGesamt > 0;

  int fundeIn(String kategorie) => fundeJeKategorie[kategorie] ?? 0;

  static SammlungAnsicht berechne({
    required List<Species> katalog,
    required Map<String, Fund> funde,
    required String kategorie,
    String? gruppe,
    required DateTime now,
  }) {
    final gefunden = <Species>[
      for (final s in katalog)
        if (funde.containsKey(s.id)) s,
    ];

    final woche = now.subtract(const Duration(days: 7));
    final fundeWoche = gefunden.where((s) {
      final at = funde[s.id]!.entdecktAm;
      return at != null && !at.isBefore(woche);
    }).length;

    final jeKategorie = <String, int>{};
    for (final s in gefunden) {
      jeKategorie[s.kategorie] = (jeKategorie[s.kategorie] ?? 0) + 1;
    }

    final inKategorie = katalog.where((s) => s.kategorie == kategorie).toList();
    final gruppen = gruppenVon(inKategorie);

    final imFilter = gruppe == null
        ? inKategorie
        : inKategorie.where((s) => s.gruppe == gruppe).toList();

    final fundeImFilter = _nachDatum(
      imFilter.where((s) => funde.containsKey(s.id)).toList(),
      funde,
    );
    final offen = imFilter.where((s) => !funde.containsKey(s.id)).toList();

    final zuletzt = gruppe != null
        ? const <Species>[]
        : _nachDatum(
            inKategorie.where((s) => funde[s.id]?.entdecktAm != null).toList(),
            funde,
          ).take(zuletztMax).toList();

    return SammlungAnsicht(
      fundeGesamt: gefunden.length,
      fundeWoche: fundeWoche,
      fundeJeKategorie: jeKategorie,
      gruppen: gruppen,
      zuletzt: zuletzt,
      funde: fundeImFilter,
      offen: offen,
    );
  }

  /// Gruppen der Liste: Reihenfolge aus [speciesGruppeKatalog], Unbekannte
  /// am Ende. Leere Gruppen (Geräte) entfallen.
  static List<String> gruppenVon(List<Species> arten) {
    final vorhanden = {
      for (final s in arten)
        if (s.gruppe.isNotEmpty) s.gruppe,
    };
    final known = speciesGruppeKatalog.keys.where(vorhanden.contains);
    final rest = vorhanden.where((g) => !speciesGruppeKatalog.containsKey(g));
    return [...known, ...(rest.toList()..sort())];
  }

  /// Neueste zuerst; ohne Datum hinten, dort bleibt die Reihenfolge stabil.
  static List<Species> _nachDatum(
    List<Species> arten,
    Map<String, Fund> funde,
  ) {
    final indexed = arten.indexed.toList();
    indexed.sort((a, b) {
      final da = funde[a.$2.id]?.entdecktAm;
      final db = funde[b.$2.id]?.entdecktAm;
      if (da != null && db != null) {
        final c = db.compareTo(da);
        if (c != 0) return c;
      } else if (da != null) {
        return -1;
      } else if (db != null) {
        return 1;
      }
      return a.$1.compareTo(b.$1);
    });
    return [for (final e in indexed) e.$2];
  }
}

/// heute · gestern · vor X Tagen · vor X Wochen · vor X Monaten
String relativeZeit(DateTime zeitpunkt, DateTime now) {
  final a = zeitpunkt.toLocal();
  final b = now.toLocal();
  final tage = DateTime(
    b.year,
    b.month,
    b.day,
  ).difference(DateTime(a.year, a.month, a.day)).inDays;
  if (tage <= 0) return 'heute';
  if (tage == 1) return 'gestern';
  if (tage < 7) return 'vor $tage Tagen';
  if (tage < 30) {
    final w = tage ~/ 7;
    return w == 1 ? 'vor 1 Woche' : 'vor $w Wochen';
  }
  final m = tage ~/ 30;
  return m == 1 ? 'vor 1 Monat' : 'vor $m Monaten';
}
