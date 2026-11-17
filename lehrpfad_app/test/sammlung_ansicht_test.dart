import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:lehrpfad_app/features/species/data/sammlung_providers.dart';
import 'package:lehrpfad_app/features/species/domain/fund.dart';
import 'package:lehrpfad_app/features/species/domain/sammlung_ansicht.dart';
import 'package:lehrpfad_app/features/species/domain/species.dart';
import 'package:lehrpfad_app/features/trail/domain/trail.dart';

Species _s(String id, String kat, {String gruppe = ''}) => Species(
  id: id,
  nameDe: id,
  nameLat: '',
  kategorie: kat,
  kurztext: '',
  gruppe: gruppe,
);

Trail _trail(String id, LatLng start, List<String> arten) => Trail(
  id: id,
  name: id,
  typ: 'wald',
  kurzbeschreibung: 'k',
  beschreibung: 'b',
  laengeKm: 1,
  dauerMin: 30,
  rundkurs: false,
  markierung: 'm',
  betreiber: 'b',
  region: 'r',
  anreise: 'a',
  startName: 's',
  arten: arten,
  route: [start, LatLng(start.latitude + 0.001, start.longitude)],
  stationen: const [],
  amenities: const [],
);

void main() {
  final now = DateTime.utc(2026, 11, 15, 12);
  final katalog = [
    _s('amsel', 'fauna', gruppe: 'voegel'),
    _s('biber', 'fauna', gruppe: 'saeugetiere'),
    _s('fuchs', 'fauna', gruppe: 'saeugetiere'),
    _s('eisvogel', 'fauna', gruppe: 'voegel'),
    _s('buche', 'flora', gruppe: 'baeume'),
    _s('schild', 'geraete'),
  ];

  Fund f(String id, {DateTime? at}) => Fund(speciesId: id, entdecktAm: at);

  test('Zähler: Gesamt, Woche, je Kategorie', () {
    final a = SammlungAnsicht.berechne(
      katalog: katalog,
      funde: {
        'amsel': f('amsel', at: now.subtract(const Duration(days: 2))),
        'biber': f('biber', at: now.subtract(const Duration(days: 30))),
        'buche': f('buche'),
        'weg': f('weg', at: now), // nicht im Katalog
      },
      kategorie: 'fauna',
      now: now,
    );
    expect(a.fundeGesamt, 3);
    expect(a.fundeWoche, 1);
    expect(a.fundeIn('fauna'), 2);
    expect(a.fundeIn('flora'), 1);
    expect(a.fundeIn('geraete'), 0);
  });

  test(
    'Funde neueste zuerst, ohne Datum hinten; Offen in Katalog-Reihenfolge',
    () {
      final a = SammlungAnsicht.berechne(
        katalog: katalog,
        funde: {
          'amsel': f('amsel', at: DateTime.utc(2026, 11, 1)),
          'biber': f('biber', at: DateTime.utc(2026, 11, 10)),
          'eisvogel': f('eisvogel'),
        },
        kategorie: 'fauna',
        now: now,
      );
      expect(a.funde.map((s) => s.id), ['biber', 'amsel', 'eisvogel']);
      expect(a.offen.map((s) => s.id), ['fuchs']);
      // Altbestand ohne Datum fehlt in „Zuletzt entdeckt“
      expect(a.zuletzt.map((s) => s.id), ['biber', 'amsel']);
    },
  );

  test('Zuletzt: max 5, nur ohne Gruppen-Filter', () {
    final viele = [
      for (var i = 0; i < 8; i++) _s('v$i', 'fauna', gruppe: 'voegel'),
    ];
    final funde = {
      for (var i = 0; i < 8; i++)
        'v$i': f('v$i', at: DateTime.utc(2026, 11, 1 + i)),
    };
    final alle = SammlungAnsicht.berechne(
      katalog: viele,
      funde: funde,
      kategorie: 'fauna',
      now: now,
    );
    expect(alle.zuletzt.length, 5);
    expect(alle.zuletzt.first.id, 'v7');

    final gefiltert = SammlungAnsicht.berechne(
      katalog: viele,
      funde: funde,
      kategorie: 'fauna',
      gruppe: 'voegel',
      now: now,
    );
    expect(gefiltert.zuletzt, isEmpty);
    expect(gefiltert.funde.length, 8);
  });

  test('Gruppen kommen aus den Daten der Kategorie, Geräte haben keine', () {
    final fauna = SammlungAnsicht.berechne(
      katalog: katalog,
      funde: const {},
      kategorie: 'fauna',
      now: now,
    );
    expect(fauna.gruppen, ['saeugetiere', 'voegel']);
    final geraete = SammlungAnsicht.berechne(
      katalog: katalog,
      funde: const {},
      kategorie: 'geraete',
      now: now,
    );
    expect(geraete.gruppen, isEmpty);
  });

  test('Gruppen-Filter schränkt Funde und Offen ein', () {
    final a = SammlungAnsicht.berechne(
      katalog: katalog,
      funde: {'biber': f('biber', at: now)},
      kategorie: 'fauna',
      gruppe: 'saeugetiere',
      now: now,
    );
    expect(a.funde.map((s) => s.id), ['biber']);
    expect(a.offen.map((s) => s.id), ['fuchs']);
  });

  test('Alles gefunden: Offen leer; nichts gefunden: Funde leer', () {
    final alle = SammlungAnsicht.berechne(
      katalog: katalog,
      funde: {for (final s in katalog) s.id: f(s.id, at: now)},
      kategorie: 'flora',
      now: now,
    );
    expect(alle.offen, isEmpty);
    final keine = SammlungAnsicht.berechne(
      katalog: katalog,
      funde: const {},
      kategorie: 'flora',
      now: now,
    );
    expect(keine.hatFunde, isFalse);
    expect(keine.funde, isEmpty);
    expect(keine.offen.length, 1);
  });

  test('relativeZeit', () {
    final jetzt = DateTime(2026, 11, 15, 12);
    String r(int tage) =>
        relativeZeit(jetzt.subtract(Duration(days: tage)), jetzt);
    expect(r(0), 'heute');
    expect(r(1), 'gestern');
    expect(r(3), 'vor 3 Tagen');
    expect(r(7), 'vor 1 Woche');
    expect(r(15), 'vor 2 Wochen');
    expect(r(31), 'vor 1 Monat');
    expect(r(95), 'vor 3 Monaten');
  });

  group('Nähe', () {
    const bezug = LatLng(52.0, 13.0);
    final nah = _trail('nah', const LatLng(52.05, 13.0), ['amsel', 'fuchs']);
    final fern = _trail('fern', const LatLng(52.5, 13.0), ['amsel', 'biber']);
    final trails = {
      'amsel': [fern, nah],
      'fuchs': [nah],
      'biber': [fern],
    };
    final offen = [katalog[0], katalog[1], katalog[2], katalog[3]];

    test('Top 2 nach kürzester Anfahrt, bester Pfad je Art', () {
      final t = naehTreffer(offen: offen, speciesTrails: trails, bezug: bezug);
      expect(t.map((e) => e.species.id), ['amsel', 'fuchs']);
      expect(t.first.chance.trail.id, 'nah');
    });

    test('ohne Bezug oder ohne Pfad keine Treffer', () {
      expect(
        naehTreffer(offen: offen, speciesTrails: trails, bezug: null),
        isEmpty,
      );
      expect(
        naehTreffer(offen: [katalog[3]], speciesTrails: trails, bezug: bezug),
        isEmpty,
      );
    });

    test('chancenFuer ohne Bezug: nur Namen, ohne Minuten', () {
      final c = chancenFuer([fern, nah], null);
      expect(c.map((e) => e.trail.id), ['fern', 'nah']);
      expect(c.every((e) => e.minuten == null), isTrue);
    });
  });

  test('Fund.merge: frühestes Datum, vorhandene Angaben gewinnen', () {
    final lokal = Fund(
      speciesId: 'a',
      entdecktAm: DateTime.utc(2026, 11, 10),
      von: EntdecktVon.kind,
    );
    final remote = Fund(
      speciesId: 'a',
      entdecktAm: DateTime.utc(2026, 11, 1),
      trailId: 'x',
    );
    final m = Fund.merge(lokal, remote);
    expect(m.entdecktAm, DateTime.utc(2026, 11, 1));
    expect(m.trailId, 'x');
    expect(m.von, EntdecktVon.kind);
    expect(
      Fund.merge(const Fund(speciesId: 'a'), remote).entdecktAm,
      remote.entdecktAm,
    );
  });
}
