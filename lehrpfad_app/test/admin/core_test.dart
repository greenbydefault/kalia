import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/admin/core/admin_repository.dart';
import 'package:lehrpfad_app/admin/core/autosave.dart';
import 'package:lehrpfad_app/admin/core/field_spec.dart';
import 'package:lehrpfad_app/core/media/media_url.dart';

void main() {
  group('slugify', () {
    test('Umlaute und Sonderzeichen', () {
      expect(slugify('Kranich der Ostsee'), 'kranich-der-ostsee');
      expect(slugify('  Grüner Frosch! '), 'gruener-frosch');
      expect(slugify('Fuß'), 'fuss');
      expect(slugify('***'), '');
    });
  });

  group('FieldLimit', () {
    test('Zeichen: zu lang und zu kurz warnen, leer nicht', () {
      const l = FieldLimit(min: 5, max: 10);
      expect(l.warn(''), isNull);
      expect(l.warn('abc'), '3 von min. 5 Zeichen');
      expect(l.warn('abcdefghijk'), '11 von max. 10 Zeichen');
      expect(l.warn('abcdef'), isNull);
    });

    test('Wörter', () {
      const l = FieldLimit(max: 3, unit: LimitUnit.words);
      expect(l.measure('  ein  zwei\ndrei '), 3);
      expect(l.warn('a b c d'), '4 von max. 3 Wörter');
    });
  });

  group('MediaUrl', () {
    const base = 'https://x.supabase.co';
    test('storage: wird zur öffentlichen URL', () {
      expect(
        MediaUrl.resolve(
          'storage:catalog-media/species/kranich/audio.mp3',
          supabaseUrl: '$base/',
        ),
        '$base/storage/v1/object/public/catalog-media/species/kranich/audio.mp3',
      );
    });

    test('http bleibt, Asset ist null', () {
      expect(MediaUrl.resolve('https://a.b/c.mp3'), 'https://a.b/c.mp3');
      expect(MediaUrl.resolve('assets/audio/x.mp3'), isNull);
      expect(MediaUrl.isNetwork('assets/audio/x.mp3'), isFalse);
    });

    test('parseStorage', () {
      final p = MediaUrl.parseStorage('storage:catalog-media/a/b.avif');
      expect(p?.bucket, 'catalog-media');
      expect(p?.object, 'a/b.avif');
      expect(MediaUrl.parseStorage('assets/a.png'), isNull);
    });
  });

  group('AutosaveController', () {
    test('bündelt Änderungen zu einem Patch und schreibt jsonb-Keys', () async {
      final saved = <Map<String, dynamic>>[];
      final hub = AutosaveHub();
      final row = <String, dynamic>{
        'name_de': 'Frosch',
        'content': {'hook': 'alt'},
      };
      final c = AutosaveController(
        row: row,
        hub: hub,
        delay: const Duration(milliseconds: 10),
        save: (patch) async => saved.add(patch),
      );
      const name = FieldSpec('name_de', 'Name', FieldKind.text);
      const hook = FieldSpec('hook', 'Hook', FieldKind.text, json: 'content');
      c.set(name, 'Teichfrosch');
      c.set(name, 'Teichfrosch 2');
      c.set(hook, 'neu');
      expect(hub.state, SaveState.dirty);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(saved, hasLength(1));
      expect(saved.single['name_de'], 'Teichfrosch 2');
      expect(saved.single['content'], {'hook': 'neu'});
      expect(hub.state, SaveState.saved);
      c.dispose();
    });

    test('leerer jsonb-Wert entfernt den Key', () async {
      final saved = <Map<String, dynamic>>[];
      final row = <String, dynamic>{
        'content': {'hook': 'x', 'hinweis': 'y'},
      };
      final c = AutosaveController(row: row, save: (p) async => saved.add(p));
      c.set(
        const FieldSpec('hook', 'Hook', FieldKind.text, json: 'content'),
        '',
      );
      await c.flush();
      expect(saved.single['content'], {'hinweis': 'y'});
      c.dispose();
    });

    test('Fehler: Patch bleibt für den nächsten Versuch', () async {
      var fail = true;
      final saved = <Map<String, dynamic>>[];
      final hub = AutosaveHub();
      final c = AutosaveController(
        row: <String, dynamic>{},
        hub: hub,
        save: (p) async {
          if (fail) throw Exception('offline');
          saved.add(p);
        },
      );
      c.set(const FieldSpec('a', 'A', FieldKind.text), '1');
      await c.flush();
      expect(hub.state, SaveState.error);
      expect(c.hasPending, isTrue);
      fail = false;
      await c.flush();
      expect(saved.single['a'], '1');
      expect(hub.state, SaveState.saved);
      c.dispose();
    });
  });
}
