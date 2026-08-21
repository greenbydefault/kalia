import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/features/trail/data/supabase_trail_repository.dart';
import 'package:lehrpfad_app/features/trail/domain/trail.dart';

void main() {
  test('trailRowToJson mappt eine Supabase-Row auf das Seed-Format', () {
    final row = <String, dynamic>{
      'id': 'von-moor-zu-moor',
      'name': 'Von Moor zu Moor',
      'typ': 'moor',
      'kurzbeschreibung': 'Rundweg durch Moore',
      'beschreibung': 'Neben dem Seenreichtum ...',
      'laenge_km': 11.6,
      'dauer_min': 175,
      'rundkurs': true,
      'markierung': 'Grün-blauer Punkt auf weißem Grund',
      'betreiber': 'Naturpark Stechlin-Ruppiner Land',
      'region': 'Menz, Stechlin, Landkreis Oberhavel',
      'website': null,
      'eintritt': true,
      'eintritt_preise': '1,50 € ab 2 Jahren',
      'oeffnungszeiten': '11–18 Uhr',
      'besuchshinweise': 'Futter am Eingang',
      'anreise': 'RE 5 ab Berlin Hbf',
      'start_name': 'NaturParkHaus Stechlin, Menz',
      'arten': ['Torfmoos', 'Wollgras'],
      'tags': ['kinderfreundlich', 'rollstuhltauglich'],
      'route': [
        [53.103808, 13.049388],
        [53.103818, 13.049463],
      ],
      'stations': [
        {
          'osm_id': 886115799,
          'lat': 53.1142557,
          'lon': 13.0368469,
          'km': 1.86,
          'reihenfolge': 1,
          'titel': 'Grubitzwisch',
          'thema': 'Aufbruch – ein Moor kehrt zurück',
          'kurztext': 'Quiz zur Moorentstehung',
          'erlebnisse': ['quiz', 'steg'],
          'barrierefrei': false,
          'steckbrief': {
            'groesseHa': 3.8,
            'alterJahre': 13000,
            'tiefeM': 4.25,
            'lebenselixier': 'Wasser',
            'werdegang': 'vom See – zum Verlandungsmoor',
          },
        },
      ],
      'amenities': [
        {
          'osm_id': 1120014122,
          'lat': 53.1039,
          'lon': 13.0495,
          'kategorie': 'parking',
          'name': null,
        },
      ],
    };

    final trail = Trail.fromJson(SupabaseTrailRepository.trailRowToJson(row));

    expect(trail.id, 'von-moor-zu-moor');
    expect(trail.laengeKm, 11.6);
    expect(trail.dauerMin, 175);
    expect(trail.rundkurs, isTrue);
    expect(trail.arten, ['Torfmoos', 'Wollgras']);
    expect(trail.tags, ['kinderfreundlich', 'rollstuhltauglich']);
    expect(trail.route, hasLength(2));
    expect(trail.stationen, hasLength(1));
    expect(trail.stationen.first.osmId, 886115799);
    expect(trail.stationen.first.steckbrief?.groesseHa, 3.8);
    expect(trail.amenities.single.kategorie, 'parking');
    expect(trail.amenities.single.name, isNull);
    expect(trail.eintritt, isTrue);
    expect(trail.eintrittPreise, '1,50 € ab 2 Jahren');
    expect(trail.oeffnungszeiten, '11–18 Uhr');
    expect(trail.besuchshinweise, 'Futter am Eingang');
  });

  test('toJson/fromJson-Roundtrip über den echten Seed-Datensatz', () {
    final raw = File('assets/seed/trail.json').readAsStringSync();
    final original = Trail.fromJson(jsonDecode(raw) as Map<String, dynamic>);

    final roundtrip = Trail.fromJson(
      jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
    );

    expect(roundtrip.id, original.id);
    expect(roundtrip.route.length, original.route.length);
    expect(roundtrip.stationen.length, original.stationen.length);
    expect(
      roundtrip.stationen.first.steckbrief?.tiefeM,
      original.stationen.first.steckbrief?.tiefeM,
    );
    expect(roundtrip.amenities.length, original.amenities.length);
  });
}
