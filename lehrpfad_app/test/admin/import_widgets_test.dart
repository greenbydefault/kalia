import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/admin/core/field_spec.dart';
import 'package:lehrpfad_app/admin/import/import_frames.dart';
import 'package:lehrpfad_app/admin/import/import_models.dart';
import 'package:lehrpfad_app/admin/import/import_scope.dart';
import 'package:lehrpfad_app/admin/import/proposal_view.dart';

class _Actions implements ImportReviewActions {
  final calls = <String>[];

  @override
  Future<void> ack(ReportEntry e) async => calls.add('ack:${e.code}');
  @override
  Future<void> addStation() async => calls.add('station');
  @override
  Future<void> applyFix(ReportEntry e) async => calls.add('fix:${e.code}');
  @override
  Future<void> ask(ReportEntry e) async => calls.add('ask:${e.code}');
  @override
  Future<void> overrideEntry(ReportEntry e) async => calls.add('override:${e.code}');
  @override
  Future<void> resolveDuplicate(ReportEntry e) async => calls.add('dup:${e.code}');
  @override
  Future<void> resolveSpecies(ReportEntry e) async => calls.add('art:${e.code}');
}

ReportEntry _e(Map<String, dynamic> j) => ReportEntry.fromJson(j);

ImportMessages _messages() =>
    ImportMessages.parse(File('import_worker/messages.json').readAsStringSync());

Widget _host(
  List<ReportEntry> report,
  _Actions actions,
  Widget Function() child, {
  Set<String> locked = const {},
}) {
  final job = ImportJob.fromRow({
    'id': 'j',
    'file_name': 'a.zip',
    'file_hash': 'h',
    'trail_id': 'a',
    'status': 'bereit',
    'modus': 'import',
  });
  final data = ImportScopeData(
    job: job,
    messages: _messages(),
    states: FieldStates(
      report: report,
      locked: locked,
      fieldMeta: const {},
      row: const {'beschreibung': 'text', 'name': 'Pfad'},
    ),
    controller: ImportEditorController(),
    actions: actions,
  );
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: ImportScope(data: data, child: child()),
      ),
    ),
  );
}

void main() {
  const spec = FieldSpec('beschreibung', 'Beschreibung', FieldKind.longText);

  testWidgets('Kürzungsvorschlag übernehmen löst applyFix aus', (tester) async {
    final a = _Actions();
    await tester.pumpWidget(
      _host(
        [
          _e({
            'code': 'TEXT_LAENGE',
            'severity': 'warnung',
            'feld': 'beschreibung',
            'wert': 870,
            'vorschlag': 'kurz',
            'params': {'laenge': 870, 'min': 400, 'max': 650},
          }),
        ],
        a,
        () => const ImportFieldFrame(spec: spec, child: Text('FELD')),
      ),
    );
    expect(find.text('Prüfen'), findsOneWidget);
    expect(find.text('Text hat die falsche Länge'), findsOneWidget);
    await tester.tap(find.text('Kürzungsvorschlag übernehmen'));
    await tester.pump();
    expect(a.calls, ['fix:TEXT_LAENGE']);
  });

  testWidgets('Übersteuerbar zeigt Übersteuern, Warnung Erledigt', (tester) async {
    final a = _Actions();
    await tester.pumpWidget(
      _host(
        [
          _e({
            'code': 'STATIONEN_MIN',
            'severity': 'uebersteuerbar',
            'feld': 'beschreibung',
            'params': {'anzahl': 1, 'min': 3, 'grund': 'luecke'},
          }),
          _e({'code': 'QUELLE_FEHLT', 'severity': 'warnung', 'feld': 'beschreibung'}),
        ],
        a,
        () => const ImportFieldFrame(spec: spec, child: Text('FELD')),
      ),
    );
    expect(find.text('Klären'), findsOneWidget);
    await tester.tap(find.text('Übersteuern …'));
    await tester.pump();
    await tester.tap(find.text('Erledigt'));
    await tester.pump();
    expect(a.calls, ['override:STATIONEN_MIN', 'ack:QUELLE_FEHLT']);
  });

  testWidgets('Fehlendes Pflichtfeld heißt „Fehlt“, Frage geht immer', (tester) async {
    final a = _Actions();
    await tester.pumpWidget(
      _host(
        [_e({'code': 'PFLICHT', 'severity': 'hart', 'feld': 'beschreibung'})],
        a,
        () => const ImportFieldFrame(spec: spec, child: Text('FELD')),
      ),
    );
    expect(find.text('Fehlt'), findsOneWidget);
    await tester.tap(find.text('Frage stellen'));
    await tester.pump();
    expect(a.calls, ['ask:PFLICHT']);
  });

  testWidgets('Gesperrtes Feld zeigt Hinweis', (tester) async {
    await tester.pumpWidget(
      _host(
        const [],
        _Actions(),
        () => const ImportFieldFrame(spec: spec, child: Text('FELD')),
        locked: {'beschreibung'},
      ),
    );
    expect(find.text('Gesperrt (im CMS bearbeitet)'), findsOneWidget);
  });

  testWidgets('Ohne Import-Scope bleibt das Feld unverändert', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ImportFieldFrame(spec: spec, child: Text('FELD')),
        ),
      ),
    );
    expect(find.text('FELD'), findsOneWidget);
    expect(find.text('OK'), findsNothing);
  });

  testWidgets('Vorschlag: gesperrte Felder sind vorab nicht angehakt', (tester) async {
    List<String>? applied = const ['unset'];
    final job = ImportJob.fromRow({
      'id': 'j',
      'file_name': 'a.zip',
      'file_hash': 'h',
      'trail_id': 'a',
      'status': 'vorschlag',
      'modus': 'import',
      'proposal': {
        'felder': {
          'kreis': {'alt': 'A', 'neu': 'B', 'gesperrt': false},
          'beschreibung': {'alt': 'x', 'neu': 'y', 'gesperrt': true},
        },
        'bloecke': {
          'stationen': {
            'alt': 3,
            'neu': 4,
            'aenderungen': ['neu: 4'],
          },
        },
        'gesperrt': ['beschreibung'],
      },
    });
    await tester.binding.setSurfaceSize(const Size(900, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProposalView(
            job: job,
            messages: _messages(),
            onApply: (t) async => applied = t,
            onReject: () async {},
          ),
        ),
      ),
    );
    expect(find.text('Auswahl annehmen (2)'), findsOneWidget);
    expect(find.text('im CMS bearbeitet'), findsOneWidget);
    await tester.tap(find.text('Auswahl annehmen (2)'));
    await tester.pump();
    expect(applied, unorderedEquals(['kreis', 'stationen']));
  });
}
