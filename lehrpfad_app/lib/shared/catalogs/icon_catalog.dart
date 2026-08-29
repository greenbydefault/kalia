import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// Icon + Anzeigename für einen Katalog-Schlüssel aus den JSON-Daten.
///
/// [buildIcon] kapselt die Darstellung: Soll das Icon-Set später erneut
/// wechseln, ändert sich nur diese Klasse - nicht die Widgets.
class KatalogEintrag {
  final IconData icon;
  final String label;
  final String? assetPath;

  const KatalogEintrag(this.icon, this.label, {this.assetPath});

  Widget buildIcon({double? size, Color? color}) {
    final path = assetPath;
    if (path != null) {
      return SvgPicture.asset(
        path,
        width: size,
        height: size,
        colorFilter: color == null
            ? null
            : ColorFilter.mode(color, BlendMode.srcIn),
      );
    }
    return PhosphorIcon(icon, size: size, color: color);
  }
}

/// Erlebnis-Icons (Inhalte einer Station)
const erlebnisKatalog = <String, KatalogEintrag>{
  'tafel': KatalogEintrag(PhosphorIcons.info, 'Infotafel'),
  'quiz': KatalogEintrag(PhosphorIcons.question, 'Quiz'),
  'steg': KatalogEintrag(PhosphorIcons.bridge, 'Moorsteg'),
  'bohrkernmodell': KatalogEintrag(PhosphorIcons.flask, 'Bohrkernmodell'),
  'mitmach-modell': KatalogEintrag(PhosphorIcons.hand, 'Mitmach-Modell'),
  'memory': KatalogEintrag(PhosphorIcons.gridFour, 'Memory'),
  'bestimmung': KatalogEintrag(PhosphorIcons.magnifyingGlass, 'Bestimmung'),
  'audio': KatalogEintrag(PhosphorIcons.headphones, 'Audio'),
  'barfusspfad': KatalogEintrag(PhosphorIcons.footprints, 'Barfußpfad'),
};

/// Amenity-Icons (Infrastruktur *am Weg*: WC, Bank, Parkplatz).
/// Nicht für kuratierte Orte im Umfeld — die liegen in [poiKategorieKatalog].
const amenityKatalog = <String, KatalogEintrag>{
  'wc': KatalogEintrag(PhosphorIcons.toilet, 'WC'),
  'parking': KatalogEintrag(PhosphorIcons.car, 'Parkplatz'),
  'bench': KatalogEintrag(PhosphorIcons.chair, 'Bank'),
  'picnic': KatalogEintrag(PhosphorIcons.picnicTable, 'Picknickplatz'),
  'shelter': KatalogEintrag(PhosphorIcons.tent, 'Schutzhütte'),
  'playground': KatalogEintrag(PhosphorIcons.soccerBall, 'Spielplatz'),
  'viewpoint': KatalogEintrag(PhosphorIcons.binoculars, 'Aussicht'),
  'gastro': KatalogEintrag(PhosphorIcons.forkKnife, 'Gastronomie'),
};

/// Orte in der Nähe — kuratiert, nicht OSM-Amenity.
///
/// Reihenfolge = Anzeige. `gastro` im [amenityKatalog] bleibt Weg-Gastronomie.
/// Phosphor ist Fallback; Custom-SVG unter `assets/icons/pois/<key>.svg`.
const poiKategorieKatalog = <String, KatalogEintrag>{
  'cafe': KatalogEintrag(
    PhosphorIcons.coffee,
    'Café',
    assetPath: 'assets/icons/pois/cafe.svg',
  ),
  'restaurant': KatalogEintrag(
    PhosphorIcons.forkKnife,
    'Restaurant & Imbiss',
    assetPath: 'assets/icons/pois/restaurant.svg',
  ),
  'hofladen': KatalogEintrag(
    PhosphorIcons.storefront,
    'Hofladen & Regionales',
    assetPath: 'assets/icons/pois/hofladen.svg',
  ),
  'baden': KatalogEintrag(
    PhosphorIcons.swimmingPool,
    'Baden & Therme',
    assetPath: 'assets/icons/pois/baden.svg',
  ),
  'museum': KatalogEintrag(
    PhosphorIcons.bank,
    'Museum & Ausstellung',
    assetPath: 'assets/icons/pois/museum.svg',
  ),
  'aktivitaet': KatalogEintrag(
    PhosphorIcons.backpack,
    'Aktivität & Touren',
    assetPath: 'assets/icons/pois/aktivitaet.svg',
  ),
  'camping': KatalogEintrag(
    PhosphorIcons.tent,
    'Camping',
    assetPath: 'assets/icons/pois/camping.svg',
  ),
};

