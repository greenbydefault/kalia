import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:latlong2/latlong.dart';

import '../domain/trail.dart';
import 'trail_hero_assets.dart';
import 'trail_repository.dart';

/// Lädt die lokalen Seed-Datensätze aus den App-Assets.
class SeedTrailRepository implements TrailRepository {
  /// Explizite Liste statt Verzeichnis-Scan: In assets/seed/ liegen auch
  /// OSM-Rohdaten und Flyer, die keine Trails sind.
  static const _seedPaths = [
    'assets/seed/trail.json',
    'assets/seed/raddusch.json',
    'assets/seed/rauener-berge.json',
    'assets/seed/lehde.json',
    'assets/seed/ravensberge.json',
    'assets/seed/heide-erlebnisweg.json',
    'assets/seed/wupatz.json',
    'assets/seed/stendenitz.json',
    'assets/seed/wahrberge.json',
    'assets/seed/libellen-wasserspielplatz-wittstock.json',
    'assets/seed/wolfspfad-zwenzow.json',
    'assets/seed/spurenweg-kratzeburg.json',
    'assets/seed/wald-erlebnispfad-serrahn.json',
    'assets/seed/hullerbusch.json',
    'assets/seed/heilige-hallen.json',
    'assets/seed/fledermauspfad-bossow.json',
    'assets/seed/lehrpfad-sandhof.json',
    'assets/seed/wasserspielplatz-roebel.json',
    'assets/seed/harzungspfad.json',
    'assets/seed/kinderwald-maerkisch-buchholz.json',
    'assets/seed/kinderbauernhof-pinke-panke.json',
    'assets/seed/arboretum-dreetz.json',
    'assets/seed/natter-pfad-goyatz.json',
    'assets/seed/erlebe-bruder-wald.json',
    'assets/seed/fossilruten-moens-klint.json',
    'assets/seed/stubbenkammer-koenigsstuhl.json',
    'assets/seed/naturerlebnisraum-spo.json',
    'assets/seed/erlebnisrundweg-friedrichskoog.json',
    'assets/seed/kaeflingsberg-speck.json',
    'assets/seed/braumannswiesen.json',
    'assets/seed/entdeckerpfad-biologische-vielfalt.json',
    'assets/seed/baumkronenpfad-hainich.json',
    'assets/seed/archaeologischer-wanderpfad-fischbek.json',
    'assets/seed/rittbrookpfad.json',
    'assets/seed/naturwaldpfad.json',
    'assets/seed/waldhusen.json',
    'assets/seed/schwartautal.json',
    'assets/seed/oher-graeberfeld.json',
    'assets/seed/naturerlebnis-grabau.json',
    'assets/seed/naturerlebnispfad-eutin.json',
    'assets/seed/kollhorst.json',
    'assets/seed/untereider.json',
    'assets/seed/baumwipfelpfad-saarschleife.json',
    'assets/seed/baumwipfelpfad-schwarzwald.json',
    'assets/seed/everstorfer-forst.json',
    'assets/seed/moislinger-aue.json',
    'assets/seed/lehrpfad-pflanzenschutz-schwentinental.json',
    'assets/seed/naturerlebnispfad-ellerbek.json',
    'assets/seed/naturerlebnisweg-ploener-seeufer.json',
    // Nach Feldcapture: build_seed.py tools/trails/alt-daber.json
    // 'assets/seed/alt-daber.json',
  ];

  @override
  Future<List<Trail>> getTrails({LatLng? near, double? radiusKm}) async {
    final trails = <Trail>[];
    for (final path in _seedPaths) {
      try {
        final raw = await rootBundle.loadString(path);
        final json = jsonDecode(raw) as Map<String, dynamic>;
        await attachHeroBilder(json);
        trails.add(Trail.fromJson(json));
      } catch (e) {
        // Ein fehlender/fehlerhafter Seed darf die übrigen Trails nicht blockieren.
        debugPrint('SeedTrailRepository: "$path" übersprungen ($e)');
      }
    }
    return trails;
  }
}
