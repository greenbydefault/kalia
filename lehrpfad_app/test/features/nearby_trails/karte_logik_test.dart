import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:lehrpfad_app/features/nearby_trails/domain/eintrag.dart';
import 'package:lehrpfad_app/features/nearby_trails/domain/karte_copy.dart';
import 'package:lehrpfad_app/features/nearby_trails/domain/karte_logik.dart';
import 'package:lehrpfad_app/features/trail/domain/gebiet.dart';

const _bezug = LatLng(52.0, 13.0);

/// Ein Punkt etwa [km] nördlich vom Bezug (1 Grad Breite ≈ 111,2 km).
LatLng _nord(double km) => LatLng(52.0 + km / 111.2, 13.0);

Eintrag _e(
  String id, {
  EintragArt art = EintragArt.weg,
  Gebiet gebiet = Gebiet.wald,
  double km = 5,
  String? name,
  int? dauer,
  int? laenge,
  int? kinder,
  int? barriere,
  bool? rundkurs,
  bool kinderwagen = false,
  bool parkplatz = false,
  bool wc = false,
  bool einkehr = false,
  Saison? saison,
}) => Eintrag(
  id: id,
  art: art,
  gebiet: gebiet,
  name: name ?? id,
  startpunkt: _nord(km),
  dauerMin: dauer,
  laengeM: laenge,
  kinderfreundlich: kinder,
  barrierefreundlich: barriere,
  rundkurs: rundkurs,
  kinderwagen: kinderwagen,
  parkplatz: parkplatz,
  wcAmWeg: wc,
  einkehr: einkehr,
  saison: saison,
);

List<String> _ids(Iterable<Treffer> t) => [for (final x in t) x.eintrag.id];