/// Ortstyp (Trail/`typ` in JSON). Einzige Stelle für Typ-Icon + Label.
///
/// Source of Truth auch für `tools/validate_seeds.py` → `TYP` (Key-Set spiegeln).
const typKatalog = <String, KatalogEintrag>{
  'wald': KatalogEintrag(PhosphorIcons.tree, 'Naturlehrpfad'),
  'moor': KatalogEintrag(PhosphorIcons.drop, 'Moorlehrpfad'),
  'spreewald': KatalogEintrag(PhosphorIcons.boat, 'Spreewald-Lehrpfad'),
  'walderlebnispfad': KatalogEintrag(PhosphorIcons.path, 'Walderlebnispfad'),
  'erlebniswald': KatalogEintrag(PhosphorIcons.treeEvergreen, 'Erlebniswald'),
  'naturerlebnis': KatalogEintrag(PhosphorIcons.park, 'Naturerlebnisraum'),
  'naturerlebnisraum': KatalogEintrag(PhosphorIcons.park, 'Naturerlebnisraum'),
  'waldspielplatz': KatalogEintrag(PhosphorIcons.soccerBall, 'Waldspielplatz'),
  'wasserspielplatz': KatalogEintrag(PhosphorIcons.drop, 'Wasserspielplatz'),
  'waldspazierplatz': KatalogEintrag(
    PhosphorIcons.personSimpleWalk,
    'Waldspazierplatz',
  ),
  'sinnespfad': KatalogEintrag(PhosphorIcons.ear, 'Sinnespfad'),
  'barfusspfad': KatalogEintrag(PhosphorIcons.footprints, 'Barfußpfad'),
  'kueste': KatalogEintrag(PhosphorIcons.waves, 'Küstenpfad'),
  'kinderbauernhof': KatalogEintrag(PhosphorIcons.barn, 'Kinderbauernhof'),
};

/// Species-Kategorie (Flora / Fauna / Geräte) — Sektions-Header, Chips, Tiles.
///
/// Source of Truth für Kategorie-Icon + Label; UI nicht Phosphor hardcoden.
const speciesKategorieKatalog = <String, KatalogEintrag>{
  'flora': KatalogEintrag(PhosphorIcons.plant, 'Flora'),
  'fauna': KatalogEintrag(PhosphorIcons.bird, 'Fauna'),
  'geraete': KatalogEintrag(PhosphorIcons.gearSix, 'Geräte'),
};

/// Geräte-Typ-Icons (Species `iconKey` bei `kategorie: geraete`).
///
/// Phase-1: generischer Key `geraet`; später z. B. `quellstein`, `rinne`, …
/// Source of Truth auch für `tools/validate_seeds.py` → `GERAETE_ICON_KEYS`.
const geraeteKatalog = <String, KatalogEintrag>{
  'geraet': KatalogEintrag(PhosphorIcons.gearSix, 'Gerät'),
};

