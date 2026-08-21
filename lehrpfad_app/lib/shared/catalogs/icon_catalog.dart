import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

/// Icon + Anzeigename für einen Katalog-Schlüssel aus den JSON-Daten.
///
/// [buildIcon] kapselt die Darstellung: Soll das Icon-Set später erneut
/// wechseln, ändert sich nur diese Klasse - nicht die Widgets.
class KatalogEintrag {
  final IconData icon;
  final String label;

  const KatalogEintrag(this.icon, this.label);

  Widget buildIcon({double? size, Color? color}) {
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

/// Amenity-Icons (Infrastruktur entlang der Route)
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
  'parkplatz-nahe': KatalogEintrag(
    PhosphorIcons.car,
    'Parkplatz in der Nähe',
  ),
  'wc-am-weg': KatalogEintrag(PhosphorIcons.toilet, 'WC am Weg'),
};

const _erlebnisFallback = KatalogEintrag(PhosphorIcons.star, 'Erlebnis');
const _amenityFallback = KatalogEintrag(PhosphorIcons.mapPin, 'Ort');
const _tagFallback = KatalogEintrag(PhosphorIcons.tag, 'Merkmal');
const _typFallback = KatalogEintrag(PhosphorIcons.tree, 'Naturlehrpfad');
const _speciesKategorieFallback = KatalogEintrag(PhosphorIcons.leaf, 'Art');
const _geraeteFallback = KatalogEintrag(PhosphorIcons.gearSix, 'Gerät');

KatalogEintrag erlebnisEintrag(String key) {
  return _lookup(erlebnisKatalog, key, _erlebnisFallback);
}

KatalogEintrag amenityEintrag(String key) {
  return _lookup(amenityKatalog, key, _amenityFallback);
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
