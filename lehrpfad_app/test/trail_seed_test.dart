import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:lehrpfad_app/features/trail/data/seed_trail_repository.dart';
import 'package:lehrpfad_app/features/trail/domain/trail.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Trail.fromJson parst den Seed-Datensatz vollständig', () {
    final raw = File('assets/seed/trail.json').readAsStringSync();
    final json = jsonDecode(raw) as Map<String, dynamic>;

    final trail = Trail.fromJson(json);

    expect(trail.id, isNotEmpty);
    expect(trail.name, isNotEmpty);
    expect(trail.route.length, greaterThan(1));
    expect(trail.stationen, isNotEmpty);
    expect(trail.stationen.first.steckbrief, isNotNull);
    expect(trail.amenities, isNotEmpty);
    expect(trail.tags, isNotEmpty);
  });

  test('Auto-Tags werden aus den Amenities abgeleitet', () {
    final raw = File('assets/seed/trail.json').readAsStringSync();
    final trail = Trail.fromJson(jsonDecode(raw) as Map<String, dynamic>);

    // Der Seed enthält parking- und wc-Amenities
    expect(trail.autoTags, containsAll(['parkplatz-nahe', 'wc-am-weg']));
    // alleTags vereint redaktionelle und abgeleitete Tags ohne Duplikate
    expect(trail.alleTags.toSet().length, trail.alleTags.length);
    expect(trail.alleTags, containsAll(trail.tags));
  });

  test('SeedTrailRepository lädt die Trails aus den Assets', () async {
    final trails = await SeedTrailRepository().getTrails();

    // Alle Einträge in _seedPaths außer auskommentiertem alt-daber.
    expect(trails, hasLength(23));
    expect(
      trails.map((t) => t.id),
      containsAll([
        'wupatz',
        'stendenitz',
        'wahrberge',
        'libellen-wasserspielplatz-wittstock',
        'wolfspfad-zwenzow',
        'spurenweg-kratzeburg',
        'wald-erlebnispfad-serrahn',
        'hullerbusch',
        'heilige-hallen',
        'fledermauspfad-bossow',
        'lehrpfad-sandhof',
        'wasserspielplatz-roebel',
        'harzungspfad',
        'kinderwald-maerkisch-buchholz',
        'kinderbauernhof-pinke-panke',
        'arboretum-dreetz',
        'natter-pfad-goyatz',
      ]),
    );
    expect(trails.firstWhere((t) => t.id == 'wupatz').route, isNotEmpty);
  });

  test('Flächen-Seed Wittstock: form flaeche, area, kein Rundkurs', () {
    final raw = File(
      'assets/seed/libellen-wasserspielplatz-wittstock.json',
    ).readAsStringSync();
    final trail = Trail.fromJson(jsonDecode(raw) as Map<String, dynamic>);

    expect(trail.isFlaeche, isTrue);
    expect(trail.rundkurs, isFalse);
    expect(trail.laengeKm, 0);
    expect(trail.area.length, greaterThanOrEqualTo(3));
    expect(trail.route, isEmpty);
    expect(trail.mapPoints, trail.area);
    expect(trail.arten, contains('Libellen-Installation'));
    expect(trail.arten, contains('Libelle'));
    expect(trail.startName, 'Wasserspielplatz an der Glinze');
    expect(trail.start.longitude, lessThan(12.485));
    expect(trail.start.longitude, greaterThan(12.482));
  });

  test('Flächen-Seed Kinderwald: form flaeche, waldspielplatz, Geräte', () {
    final raw = File(
      'assets/seed/kinderwald-maerkisch-buchholz.json',
    ).readAsStringSync();
    final trail = Trail.fromJson(jsonDecode(raw) as Map<String, dynamic>);

    expect(trail.isFlaeche, isTrue);
    expect(trail.typ, 'waldspielplatz');
    expect(trail.rundkurs, isFalse);
    expect(trail.laengeKm, 0);
    expect(trail.area.length, greaterThanOrEqualTo(3));
    expect(trail.route, isEmpty);
    expect(trail.arten, contains('Kinderhochstand'));
    expect(trail.arten, contains('Honigbiene'));
    expect(trail.stationen.length, greaterThanOrEqualTo(3));
  });

  test('Flächen-Seed Röbel: form flaeche, area, Müritz-Hafen', () {
    final raw = File(
      'assets/seed/wasserspielplatz-roebel.json',
    ).readAsStringSync();
    final trail = Trail.fromJson(jsonDecode(raw) as Map<String, dynamic>);

    expect(trail.isFlaeche, isTrue);
    expect(trail.rundkurs, isFalse);
    expect(trail.laengeKm, 0);
    expect(trail.area.length, greaterThanOrEqualTo(3));
    expect(trail.route, isEmpty);
    expect(trail.mapPoints, trail.area);
    expect(trail.arten, contains('Libelle'));
  });

  test('A→B-Seed hat end, Rundkurs und Fläche nicht', () async {
    final trails = await SeedTrailRepository().getTrails();

    final ab = trails.firstWhere((t) => t.id == 'wald-erlebnispfad-serrahn');
    expect(ab.isPointToPoint, isTrue);
    expect(ab.end, ab.route.last);

    final loop = trails.firstWhere((t) => t.id == 'wolfspfad-zwenzow');
    expect(loop.rundkurs, isTrue);
    expect(loop.isPointToPoint, isFalse);
    expect(loop.end, isNull);

    final zone = trails.firstWhere((t) => t.id == 'wasserspielplatz-roebel');
    expect(zone.isFlaeche, isTrue);
    expect(zone.isPointToPoint, isFalse);
    expect(zone.end, isNull);
  });

  test('Flächen-Seed Dreetz: naturerlebnis, form flaeche, Arten', () {
    final raw = File('assets/seed/arboretum-dreetz.json').readAsStringSync();
    final trail = Trail.fromJson(jsonDecode(raw) as Map<String, dynamic>);

    expect(trail.isFlaeche, isTrue);
    expect(trail.typ, 'naturerlebnis');
    expect(trail.rundkurs, isFalse);
    expect(trail.laengeKm, 0);
    expect(trail.area.length, greaterThanOrEqualTo(3));
    expect(trail.route, isEmpty);
    expect(trail.eintritt, isFalse);
    expect(trail.arten, containsAll(['Stieleiche', 'Rotbuche', 'Edelkastanie']));
    expect(trail.stationen.length, greaterThanOrEqualTo(3));
    expect(trail.tags, isNot(contains('barfusspfad')));
    expect(trail.tags, isNot(contains('spielplatz')));
  });

  test('Linien-Seed Natter-Pfad: walderlebnispfad, Rundkurs, Ringelnatter', () {
    final raw = File('assets/seed/natter-pfad-goyatz.json').readAsStringSync();
    final trail = Trail.fromJson(jsonDecode(raw) as Map<String, dynamic>);

    expect(trail.isFlaeche, isFalse);
    expect(trail.typ, 'walderlebnispfad');
    expect(trail.rundkurs, isTrue);
    expect(trail.laengeKm, greaterThan(1.5));
    expect(trail.route, isNotEmpty);
    expect(trail.area, isEmpty);
    expect(trail.arten, containsAll(['Ringelnatter', 'Heckenrose', 'Haselnuss']));
    expect(trail.stationen.length, greaterThanOrEqualTo(3));
    expect(
      trail.stationen.map((s) => s.titel),
      containsAll([
        'Spreewaldbahnhof Goyatz',
        'Feuchtwiesen',
        'Stamm in Ringelnatter-Form',
      ]),
    );
  });

  test('Flächen-Seed Pinke-Panke: kinderbauernhof, Besuchsfelder, kein Eintritt-Chip', () {
    final raw = File(
      'assets/seed/kinderbauernhof-pinke-panke.json',
    ).readAsStringSync();
    final trail = Trail.fromJson(jsonDecode(raw) as Map<String, dynamic>);

    expect(trail.isFlaeche, isTrue);
    expect(trail.typ, 'kinderbauernhof');
    expect(trail.rundkurs, isFalse);
    expect(trail.laengeKm, 0);
    expect(trail.area.length, greaterThanOrEqualTo(3));
    expect(trail.route, isEmpty);
    expect(trail.eintritt, isFalse);
    expect(trail.eintrittPreise, contains('Spende'));
    expect(trail.oeffnungszeiten, isNotEmpty);
    expect(trail.besuchshinweise, contains('16 Uhr'));
    expect(trail.website, isNotEmpty);
    expect(trail.hasBesuchInfos, isTrue);
    expect(trail.arten, containsAll(['Ziege', 'Schaf', 'Haushuhn']));
    expect(trail.stationen.length, greaterThanOrEqualTo(3));
  });

  test('fromJson: Besuchsfelder defaulten, wenn Keys fehlen', () {
    final raw = File('assets/seed/trail.json').readAsStringSync();
    final trail = Trail.fromJson(jsonDecode(raw) as Map<String, dynamic>);

    expect(trail.eintritt, isFalse);
    expect(trail.eintrittPreise, isNull);
    expect(trail.oeffnungszeiten, isNull);
    expect(trail.besuchshinweise, isNull);
  });

  test('end ist null wenn Start und Ziel näher als 40 m', () {
    Trail pointToPoint(List<LatLng> route) => Trail(
      id: 't',
      name: 'Test',
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
      arten: const [],
      route: route,
      stationen: const [],
      amenities: const [],
    );

    // ~22 m Nord
    final near = pointToPoint(const [LatLng(52, 13), LatLng(52.0002, 13)]);
    expect(near.isPointToPoint, isTrue);
    expect(near.end, isNull);

    // ~1.1 km Nord
    final far = pointToPoint(const [LatLng(52, 13), LatLng(52.01, 13)]);
    expect(far.end, far.route.last);
  });
}