/// Ausstattungs-Tags eines Trails (redaktionell in DB + autoTags aus Amenities)
const tagKatalog = <String, KatalogEintrag>{
  'kinderfreundlich': KatalogEintrag(PhosphorIcons.baby, 'Kinderfreundlich'),
  'kinderwagentauglich': KatalogEintrag(
    PhosphorIcons.babyCarriage,
    'Kinderwagentauglich',
  ),
  'rollstuhltauglich': KatalogEintrag(
    PhosphorIcons.wheelchair,
    'Rollstuhltauglich',
  ),
  'hunde-erlaubt': KatalogEintrag(PhosphorIcons.dog, 'Hunde erlaubt'),
  'einkehr': KatalogEintrag(PhosphorIcons.coffee, 'Einkehrmöglichkeit'),
  'spielplatz': KatalogEintrag(PhosphorIcons.soccerBall, 'Spielplatz'),
  'picknick': KatalogEintrag(PhosphorIcons.picnicTable, 'Picknickplatz'),
  'barfusspfad': KatalogEintrag(PhosphorIcons.footprints, 'Barfußpfad'),
  // Auto-Tags (aus Amenities abgeleitet, nicht in der DB gepflegt)
  'parkplatz-nahe': KatalogEintrag(PhosphorIcons.car, 'Parkplatz in der Nähe'),
  'wc-am-weg': KatalogEintrag(PhosphorIcons.toilet, 'WC am Weg'),
};

/// Merkmale (Species-Profil). Keys aus assets/seed/merkmale.json → `iconKey`.
/// Phosphor-Platzhalter; Custom-Assets später über denselben Key.
const merkmaleKatalog = <String, KatalogEintrag>{
  // Aussehen
  'pelzig': KatalogEintrag(PhosphorIcons.pawPrint, 'Pelzig'),
  'gefiedert': KatalogEintrag(PhosphorIcons.bird, 'Gefiedert'),
  'schuppig': KatalogEintrag(PhosphorIcons.spiral, 'Schuppig'),
  'dornig': KatalogEintrag(PhosphorIcons.cactus, 'Dornig'),
  'laubabwerfend': KatalogEintrag(PhosphorIcons.leaf, 'Laubabwerfend'),
  'immergruen': KatalogEintrag(PhosphorIcons.treeEvergreen, 'Immergrün'),
  'nadelbaum': KatalogEintrag(PhosphorIcons.treeEvergreen, 'Nadelbaum'),
  'laubbaum': KatalogEintrag(PhosphorIcons.tree, 'Laubbaum'),
  'bluete': KatalogEintrag(PhosphorIcons.flower, 'Blüte'),
  'herbstfarbe': KatalogEintrag(PhosphorIcons.leaf, 'Herbstfarbe'),
  // Verhalten
  'sozial': KatalogEintrag(PhosphorIcons.usersThree, 'Sozial'),
  'nachtaktiv': KatalogEintrag(PhosphorIcons.moon, 'Nachtaktiv'),
  'tagaktiv': KatalogEintrag(PhosphorIcons.sun, 'Tagaktiv'),
  'wanderer': KatalogEintrag(PhosphorIcons.path, 'Wanderer'),
  'baumeister': KatalogEintrag(PhosphorIcons.hammer, 'Baumeister'),
  'tarnung': KatalogEintrag(PhosphorIcons.eyeSlash, 'Tarnung'),
  'wehrhaft': KatalogEintrag(PhosphorIcons.shield, 'Wehrhaft'),
  'saenger': KatalogEintrag(PhosphorIcons.musicNote, 'Sänger'),
  // Rolle
  'insektenfresser': KatalogEintrag(PhosphorIcons.bug, 'Insektenfresser'),
  'pflanzenfresser': KatalogEintrag(PhosphorIcons.plant, 'Pflanzenfresser'),
  'fleischfresser': KatalogEintrag(PhosphorIcons.knife, 'Fleischfresser'),
  'allesfresser': KatalogEintrag(PhosphorIcons.forkKnife, 'Allesfresser'),
  'bestaeuber': KatalogEintrag(PhosphorIcons.butterfly, 'Bestäuber'),
  'schluesselart': KatalogEintrag(PhosphorIcons.key, 'Schlüsselart'),
  'fruchttragend': KatalogEintrag(PhosphorIcons.orange, 'Fruchttragend'),
  // Lebensraum
  'wasserlebend': KatalogEintrag(PhosphorIcons.drop, 'Wasserlebend'),
  'luftbewohnend': KatalogEintrag(PhosphorIcons.wind, 'Luftbewohnend'),
  'hoehlenbewohnend': KatalogEintrag(
    PhosphorIcons.mountains,
    'Höhlenbewohnend',
  ),
  'moor': KatalogEintrag(PhosphorIcons.drop, 'Moor'),
  'heide': KatalogEintrag(PhosphorIcons.plant, 'Heide'),
  'salzwiese': KatalogEintrag(PhosphorIcons.waves, 'Salzwiese'),
};

