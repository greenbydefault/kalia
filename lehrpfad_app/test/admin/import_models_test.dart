import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/admin/import/import_models.dart';

ReportEntry _e(
  String code,
  Severity s,
  String feld, {
  Map<String, dynamic> params = const {},
  dynamic wert,
  dynamic vorschlag,
  String status = 'offen',
  String? reason,
}) => ReportEntry.fromJson({
  'code': code,
  'severity': s.name,
  'feld': feld,
  'params': params,
  'wert': wert,
  'vorschlag': vorschlag,
  'status': status,
  if (reason != null) 'override': {'reason': reason},
});

void main() {
  group('Report', () {
    test('Blocker zählen nur offene harte und nicht übersteuerte Meldungen', () {
      final r = [
        _e('PFLICHT', Severity.hart, 'name'),
        _e('STATIONEN_MIN', Severity.uebersteuerbar, 'stationen'),
        _e('STATIONEN_MIN', Severity.uebersteuerbar, 'stationen', reason: 'Fläche'),
        _e('TEXT_LAENGE', Severity.warnung, 'beschreibung'),
        _e('QUELLE_FEHLT', Severity.warnung, 'abschnitt6', status: 'erledigt'),
        _e('PFLICHT', Severity.hart, 'typ', status: 'erledigt'),
      ];
      final b = blockersOf(r);
      expect(b.hart, 1);
      expect(b.uebersteuerbar, 1);
      expect(warningCount(r), 1);
    });

    test('Feldschlüssel: Station, Abschnitt, Start, Fläche', () {
      expect(_e('X', Severity.warnung, 'stationen[3]').anzeigeKey, 'stationen');
      expect(_e('X', Severity.warnung, 'stationen[3]').index, 3);
      expect(_e('X', Severity.warnung, 'bilder[2]').anzeigeKey, 'bilder');
      expect(_e('X', Severity.warnung, 'abschnitt6').baseFeld, 'abschnitt');
      expect(_e('X', Severity.warnung, 'start_lon').anzeigeKey, 'start_lat');
      expect(_e('X', Severity.warnung, 'area').anzeigeKey, 'route');
    });

    test('Job: Anlegen nur ohne Blocker und im richtigen Status', () {
      ImportJob job(String status, List<Map<String, dynamic>> report) =>
          ImportJob.fromRow({
            'id': 'j1',
            'file_name': 'a.zip',
            'file_hash': 'h',
            'trail_id': 'a',
            'status': status,
            'modus': 'import',
            'report': report,
          });
      final clean = job('bereit', const []);
      expect(clean.canPublish, isTrue);
      expect(job('wartet', const []).canPublish, isFalse);
      expect(job('wartet', const []).pruefend, isTrue);
      expect(
        job('bereit', [
          {'code': 'PFLICHT', 'severity': 'hart', 'feld': 'name', 'status': 'offen'},
        ]).canPublish,
        isFalse,
      );
      expect(job('angelegt', const []).canPublish, isFalse);
    });

    test('Tabs sortieren Status', () {
      expect(ImportTab.imImport.accepts(ImportStatus.vorschlag), isTrue);
      expect(ImportTab.klaerung.accepts(ImportStatus.wartetAufKlaerung), isTrue);
      expect(ImportTab.archiv.accepts(ImportStatus.angelegt), isTrue);
      expect(ImportTab.fehlgeschlagen.accepts(ImportStatus.bereit), isFalse);
    });
  });

  group('FieldStates', () {
    FieldStates states(List<ReportEntry> r, {Set<String> locked = const {}}) =>
        FieldStates(
          report: r,
          locked: locked,
          fieldMeta: const {
            'hoertext': {'quelle': 'ki'},
          },
          row: const {'name': 'Pfad', 'kreis': '', 'typ': 'wald', 'hoertext': 'x'},
        );

    test('rot vor gelb, gefüllt = grün, gesperrt = grau', () {
      final s = states(
        [
          _e('PFLICHT', Severity.hart, 'kreis'),
          _e('TEXT_LAENGE', Severity.warnung, 'name'),
        ],
        locked: {'typ'},
      );
      expect(s.of('kreis').tone, FieldTone.error);
      expect(s.of('name').tone, FieldTone.warn);
      expect(s.of('typ').tone, FieldTone.locked);
      expect(s.of('typ').locked, isTrue);
      expect(s.of('hoertext').tone, FieldTone.info);
      expect(s.of('hoertext').fromKi, isTrue);
      expect(s.of('nix').tone, FieldTone.none);
    });

    test('mehrere Meldungen: der schwerste Ton gewinnt', () {
      final s = states([
        _e('QUELLE_FEHLT', Severity.warnung, 'name'),
        _e('PFLICHT', Severity.hart, 'name'),
        _e('FORM', Severity.warnung, 'name'),
      ]);
      expect(s.of('name').tone, FieldTone.error);
    });

    test('Formkorrektur ist blau, übersteuerte Meldung ebenfalls', () {
      final s = states([
        _e('FORM', Severity.warnung, 'name', vorschlag: 'Pfad'),
        _e('STATIONEN_MIN', Severity.uebersteuerbar, 'stationen', reason: 'Fläche'),
      ]);
      expect(s.of('name').tone, FieldTone.info);
      expect(s.of('stationen').tone, FieldTone.info);
    });
  });

  group('ImportMessages (Parität mit import_worker/messages.py)', () {
    late ImportMessages m;
    setUpAll(() {
      m = ImportMessages.parse(File('import_worker/messages.json').readAsStringSync());
    });

    test('Text zu lang', () {
      final r = m.render(
        _e(
          'TEXT_LAENGE',
          Severity.warnung,
          'beschreibung',
          wert: 870,
          params: {'laenge': 870, 'min': 400, 'max': 650},
        ),
      );
      expect(r.titel, 'Text hat die falsche Länge');
      expect(r.was, 'Beschreibung hat 870 Zeichen (erlaubt: 400 bis 650).');
    });

    test('Hörtext zählt Wörter', () {
      final r = m.render(
        _e(
          'TEXT_LAENGE',
          Severity.warnung,
          'hoertext',
          wert: 64,
          params: {'laenge': 64, 'min': 70, 'max': 110, 'einheit': 'Wörter'},
        ),
      );
      expect(r.was, 'Hörtext hat 64 Wörter (erlaubt: 70 bis 110).');
    });

    test('Dublette und Stationen', () {
      final d = m.render(
        _e(
          'DUPLIKAT_NAH',
          Severity.warnung,
          'id',
          wert: 'x',
          params: {'id': 'x', 'name': 'Y', 'meter': 80, 'aehnlichkeit': 0.9},
        ),
      );
      expect(d.was, '"Y" (x) startet nur 80 m entfernt.');
      final s = m.render(
        _e(
          'STATIONEN_MIN',
          Severity.uebersteuerbar,
          'stationen',
          params: {'anzahl': 1, 'min': 3, 'grund': 'luecke'},
        ),
      );
      expect(s.titel, 'Zu wenige Stationen');
      expect(
        s.was,
        'Der Pfad hat 1 Stationen (luecke). Gebraucht werden mindestens 3, lückenlos ab 1 nummeriert.',
      );
    });

    test('Feldlabels', () {
      expect(m.feldLabel('stationen[3]'), 'Station 3');
      expect(m.feldLabel('abschnitt2'), 'Abschnitt 2');
      expect(m.feldLabel('id'), 'ID');
      expect(m.feldLabel('unbekannt'), 'unbekannt');
    });

    test('jeder Code hat Titel, Was, Warum, Wie', () {
      for (final code in ['SCHEMA', 'PFLICHT', 'BILD_FEHLT', 'ART_UNBEKANNT']) {
        final r = m.render(_e(code, Severity.warnung, 'name'));
        expect(r.titel, isNotEmpty, reason: code);
        expect(r.was, isNotEmpty, reason: code);
        expect(r.warum, isNotEmpty, reason: code);
        expect(r.wie, isNotEmpty, reason: code);
      }
    });
  });
}