void main() {
  group('formatAnfahrt', () {
    test('Beispiele der Spec', () {
      expect(formatAnfahrt(3), 'ca. 3 Min');
      expect(formatAnfahrt(23), 'ca. 25 Min');
      expect(formatAnfahrt(58), 'ca. 1 Std');
      expect(formatAnfahrt(80), 'ca. 1,5 Std');
      expect(formatAnfahrt(125), 'ca. 2 Std');
    });
    test('Grenzen', () {
      expect(formatAnfahrt(9), 'ca. 9 Min');
      expect(formatAnfahrt(10), 'ca. 10 Min');
      expect(formatAnfahrt(57), 'ca. 55 Min');
      expect(formatAnfahrt(60), 'ca. 1 Std');
    });
  });

  group('formatDauer', () {
    test('Beispiele der Spec', () {
      expect(formatDauer(40), '40 Min');
      expect(formatDauer(42), '45 Min');
      expect(formatDauer(90), '1,5 Std');
      expect(formatDauer(100), '2 Std');
      expect(formatDauer(150), '2,5 Std');
    });
    test('Aufrunden über die Stundengrenze', () {
      expect(formatDauer(58), '1 Std');
      expect(formatDauer(60), '1 Std');
      expect(formatDauer(61), '1,5 Std');
    });
  });

  group('formatLaenge', () {
    test('Beispiele der Spec', () {
      expect(formatLaenge(800), '800 m');
      expect(formatLaenge(3000), '3 km');
      expect(formatLaenge(11600), '11,6 km');
    });
    test('Runden auf 50 m', () {
      expect(formatLaenge(830), '850 m');
      expect(formatLaenge(980), '1 km');
    });
  });

  group('formatSaison', () {
    test('Beispiele der Spec', () {
      expect(formatSaison(const Saison(5, 9), DateTime(2026, 7)), 'Mai–Sep');
      expect(formatSaison(const Saison(5, 9), DateTime(2026, 10)), 'ab Mai');
      expect(formatSaison(const Saison(11, 2), DateTime(2026, 12)), 'Nov–Feb');
    });
    test('ganzjährig und Jahreswechsel', () {
      expect(
        formatSaison(const Saison.ganzjaehrig(), DateTime(2026, 3)),
        'Ganzjährig',
      );
      expect(const Saison(11, 2).enthaelt(1), isTrue);
      expect(const Saison(11, 2).enthaelt(6), isFalse);
    });
  });

  test('formatEintritt', () {
    expect(formatEintritt(const Eintritt('3 € p. P.')), '3 € p. P.');
    expect(formatEintritt(const Eintritt.frei()), 'Frei');
  });

  test('formatKinder', () {
    expect(formatKinder(4), [true, true, true, true, false]);
    expect(formatKinder(null), isNull);
    expect(kinderSemantik(4), 'Kinderfreundlich: 4 von 5');
  });

  group('schaetzeAnfahrtMin', () {
    test('mindestens 2 Min', () {
      expect(schaetzeAnfahrtMin(_bezug, _bezug), 2);
    });
    test('Umweg 1,3 und 45 km/h', () {
      // 30 km Luftlinie → 39 km → 52 Min
      expect(schaetzeAnfahrtMin(_bezug, _nord(30)), 52);
    });
  });

  group('Filter', () {
    test('Standard lässt alles durch, zählt 0', () {
      expect(KarteFilter.standard.passt(_e('a')), isTrue);
      expect(KarteFilter.standard.anzahlAktiv, 0);
    });

    test('Dauergrenzen nur für Wege', () {
      const bis1 = KarteFilter(dauer: DauerBereich.bis1Std);
      expect(bis1.passt(_e('a', dauer: 60)), isTrue);
      expect(bis1.passt(_e('a', dauer: 61)), isFalse);
      const mid = KarteFilter(dauer: DauerBereich.von1bis2Std);
      expect(mid.passt(_e('a', dauer: 61)), isTrue);
      expect(mid.passt(_e('a', dauer: 120)), isTrue);
      expect(mid.passt(_e('a', dauer: 121)), isFalse);
      const lang = KarteFilter(dauer: DauerBereich.ueber2Std);
      expect(lang.passt(_e('a', dauer: 121)), isTrue);
      // Weg ohne Dauer fällt raus, Ort bleibt unberührt.
      expect(bis1.passt(_e('a')), isFalse);
      expect(bis1.passt(_e('o', art: EintragArt.ort)), isTrue);
    });

    test('Längengrenzen', () {
      const bis3 = KarteFilter(laenge: LaengeBereich.bis3km);
      expect(bis3.passt(_e('a', laenge: 3000)), isTrue);
      expect(bis3.passt(_e('a', laenge: 3001)), isFalse);
      const bis5 = KarteFilter(laenge: LaengeBereich.bis5km);
      expect(bis5.passt(_e('a', laenge: 5000)), isTrue);
      expect(bis5.passt(_e('a', laenge: 5001)), isFalse);
      const ueber5 = KarteFilter(laenge: LaengeBereich.ueber5km);
      expect(ueber5.passt(_e('a', laenge: 5001)), isTrue);
      expect(ueber5.passt(_e('a', laenge: 5000)), isFalse);
    });

    test('Art: nur Wege oder nur Orte', () {
      const nurWege = KarteFilter(arten: {EintragArt.weg});
      expect(nurWege.passt(_e('w')), isTrue);
      expect(nurWege.passt(_e('o', art: EintragArt.ort)), isFalse);
      expect(nurWege.anzahlAktiv, 1);
    });

    test('Merkmale mit UND, unbekannt fällt raus', () {
      const f = KarteFilter(merkmale: {Merkmal.rundkurs, Merkmal.parkplatz});
      expect(f.passt(_e('a', rundkurs: true, parkplatz: true)), isTrue);
      expect(f.passt(_e('a', rundkurs: true)), isFalse);
      // Rundkurs bei einem Ort: passt nicht zum Typ.
      expect(f.passt(_e('o', art: EintragArt.ort, parkplatz: true)), isFalse);
      expect(f.anzahlAktiv, 2);
    });

    test('Barrierefrei ab 4 von 5', () {
      const f = KarteFilter(merkmale: {Merkmal.barrierefrei});
      expect(f.passt(_e('a', barriere: 4)), isTrue);
      expect(f.passt(_e('a', barriere: 3)), isFalse);
      expect(f.passt(_e('a')), isFalse);
    });

    test('Zählung: Sektionen je 1, Merkmale einzeln', () {
      const f = KarteFilter(
        arten: {EintragArt.ort},
        dauer: DauerBereich.bis1Std,
        laenge: LaengeBereich.bis3km,
        merkmale: {Merkmal.wc, Merkmal.einkehr},
      );
      expect(f.anzahlAktiv, 5);
    });
  });

  group('Menge M', () {
    final alle = [
      _e('nah', km: 5),
      _e('mittel', km: 15),
      _e('fern', km: 60, gebiet: Gebiet.moor),
    ];

    test('Umkreis 15 Min', () {
      final m = berechneMenge(alle, bezug: _bezug, umkreis: Umkreis.min15);
      expect(_ids(m), ['nah']);
    });
    test('Umkreis 30 Min', () {
      final m = berechneMenge(alle, bezug: _bezug);
      expect(_ids(m).toSet(), {'nah', 'mittel'});
    });
    test('egal', () {
      final m = berechneMenge(alle, bezug: _bezug, umkreis: Umkreis.egal);
      expect(m.length, 3);
    });
    test('Gebiet', () {
      final m = berechneMenge(
        alle,
        bezug: _bezug,
        umkreis: Umkreis.egal,
        gebiet: Gebiet.moor,
      );
      expect(_ids(m), ['fern']);
    });
    test('ohne Bezugspunkt: kein Umkreis, Anfahrt null', () {
      final m = berechneMenge(alle, bezug: null);
      expect(m.length, 3);
      expect(m.every((t) => t.anfahrtMin == null), isTrue);
    });
  });

  group('Sortierung', () {
    test('Anfahrt, bei Gleichstand Name', () {
      final m = [
        Treffer(_e('b'), 10),
        Treffer(_e('a'), 10),
        Treffer(_e('c'), 5),
      ];
      expect(_ids(sortiere(m, Sortierung.anfahrt)), ['c', 'a', 'b']);
    });

    test('Dauer: ohne Dauer ans Ende, dort nach Anfahrt', () {
      final m = [
        Treffer(_e('ort', art: EintragArt.ort), 5),
        Treffer(_e('lang', dauer: 120), 3),
        Treffer(_e('kurz', dauer: 30), 20),
        Treffer(_e('ort2', art: EintragArt.ort), 2),
      ];
      expect(_ids(sortiere(m, Sortierung.dauer)), [
        'kurz',
        'lang',
        'ort2',
        'ort',
      ]);
    });

    test('Kinderfreundlichste: absteigend, ohne Wert ans Ende', () {
      final m = [
        Treffer(_e('x', kinder: 3), 1),
        Treffer(_e('y', kinder: 5), 9),
        Treffer(_e('z'), 2),
        Treffer(_e('w', kinder: 5), 4),
      ];
      expect(_ids(sortiere(m, Sortierung.kinder)), ['w', 'y', 'x', 'z']);
    });
  });

  group('Vorschläge', () {
    final heute = DateTime(2026, 7, 10);
    List<Treffer> mk(List<(String, Gebiet, int)> l) => [
      for (final (id, g, min) in l) Treffer(_e(id, gebiet: g), min),
    ];

    test('je Gebiet das Nächste, die 4 nächsten, nach Anfahrt', () {
      final m = mk([
        ('w1', Gebiet.wald, 5),
        ('w2', Gebiet.wald, 6),
        ('m1', Gebiet.moor, 8),
        ('h1', Gebiet.heide, 12),
        ('k1', Gebiet.kueste, 20),
        ('s1', Gebiet.wasser, 25),
      ]);
      expect(_ids(vorschlaege(m, heute)), ['w1', 'm1', 'h1', 'k1']);
    });

    test('weniger als 4 Gebiete: mit den nächsten Übrigen auffüllen', () {
      final m = mk([
        ('w1', Gebiet.wald, 5),
        ('w2', Gebiet.wald, 6),
        ('w3', Gebiet.wald, 7),
        ('m1', Gebiet.moor, 8),
        ('m2', Gebiet.moor, 9),
      ]);
      expect(_ids(vorschlaege(m, heute)), ['w1', 'w2', 'w3', 'm1']);
    });

    test('Orte außerhalb der Saison werden übersprungen', () {
      final m = [
        Treffer(
          _e(
            'o',
            art: EintragArt.ort,
            gebiet: Gebiet.wasser,
            saison: const Saison(11, 2),
          ),
          3,
        ),
        ...mk([
          ('w1', Gebiet.wald, 5),
          ('m1', Gebiet.moor, 8),
          ('h1', Gebiet.heide, 12),
          ('k1', Gebiet.kueste, 20),
          ('hof', Gebiet.hof, 30),
        ]),
      ];
      expect(_ids(vorschlaege(m, heute)), ['w1', 'm1', 'h1', 'k1']);
    });

    test('höchstens 4 in M: alle, auch außerhalb der Saison', () {
      final m = [
        Treffer(_e('o', art: EintragArt.ort, saison: const Saison(11, 2)), 3),
        Treffer(_e('w'), 5),
      ];
      expect(_ids(vorschlaege(m, heute)), ['o', 'w']);
    });
  });

  group('Leerzustand', () {
    final alle = [
      _e('nah', km: 5, gebiet: Gebiet.wald),
      _e('mittel', km: 15, gebiet: Gebiet.moor),
      _e('fern', km: 30, gebiet: Gebiet.heide),
    ];

    test('E6 hat Vorrang: ohne Filter gäbe es Treffer', () {
      final f = bestimmeLeerFall(
        alle,
        bezug: _bezug,
        umkreis: Umkreis.min30,
        gebiet: Gebiet.heide,
        filter: KarteFilter.standard,
      );
      expect(f.art, LeerArt.filter);
    });

    test('E5: nichts im Umkreis, aber im größeren', () {
      final f = bestimmeLeerFall(
        [alle[2]],
        bezug: _bezug,
        umkreis: Umkreis.min30,
        gebiet: null,
        filter: KarteFilter.standard,
      );
      expect(f.art, LeerArt.umkreis);
      expect(f.erweitern, Umkreis.min60);
      expect(f.naechster!.eintrag.id, 'fern');
    });

    test('E7: nichts innerhalb 1 Std', () {
      final f = bestimmeLeerFall(
        [_e('weit', km: 200)],
        bezug: _bezug,
        umkreis: Umkreis.min15,
        gebiet: null,
        filter: KarteFilter.standard,
      );
      expect(f.art, LeerArt.region);
    });
  });

  group('Texte', () {
    test('Merkmale in fester Reihenfolge, nur Wahres', () {
      final e = _e(
        'a',
        rundkurs: true,
        kinderwagen: true,
        parkplatz: true,
        wc: true,
        einkehr: true,
        barriere: 4,
      );
      expect(
        merkmaleText(e),
        'Rundkurs, Kinderwagen, Parkplatz, WC, Einkehr, Barrierefrei',
      );
      expect(merkmaleText(_e('b', barriere: 3)), '');
    });

    test('Abschnittszeile', () {
      expect(listenAnzahlText(1, KarteFilter.standard), '1 Ergebnis');
      expect(listenAnzahlText(7, KarteFilter.standard), '7 Wege und Orte');
      expect(
        listenAnzahlText(7, const KarteFilter(arten: {EintragArt.weg})),
        '7 Wege',
      );
    });

    test('Anfahrt-Zelle', () {
      expect(anfahrtZelle(null), '–');
      expect(anfahrtZelle(25), 'ca. 25 Min');
    });

    test('Umkreistexte', () {
      expect(Umkreis.min30.text, 'bis 30 Min Anfahrt');
      expect(Umkreis.min60.text, 'bis 1 Std Anfahrt');
      expect(Umkreis.egal.text, 'alle Entfernungen');
    });
  });

  test('Copy: jeder im Code genutzte Key existiert', () {
    final key = RegExp(r"""\bkt\(\s*'([^'$]+)'""");
    final fehlend = <String>{};
    final dirs = [
      Directory('lib/features/nearby_trails'),
      Directory('lib/features/trail/presentation/map'),
    ];
    for (final dir in dirs) {
      if (!dir.existsSync()) continue;
      for (final f in dir.listSync(recursive: true).whereType<File>()) {
        if (!f.path.endsWith('.dart')) continue;
        for (final m in key.allMatches(f.readAsStringSync())) {
          final k = m.group(1)!;
          if (!karteTexte.containsKey(k)) fehlend.add('$k (${f.path})');
        }
      }
    }
    expect(fehlend, isEmpty);
  });
}