/// Artgruppe (Species `gruppe`). Karte „Kategorie“ im Profil.
const speciesGruppeKatalog = <String, KatalogEintrag>{
  'saeugetiere': KatalogEintrag(PhosphorIcons.pawPrint, 'Säugetiere'),
  'voegel': KatalogEintrag(PhosphorIcons.bird, 'Vögel'),
  'insekten': KatalogEintrag(PhosphorIcons.bug, 'Insekten'),
  'amphibien': KatalogEintrag(PhosphorIcons.fish, 'Amphibien'),
  'reptilien': KatalogEintrag(PhosphorIcons.spiral, 'Reptilien'),
  'spinnen': KatalogEintrag(PhosphorIcons.bug, 'Spinnen'),
  'baeume': KatalogEintrag(PhosphorIcons.tree, 'Bäume'),
  'straeucher': KatalogEintrag(PhosphorIcons.plant, 'Sträucher'),
  'kraeuter': KatalogEintrag(PhosphorIcons.flower, 'Kräuter'),
  'moose': KatalogEintrag(PhosphorIcons.plant, 'Moose'),
};

/// Seltenheit auf unseren Trails (Species `seltenheit`).
const seltenheitKatalog = <String, KatalogEintrag>{
  'haeufig': KatalogEintrag(PhosphorIcons.sparkle, 'Häufig'),
  'mittel': KatalogEintrag(PhosphorIcons.star, 'Mittel'),
  'selten': KatalogEintrag(PhosphorIcons.starHalf, 'Selten'),
  'sehr-selten': KatalogEintrag(PhosphorIcons.starFour, 'Sehr selten'),
};

/// Gefahr-Label (Species `gefahr` 1–5). Icon immer `warning`.
const gefahrLabels = <int, String>{
  1: 'Sehr gering',
  2: 'Gering',
  3: 'Mittel',
  4: 'Hoch',
  5: 'Nicht annähern',
};

/// Maße-Keys (Species `masse[]`). Nicht jede Art nutzt jeden Key.
const masseKatalog = <String, KatalogEintrag>{
  // Fauna
  'laenge': KatalogEintrag(PhosphorIcons.ruler, 'Länge'),
  'spannweite': KatalogEintrag(PhosphorIcons.arrowsOut, 'Spannweite'),
  'gewicht': KatalogEintrag(PhosphorIcons.barbell, 'Gewicht'),
  'alter': KatalogEintrag(PhosphorIcons.hourglass, 'Lebenserwartung'),
  'tempo': KatalogEintrag(PhosphorIcons.gauge, 'Top-Speed'),
  'gelege': KatalogEintrag(PhosphorIcons.egg, 'Gelege'),
  'tragzeit': KatalogEintrag(PhosphorIcons.calendar, 'Tragzeit'),
  // Flora
  'hoehe': KatalogEintrag(PhosphorIcons.arrowsVertical, 'Höhe'),
  'stamm': KatalogEintrag(PhosphorIcons.circle, 'Stamm'),
  'frucht': KatalogEintrag(PhosphorIcons.orange, 'Frucht'),
  'bluetezeit': KatalogEintrag(PhosphorIcons.flower, 'Blütezeit'),
};

