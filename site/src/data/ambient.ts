/**
 * Atmosphäre über der Karte. Alle Maße in px des 1920er-Canvas, in dem die SVGs exportiert wurden.
 * Atmosphere.astro rechnet das in % der Kartenbreite um. Nachjustieren hier, nicht im Markup.
 *
 * y     = Höhe in % der Karte (0 oben, 100 unten)
 * start = Fortschritt der Bahn beim Laden (0 = links draußen, 1 = rechts draußen)
 * dur   = Sekunden für eine Querung der Karte
 */

export const CANVAS_W = 1920;
const dir = '/img/ambient';

export type Cloud = {
  body: string;
  shadow: string;
  /** Maße von Wolke und Schatten in px */
  cw: number;
  ch: number;
  sw: number;
  sh: number;
  /** Versatz des Schattens relativ zur zentrierten Lage unter der Wolke, in px */
  dx: number;
  dy: number;
  y: number;
  start: number;
  dur: number;
};

export const clouds: Cloud[] = [
  { body: `${dir}/wolke-1.svg`, shadow: `${dir}/wolkenschatten-1.svg`, cw: 139, ch: 60, sw: 160, sh: 57, dx: 50, dy: 200, y: 17, start: 0.3, dur: 200 },
  { body: `${dir}/wolke-4.svg`, shadow: `${dir}/wolkenschatten-4.svg`, cw: 127, ch: 59, sw: 146, sh: 52, dx: 45, dy: 190, y: 62, start: 0.12, dur: 240 },
  { body: `${dir}/wolke-3.svg`, shadow: `${dir}/wolkenschatten-2.svg`, cw: 142, ch: 71, sw: 133, sh: 47, dx: 50, dy: 210, y: 42, start: 0.72, dur: 170 },
  { body: `${dir}/wolke-5.svg`, shadow: `${dir}/wolkenschatten-5.svg`, cw: 90, ch: 43, sw: 112, sh: 40, dx: 35, dy: 150, y: 74, start: 0.55, dur: 260 },
];

export type Crane = {
  /** Pose beim Laden und Gegenpose fürs Flattern */
  poses: [string, string];
  /** Lage im Schwarm in px (Schwarmbox {@link flock}) */
  x: number;
  y: number;
};

const k = (n: number) => `${dir}/kranich-${n}.svg`;

/** Schwarm als V, fliegt nach rechts. Box in px, Vögel sind 27 × 13 px. */
export const flock = {
  w: 100,
  h: 70,
  birdW: 27,
  y: 22,
  start: 0.35,
  dur: 55,
  /** Pause nach jeder Querung in Sekunden */
  pause: 30,
  /** Flügelschlag: Sekunden pro Pose, plus Streuung */
  flap: 0.26,
};

export const cranes: Crane[] = [
  { poses: [k(1), k(2)], x: 72, y: 28 },
  { poses: [k(2), k(3)], x: 56, y: 20 },
  { poses: [k(3), k(4)], x: 56, y: 38 },
  { poses: [k(4), k(5)], x: 40, y: 12 },
  { poses: [k(5), k(6)], x: 40, y: 46 },
  { poses: [k(6), k(7)], x: 24, y: 4 },
  { poses: [k(7), k(2)], x: 24, y: 54 },
];

export type Gull = {
  src: string;
  /** Breite in px */
  w: number;
  y: number;
  start: number;
  dur: number;
  /** 1 = nach rechts, -1 = nach links */
  dir: 1 | -1;
  /** Schaukeln im Gleitflug: Ausschlag in px und Grad (Vorzeichen = Richtung), Sekunden pro Hub */
  wobble: { y: number; rot: number; dur: number };
};

export const gulls: Gull[] = [
  { src: `${dir}/moewe-1.svg`, w: 20, y: 30, start: 0.2, dur: 85, dir: 1, wobble: { y: -4, rot: 3, dur: 3.2 } },
  { src: `${dir}/moewe-2.svg`, w: 16, y: 56, start: 0.65, dur: 105, dir: -1, wobble: { y: 5, rot: -2.5, dur: 2.6 } },
  { src: `${dir}/moewe-3.svg`, w: 22, y: 82, start: 0.4, dur: 95, dir: 1, wobble: { y: 3.5, rot: 3.5, dur: 3.8 } },
  { src: `${dir}/moewe-4.svg`, w: 15, y: 48, start: 0.85, dur: 120, dir: -1, wobble: { y: -5.5, rot: -3, dur: 3 } },
];

/* Umrechnung px im Canvas → % (für Markup und generiertes CSS) */
export const pct = (px: number) => +((px / CANVAS_W) * 100).toFixed(3);
export const rel = (px: number, of: number) => +((px / of) * 100).toFixed(3);
