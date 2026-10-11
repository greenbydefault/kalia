import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:lehrpfad_app/features/nearby/data/nearby_zeiten_repository.dart';
import 'package:lehrpfad_app/features/nearby/data/supabase_nearby_zeiten_repository.dart';
import 'package:lehrpfad_app/features/nearby/domain/nearby.dart';
import 'package:lehrpfad_app/features/nearby/domain/nearby_place.dart';
import 'package:lehrpfad_app/features/trail/domain/trail.dart';

NearbyPlace place(String id, String kategorie) => NearbyPlace(
  id: id,
  name: id,
  kategorie: kategorie,
  kurztext: '',
  position: const LatLng(0, 0),
);

void main() {
  final trail = Trail.fromJson(
    jsonDecode(File('assets/seed/trail.json').readAsStringSync())
        as Map<String, dynamic>,
  );

  test('Grenze: 1200 s inklusive, 1201 s raus', () {
    final catalog = [
      place('a', 'cafe'),
      place('b', 'cafe'),
      place('c', 'baden'),
    ];
    final zeiten = {
      trail.id: {
        'a': nearbyMaxFahrzeitSek,
        'b': nearbyMaxFahrzeitSek + 1,
        'c': 60,
      },
    };
    final ids = nearby(trail, catalog, zeiten).map((t) => t.place.id);
    expect(nearbyMaxFahrzeitSek, 1200);
    expect(ids, ['c', 'a']);
  });

  test('sortiert nach Fahrzeit, nicht nach Katalog-Reihenfolge', () {
    final catalog = [
      place('weit', 'cafe'),
      place('mitte', 'museum'),
      place('nah', 'restaurant'),
    ];
    final zeiten = {
      trail.id: {'weit': 1100, 'mitte': 600, 'nah': 120},
    };
    final hits = nearby(trail, catalog, zeiten);
    expect(hits.map((t) => t.place.id), ['nah', 'mitte', 'weit']);
    expect(hits.first.fahrzeitSek, 120);
  });

  test('Trail ohne Eintrag oder ohne Katalog-Ort → leer', () {
    final catalog = [place('a', 'cafe')];
    expect(nearby(trail, catalog, const {}), isEmpty);
    expect(
      nearby(trail, catalog, {
        'anderer-trail': {'a': 60},
      }),
      isEmpty,
    );
    expect(
      nearby(trail, catalog, {
        trail.id: {'unbekannt': 60},
      }),
      isEmpty,
    );
  });

  test('Cap: max. 8, erst 2 pro Kategorie, Rest nach Fahrzeit', () {
    final katalog = <NearbyPlace>[];
    final zeitenTrail = <String, int>{};
    for (var i = 0; i < 5; i++) {
      katalog.add(place('cafe$i', 'cafe'));
      zeitenTrail['cafe$i'] = 60 + i * 10;
    }
    for (var i = 0; i < 3; i++) {
      katalog.add(place('rest$i', 'restaurant'));
      zeitenTrail['rest$i'] = 200 + i * 10;
    }
    katalog.add(place('bad', 'baden'));
    zeitenTrail['bad'] = 1000;
    katalog.add(place('museum', 'museum'));
    zeitenTrail['museum'] = 1100;
    final hits = nearby(trail, katalog, {trail.id: zeitenTrail});
    final ids = hits.map((t) => t.place.id).toList();
    expect(hits.length, nearbyMaxProTrail);
    // Mix vor Auffüllen: Bad und Museum sind trotz größerer Fahrzeit drin,
    // aufgefüllt wird danach nach Fahrzeit (cafe2, cafe3), cafe4/rest2 fallen raus.
    expect(
      ids,
      containsAll(['cafe0', 'cafe1', 'rest0', 'rest1', 'bad', 'museum']),
    );
    expect(ids, containsAll(['cafe2', 'cafe3']));
    expect(ids, isNot(contains('cafe4')));
    expect(ids, isNot(contains('rest2')));
    expect(
      [
        for (var i = 1; i < hits.length; i++)
          hits[i].fahrzeitSek >= hits[i - 1].fahrzeitSek,
      ].every((ok) => ok),
      isTrue,
    );
  });

  test('formatFahrzeit', () {
    expect(formatFahrzeit(30), 'direkt am Trail');
    expect(formatFahrzeit(60), '1 Min Auto');
    expect(formatFahrzeit(749), '12 Min Auto');
    expect(formatFahrzeit(1200), '20 Min Auto');
  });

  test('NearbyTreffer.fahrzeitMin rundet, mindestens 1', () {
    final p = place('a', 'cafe');
    expect(NearbyTreffer(place: p, fahrzeitSek: 0).fahrzeitMin, 1);
    expect(NearbyTreffer(place: p, fahrzeitSek: 749).fahrzeitMin, 12);
  });

  test('Seed-JSON Roundtrip', () {
    final zeiten = zeitenFromSeedJson({
      't1': [
        {'poi': 'a', 'sek': 100},
        {'poi': 'b', 'sek': 200},
      ],
      't2': <dynamic>[],
    });
    expect(zeiten, {
      't1': {'a': 100, 'b': 200},
      't2': <String, int>{},
    });
    expect(zeitenFromSeedJson(zeitenToSeedJson(zeiten)), zeiten);
  });

  test('Supabase-Rows → NearbyZeiten', () {
    final zeiten = SupabaseNearbyZeitenRepository.rowsToZeiten([
      {'trail_id': 't1', 'poi_id': 'a', 'sek': 100},
      {'trail_id': 't1', 'poi_id': 'b', 'sek': 200},
      {'trail_id': 't2', 'poi_id': 'a', 'sek': 300},
    ]);
    expect(zeiten, {
      't1': {'a': 100, 'b': 200},
      't2': {'a': 300},
    });
  });

  test('Seed-Datei: alle Zeiten ≤ 1200 s und nach Zeit sortiert', () {
    final json =
        jsonDecode(File('assets/seed/nearby_zeiten.json').readAsStringSync())
            as Map<String, dynamic>;
    final zeiten = zeitenFromSeedJson(json);
    expect(zeiten, isNotEmpty);
    for (final e in json.entries) {
      var last = 0;
      for (final z in (e.value as List).cast<Map<String, dynamic>>()) {
        final sek = z['sek'] as int;
        expect(sek, lessThanOrEqualTo(nearbyMaxFahrzeitSek), reason: e.key);
        expect(sek, greaterThanOrEqualTo(last), reason: e.key);
        last = sek;
      }
    }
  });
}