/// Taxonomie-Ränge (Reihenfolge der Pills im Profil).
const taxonomieRanks = <String, String>{
  'reich': 'Reich',
  'stamm': 'Stamm',
  'klasse': 'Klasse',
  'ordnung': 'Ordnung',
  'familie': 'Familie',
};

const _erlebnisFallback = KatalogEintrag(PhosphorIcons.star, 'Erlebnis');
const _amenityFallback = KatalogEintrag(PhosphorIcons.mapPin, 'Ort');
const _poiFallback = KatalogEintrag(PhosphorIcons.mapPin, 'Ort');
const _tagFallback = KatalogEintrag(PhosphorIcons.tag, 'Merkmal');
const _typFallback = KatalogEintrag(PhosphorIcons.tree, 'Naturlehrpfad');
const _speciesKategorieFallback = KatalogEintrag(PhosphorIcons.leaf, 'Art');
const _geraeteFallback = KatalogEintrag(PhosphorIcons.gearSix, 'Gerät');
const _merkmalFallback = KatalogEintrag(PhosphorIcons.tag, 'Merkmal');
const _gruppeFallback = KatalogEintrag(PhosphorIcons.leaf, 'Art');
const _seltenheitFallback = KatalogEintrag(PhosphorIcons.star, 'Seltenheit');
const _masseFallback = KatalogEintrag(PhosphorIcons.ruler, 'Maß');

KatalogEintrag erlebnisEintrag(String key) {
  return _lookup(erlebnisKatalog, key, _erlebnisFallback);
}

KatalogEintrag amenityEintrag(String key) {
  return _lookup(amenityKatalog, key, _amenityFallback);
}

KatalogEintrag poiKategorieEintrag(String key) {
  return _lookup(poiKategorieKatalog, key, _poiFallback);
}

KatalogEintrag tagEintrag(String key) {
  return _lookup(tagKatalog, key, _tagFallback);
}

KatalogEintrag typEintrag(String key) {
  return _lookup(typKatalog, key, _typFallback);
}

KatalogEintrag speciesKategorieEintrag(String key) {
  return _lookup(speciesKategorieKatalog, key, _speciesKategorieFallback);
}

/// Geräte-Icon für [iconKey]; leer/null → generischer Fallback `geraet`.
KatalogEintrag geraeteEintrag(String? iconKey) {
  final key = (iconKey == null || iconKey.isEmpty) ? 'geraet' : iconKey;
  return _lookup(geraeteKatalog, key, _geraeteFallback);
}

/// Merkmal-Icon für [iconKey]; leer/null → generischer Fallback.
KatalogEintrag merkmalEintrag(String? iconKey) {
  final key = (iconKey == null || iconKey.isEmpty) ? '' : iconKey;
  return _lookup(merkmaleKatalog, key, _merkmalFallback);
}

KatalogEintrag gruppeEintrag(String key) {
  return _lookup(speciesGruppeKatalog, key, _gruppeFallback);
}

KatalogEintrag seltenheitEintrag(String key) {
  return _lookup(seltenheitKatalog, key, _seltenheitFallback);
}

KatalogEintrag masseEintrag(String key) {
  return _lookup(masseKatalog, key, _masseFallback);
}

/// Unbekannte Schlüssel (z. B. Tippfehler im JSON) werden sichtbar gemacht,
/// statt still auf den Fallback zu fallen.
KatalogEintrag _lookup(
  Map<String, KatalogEintrag> katalog,
  String key,
  KatalogEintrag fallback,
) {
  final eintrag = katalog[key];
  if (eintrag == null) {
    debugPrint('IconKatalog: unbekannter Schlüssel "$key" - Fallback genutzt');
    return fallback;
  }
  return eintrag;
}
