/**
 * Live-Karte: Konfiguration und Katalog-Labels. Spiegel von
 * lehrpfad_app/lib/core/config/map_config.dart und lib/shared/catalogs/icon_catalog.dart.
 */

/**
 * Tiles. Eine Stelle für den späteren Wechsel (eigener Host, MapTiler).
 * tile.openstreetmap.org hat kein SLA, vor dem Launch mit echtem Traffic neu bewerten.
 */
export const TILE_URL = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
export const TILE_SIZE = 256;
export const TILE_MAX_ZOOM = 19;
export const ATTRIBUTION =
  '© <a href="https://www.openstreetmap.org/copyright" target="_blank" rel="noopener">OpenStreetMap</a>-Mitwirkende';

/**
 * Startansicht: Müritz-Region. Zoom ist MapLibre-Zoom (512er Welt, 256er Tiles):
 * MapLibre-Zoom = flutter_map-Zoom - 1.
 */
export const START_CENTER: [number, number] = [13.0, 53.2]; // [lng, lat]
export const START_ZOOM = 8.6;
export const MIN_ZOOM = 4;
export const MAX_ZOOM = 18;

/** Umkreis wie in der App: 30 Min. Anfahrt, min = max(2, km · 1,3 / 45 · 60) → ca. 17 km Luftlinie. */
export const RADIUS_KM = (30 * 45) / 60 / 1.3;
/** Zoom auf einen Ort ohne Trail in der Nähe (App: placeZoom 12). */
export const PLACE_ZOOM = 11;
/** Mindestzoom, wenn die Kamera auf einen einzelnen Pin fährt. */
export const PIN_ZOOM = 12.5;

export const ORTE_URL = '/data/orte_de.json';

export const typLabels: Record<string, string> = {
  wald: 'Naturlehrpfad',
  moor: 'Moorlehrpfad',
  aue: 'Auenlehrpfad',
  walderlebnispfad: 'Walderlebnispfad',
  erlebniswald: 'Erlebniswald',
  naturerlebnis: 'Naturerlebnisraum',
  naturerlebnisraum: 'Naturerlebnisraum',
  waldspielplatz: 'Waldspielplatz',
  wasserspielplatz: 'Wasserspielplatz',
  waldspazierplatz: 'Waldspazierplatz',
  sinnespfad: 'Sinnespfad',
  barfusspfad: 'Barfußpfad',
  kueste: 'Küstenpfad',
  kinderbauernhof: 'Kinderbauernhof',
};

export const tagLabels: Record<string, string> = {
  kinderfreundlich: 'Kinderfreundlich',
  kinderwagentauglich: 'Kinderwagentauglich',
  rollstuhltauglich: 'Rollstuhltauglich',
  'hunde-erlaubt': 'Hunde erlaubt',
  einkehr: 'Einkehrmöglichkeit',
  spielplatz: 'Spielplatz',
  picknick: 'Picknickplatz',
  barfusspfad: 'Barfußpfad',
};

/**
 * Pin-Icon je Ortstyp. Heute überall der Baum, die Ort-Icons kommen später:
 * dann hier den Key auf ein neues <symbol id="pin-icon-…"> in LiveMap.astro zeigen lassen.
 */
export const pinIconByTyp: Record<string, string> = {};
export const PIN_ICON_DEFAULT = 'baum';
