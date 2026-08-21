import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/features/species/data/species_resolver.dart';
import 'package:lehrpfad_app/features/species/data/supabase_species_repository.dart';
import 'package:lehrpfad_app/features/species/domain/species.dart';

void main() {
  late SpeciesResolver resolver;

  setUpAll(() {
    final raw = File('assets/seed/species.json').readAsStringSync();
    final catalog = (jsonDecode(raw) as List)
        .map((e) => Species.fromJson(e as Map<String, dynamic>))
        .toList();
    resolver = SpeciesResolver(catalog);
  });

  test('resolves nameDe and aliases, dedupes', () {
    final list = resolver.resolve([
      'Sumpf-Iris',
      'Moosjungfer',
      'Rotbauchunke',
      'Sumpf-Schwertlilie',
    ]);
    expect(list.map((s) => s.id).toList(), [
      'sumpf-schwertlilie',
      'grosse-moosjungfer',
      'rotbauchunke',
    ]);
  });

  test('skips unknown names', () {
    final list = resolver.resolve(['Unbekanntes Tier', 'Biber']);
    expect(list.single.id, 'biber');
  });

  test('rowToJson maps snake_case to seed format', () {
    final json = SupabaseSpeciesRepository.rowToJson({
      'id': 'biber',
      'name_de': 'Biber',
      'name_lat': 'Castor fiber',
      'kategorie': 'fauna',
      'kurztext': 'Text',
      'content': {
        'hook': 'Hier formt jemand den Fluss um – oft siehst du die Baustelle zuerst.',
        'erkennung': ['frische Nagespuren an Weide', 'Damm oder Burg am Ufer'],
        'lebensraum': 'An Fließen und Ufern im Spreewald.',
        'funFacts': ['Baut nachts', 'Zähne wie eine Säge'],
        'hinweis': '',
        'hoertext': 'x ' * 95,
      },
      'aliases': <String>[],
      'image_path': null,
      'image_credit': '',
      'audio_path': 'assets/audio/species/biber.opus',
    });
    final s = Species.fromJson(json);
    expect(s.id, 'biber');
    expect(s.nameDe, 'Biber');
    expect(s.isFauna, isTrue);
    expect(s.kurztext, 'Text');
    expect(s.content.hook, contains('Fluss'));
    expect(s.displayHook, contains('Fluss'));
    expect(s.audioPath, 'assets/audio/species/biber.opus');
  });

  test('geraete uses icon catalog via iconKey', () {
    final s = Species.fromJson({
      'id': 'quellsteine-wasserdueisen',
      'nameDe': 'Quellsteine mit Wasserdüsen',
      'nameLat': '',
      'kategorie': 'geraete',
      'kurztext': 'Wasser aus Steinen',
      'iconKey': 'geraet',
    });
    expect(s.isGeraet, isTrue);
    expect(s.kategorieLabel, 'Geräte');
    expect(s.displayIconEintrag.label, 'Gerät');
  });

  test('displayHook falls back to kurztext', () {
    final s = Species.fromJson({
      'id': 'x',
      'nameDe': 'X',
      'nameLat': '',
      'kategorie': 'flora',
      'kurztext': 'Alter Text',
      'content': <String, dynamic>{},
    });
    expect(s.displayHook, 'Alter Text');
  });
}
