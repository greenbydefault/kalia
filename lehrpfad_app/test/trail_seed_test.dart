import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:lehrpfad_app/features/trail/data/seed_trail_repository.dart';
import 'package:lehrpfad_app/features/trail/data/trail_hero_assets.dart';
import 'package:lehrpfad_app/features/trail/domain/trail.dart';
import 'package:lehrpfad_app/features/trail/presentation/map/trail_hero.dart';

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
    expect(trails, hasLength(28));
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
        'erlebe-bruder-wald',
        'fossilruten-moens-klint',
        'stubbenkammer-koenigsstuhl',
        'naturerlebnisraum-spo',
        'kaeflingsberg-speck',
      ]),
    );
    expect(trails.firstWhere((t) => t.id == 'wupatz').route, isNotEmpty);
  });

  test('Heide-Erlebnisweg lädt Seed-Hero-Bilder aus credits.json', () async {
    final trails = await SeedTrailRepository().getTrails();
    final heide = trails.firstWhere((t) => t.id == 'heide-erlebnisweg');
    expect(heide.bilder.length, inInclusiveRange(10, 15));
    expect(heide.hasHeroBilder, isTrue);
    expect(TrailHero.pagesFor(heide), heide.bilder);
    for (final bild in heide.bilder) {
      expect(bild.file, isNotEmpty);
      expect(bild.credit, isNotEmpty);
      expect(bild.license, isNotEmpty);
      expect(bild.sourceUrl, contains('commons.wikimedia.org'));
      expect(
        File(
          'assets/images/trails/heide-erlebnisweg/${bild.file}',
        ).existsSync(),
        isTrue,
      );
    }
  });

  test('SPO-Naturerlebnisraum lädt Seed-Hero-Bilder aus credits.json', () async {
    final trails = await SeedTrailRepository().getTrails();
    final spo = trails.firstWhere((t) => t.id == 'naturerlebnisraum-spo');
    expect(spo.bilder.length, inInclusiveRange(8, 15));
    expect(spo.hasHeroBilder, isTrue);
    expect(TrailHero.pagesFor(spo), spo.bilder);
    expect(spo.typ, 'kueste');
    expect(spo.route.length, greaterThan(2));
    expect(spo.rundkurs, isTrue);
    for (final bild in spo.bilder) {
      expect(bild.file, isNotEmpty);
      expect(bild.credit, isNotEmpty);
      expect(bild.license, isNotEmpty);
      expect(bild.sourceUrl, contains('commons.wikimedia.org'));
      expect(
        File(
          'assets/images/trails/naturerlebnisraum-spo/${bild.file}',
        ).existsSync(),
        isTrue,
      );
    }
  });

  test('Käflingsberg Speck lädt Seed-Hero-Bilder aus credits.json', () async {
    final trails = await SeedTrailRepository().getTrails();
    final trail = trails.firstWhere((t) => t.id == 'kaeflingsberg-speck');
    expect(trail.bilder.length, inInclusiveRange(10, 15));
    expect(trail.hasHeroBilder, isTrue);
    expect(TrailHero.pagesFor(trail), trail.bilder);
    expect(trail.typ, 'wald');
    expect(trail.rundkurs, isFalse);
    expect(trail.arten, contains('Fischadler'));
    expect(trail.route.length, greaterThan(2));
    expect(trail.stationen.length, greaterThanOrEqualTo(4));
    for (final bild in trail.bilder) {
      expect(bild.file, isNotEmpty);
      expect(bild.credit, isNotEmpty);
      expect(bild.license, isNotEmpty);
      expect(bild.sourceUrl, contains('commons.wikimedia.org'));
      expect(
        File(
          'assets/images/trails/kaeflingsberg-speck/${bild.file}',
        ).existsSync(),
        isTrue,
      );
    }
  });

  test('Hero-Credits hydrieren auch ohne bilderAsset (Supabase-Pfad)', () async {
    final json = <String, dynamic>{'id': 'kaeflingsberg-speck'};
    await attachHeroBilder(json);
    final bilder = json['bilder'] as List;
    expect(bilder.length, inInclusiveRange(10, 15));
  });

  test('Trail ohne Hero-Fotos bekommt zentralen Platzhalter', () async {
    final trails = await SeedTrailRepository().getTrails();
    final stub = trails.firstWhere((t) => t.id == 'stubbenkammer-koenigsstuhl');
    expect(stub.bilder, isEmpty);
    expect(stub.hasHeroBilder, isFalse);
    final pages = TrailHero.pagesFor(stub);
    expect(pages, hasLength(1));
    expect(pages.single.isPlaceholder, isTrue);
    expect(pages.single.assetPath(stub.id), TrailHero.placeholderAsset);
    expect(pages.single.hasCreditBadge, isFalse);
    expect(File('assets/images/trails/_placeholder.jpg').existsSync(), isTrue);

    final wolf = trails.firstWhere((t) => t.id == 'wolfspfad-zwenzow');
    expect(wolf.bilder, isEmpty);
    expect(TrailHero.pagesFor(wolf), hasLength(1));
    expect(TrailHero.pagesFor(wolf).single.isPlaceholder, isTrue);
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
    expect(
      trail.arten,
      containsAll(['Stieleiche', 'Rotbuche', 'Edelkastanie']),
    );
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
    expect(
      trail.arten,
      containsAll(['Ringelnatter', 'Heckenrose', 'Haselnuss']),
    );
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

  test('Linien-Seed Bruderwald: walderlebnispfad, Rundkurs, Bamberg', () {
    final raw = File('assets/seed/erlebe-bruder-wald.json').readAsStringSync();
    final trail = Trail.fromJson(jsonDecode(raw) as Map<String, dynamic>);

    expect(trail.isFlaeche, isFalse);
    expect(trail.typ, 'walderlebnispfad');
    expect(trail.rundkurs, isTrue);
    expect(trail.laengeKm, greaterThan(2));
    expect(trail.route, isNotEmpty);
    expect(trail.area, isEmpty);
    expect(trail.arten, containsAll(['Rotbuche', 'Stieleiche', 'Kiefer']));
    expect(trail.stationen.length, greaterThanOrEqualTo(3));
    expect(
      trail.stationen.map((s) => s.titel),
      containsAll([
        'Eingang Bruderwald',
        'Ökorohstoff Holz',
        'Barfußraupe',
        'Mein Bruder Wald',
      ]),
    );
    expect(trail.stationen.first.titel, 'Eingang Bruderwald');
    expect(trail.stationen.last.titel, 'Mein Bruder Wald');
  });

  test('Linien-Seed Fossilruten: kueste, Rundkurs, Dänemark', () {
    final raw = File(
      'assets/seed/fossilruten-moens-klint.json',
    ).readAsStringSync();
    final trail = Trail.fromJson(jsonDecode(raw) as Map<String, dynamic>);

    expect(trail.isFlaeche, isFalse);
    expect(trail.typ, 'kueste');
    expect(trail.rundkurs, isTrue);
    expect(trail.laengeKm, greaterThan(2));
    expect(trail.route, isNotEmpty);
    expect(trail.area, isEmpty);
    expect(trail.region, contains('Dänemark'));
    expect(
      trail.arten,
      containsAll(['Rotbuche', 'Knabenkraut', 'Wanderfalke']),
    );
    expect(trail.stationen.length, greaterThanOrEqualTo(3));
    expect(
      trail.stationen.map((s) => s.titel),
      containsAll([
        'GeoCenter Møns Klint',
        'Maglevandstrappen',
        'Fossilstrand',
        'Sommerspirspynten',
      ]),
    );
    expect(trail.start.latitude, closeTo(54.96, 0.05));
    expect(trail.start.longitude, closeTo(12.55, 0.05));
  });

  test('Linien-Seed Stubbenkammer: kueste, Rundkurs, MV/Rügen', () {
    final raw = File(
      'assets/seed/stubbenkammer-koenigsstuhl.json',
    ).readAsStringSync();
    final trail = Trail.fromJson(jsonDecode(raw) as Map<String, dynamic>);

    expect(trail.isFlaeche, isFalse);
    expect(trail.typ, 'kueste');
    expect(trail.rundkurs, isTrue);
    expect(trail.laengeKm, greaterThan(2));
    expect(trail.laengeKm, lessThan(4));
    expect(trail.route, isNotEmpty);
    expect(trail.area, isEmpty);
    expect(trail.region, contains('Vorpommern-Rügen'));
    expect(
      trail.arten,
      containsAll(['Rotbuche', 'Knabenkraut', 'Wanderfalke']),
    );
    expect(trail.stationen.length, greaterThanOrEqualTo(3));
    expect(
      trail.stationen.map((s) => s.titel),
      containsAll([
        'Nationalpark-Zentrum Königsstuhl',
        'Victoria-Sicht',
        'Küste in Bewegung',
        'Herthasee',
      ]),
    );
    expect(trail.start.latitude, closeTo(54.572, 0.02));
    expect(trail.start.longitude, closeTo(13.66, 0.02));
  });

  test(
    'Flächen-Seed Pinke-Panke: kinderbauernhof, Besuchsfelder, kein Eintritt-Chip',
    () {
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
    },
  );

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
