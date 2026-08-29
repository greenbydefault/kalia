import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/features/species/data/species_resolver.dart';
import 'package:lehrpfad_app/features/species/data/supabase_species_repository.dart';
import 'package:lehrpfad_app/features/species/domain/species.dart';
import 'package:lehrpfad_app/features/species/domain/species_beziehung.dart';

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

  test('profil fields parse from seed json', () {
    final s = Species.fromJson({
      'id': 'biber',
      'nameDe': 'Biber',
      'nameLat': 'Castor fiber',
      'kategorie': 'fauna',
      'kurztext': 'Text',
      'gruppe': 'saeugetiere',
      'seltenheit': 'selten',
      'gefahr': 2,
      'nahrung': ['Rinde', 'Zweige'],
      'taxonomie': {
        'reich': 'Animalia',
        'stamm': 'Chordata',
        'klasse': 'Mammalia',
        'ordnung': 'Rodentia',
        'familie': 'Castoridae',
      },
      'masse': [
        {'key': 'laenge', 'wert': '80–100 cm'},
      ],
      'merkmale': ['pelzig', 'sozial'],
      'beziehungen': [
        {'typ': 'frisst', 'speciesId': 'schwarzerle', 'kurztext': 'Nagt Rinde.'},
      ],
    });
    expect(s.hasProfil, isTrue);
    expect(s.gruppe, 'saeugetiere');
    expect(s.seltenheit, 'selten');
    expect(s.gefahr, 2);
    expect(s.nahrung, ['Rinde', 'Zweige']);
    expect(s.taxonomie['familie'], 'Castoridae');
    expect(s.masse.single.key, 'laenge');
    expect(s.masse.single.wert, '80–100 cm');
    expect(s.merkmalIds, ['pelzig', 'sozial']);
    expect(s.beziehungen.single.typ, 'frisst');
    expect(s.beziehungen.single.toSpeciesId, 'schwarzerle');
  });

  test('geraete has no profil', () {
    final s = Species.fromJson({
      'id': 'quellsteine-wasserdueisen',
      'nameDe': 'Quellsteine mit Wasserdüsen',
      'nameLat': '',
      'kategorie': 'geraete',
      'kurztext': 'Wasser aus Steinen',
      'iconKey': 'geraet',
    });
    expect(s.hasProfil, isFalse);
    expect(s.gruppe, isEmpty);
    expect(s.merkmalIds, isEmpty);
  });

  test('rowToJson maps profil snake_case to seed format', () {
    final json = SupabaseSpeciesRepository.rowToJson({
      'id': 'biber',
      'name_de': 'Biber',
      'name_lat': 'Castor fiber',
      'kategorie': 'fauna',
      'kurztext': 'Text',
      'content': <String, dynamic>{},
      'aliases': <String>[],
      'gruppe': 'saeugetiere',
      'seltenheit': 'selten',
      'gefahr': 2,
      'nahrung': ['Rinde'],
      'tax_reich': 'Animalia',
      'tax_stamm': 'Chordata',
      'tax_klasse': 'Mammalia',
      'tax_ordnung': 'Rodentia',
      'tax_familie': 'Castoridae',
      'masse': [
        {'key': 'laenge', 'wert': '80–100 cm'},
      ],
      'species_merkmale': [
        {'merkmal_id': 'pelzig'},
      ],
      'species_beziehungen': [
        {'typ': 'frisst', 'to_species_id': 'schwarzerle', 'name_de': '', 'name_lat': '', 'kurztext': 'Nagt Rinde.'},
      ],
    });
    final s = Species.fromJson(json);
    expect(s.gruppe, 'saeugetiere');
    expect(s.taxonomie['familie'], 'Castoridae');
    expect(s.merkmalIds, ['pelzig']);
    expect(s.beziehungen.single.toSpeciesId, 'schwarzerle');
  });

  test('SpeciesBeziehung.fromJson akzeptiert speciesId und toSpeciesId', () {
    final alt = SpeciesBeziehung.fromJson({
      'typ': 'frisst',
      'speciesId': 'schwarzerle',
      'kurztext': 'Nagt Rinde.',
    });
    expect(alt.toSpeciesId, 'schwarzerle');
    expect(alt.isKatalogArt, isTrue);

    final neu = SpeciesBeziehung.fromJson({
      'typ': 'frisst',
      'toSpeciesId': 'schwarzerle',
      'kurztext': 'Nagt Rinde.',
    });
    expect(neu.toSpeciesId, 'schwarzerle');
    expect(neu.toJson()['toSpeciesId'], 'schwarzerle');
    expect(neu.toJson().containsKey('speciesId'), isFalse);

    final frei = SpeciesBeziehung.fromJson({
      'typ': 'frisst',
      'nameDe': 'Mücke',
    });
    expect(frei.toSpeciesId, isNull);
    expect(frei.isKatalogArt, isFalse);
  });
}
