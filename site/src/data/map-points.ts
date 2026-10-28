/**
 * Punkte auf der Karte. Positionen in Prozent des Kartenbilds.
 * Nur Punkte mit `pop` lösen Spotlight + Popover aus (`kind: 'area'` = Kennzahlen, `kind: 'species'` = Arten-Karte mit Ton). Die anderen sind echte Buttons, aber noch ohne Timeline.
 * Alle Zahlen sind aus dem Seed (`lehrpfad_app/assets/seed`, Stand Okt 2026, 105 Trails) fest eingetragen, nicht live.
 * Gebiet-Chips: Trails = Anzahl je `gebiet`, Stationen = Summe, Arten = verschiedene Artnamen über alle Trails des Gebiets.
 * Heide-Erlebnisweg ist ein einzelner Trail (Zahlen aus dessen Seed). Vor Livegang gegen den Katalog prüfen.
 */
export type AreaPopover = {
  /** Gebiet oder Trail: Kennzahlen, Tags, Beispiel-Trail */
  kind: 'area';
  kicker: string;
  /** `dec` = Nachkommastellen beim Hochzählen */
  stats: { label: string; value: number; dec?: number }[];
  tags: string[];
  trail: { kicker: string; name: string; meta: string };
  cta: { label: string; href: string };
};

/** Arten-Karte mit Hörprobe. Inhalt kommt zentral aus data/species-cards.ts, hier nur der Verweis. */
export type SpeciesPopover = {
  kind: 'species';
  ref: string;
};

export type MapPopover = AreaPopover | SpeciesPopover;

export type MapPoint = {
  id: string;
  kind: 'chip' | 'dot';
  label: string;
  meta?: string;
  x: number;
  y: number;
  icon: string;
  pop?: MapPopover;
};

const TREE = '/img/icons/tree.svg';

export const mapPoints: MapPoint[] = [
  {
    id: 'bauernhof',
    kind: 'chip',
    label: 'Bauernhof',
    meta: '2 Trails',
    x: 11,
    y: 36.5,
    icon: TREE,
    pop: {
      kind: 'area',
      kicker: 'Gebiet',
      stats: [
        { label: 'Trails', value: 2 },
        { label: 'Stationen', value: 8 },
        { label: 'Arten', value: 10 },
      ],
      tags: ['Kinderfreundlich', 'Spielplatz', 'Rollstuhltauglich'],
      trail: { kicker: 'Zum Beispiel', name: 'Kinderbauernhof am Mauerplatz', meta: '90 Min.' },
      cta: { label: 'Auf die Warteliste', href: '#liste' },
    },
  },
  {
    id: 'heiderundweg',
    kind: 'chip',
    label: 'Heide-Erlebnisweg',
    meta: '11,4 km',
    x: 29.5,
    y: 68.5,
    icon: TREE,
    pop: {
      kind: 'area',
      kicker: 'Trail',
      stats: [
        { label: 'Kilometer', value: 11.4, dec: 1 },
        { label: 'Minuten', value: 210 },
        { label: 'Stationen', value: 11 },
      ],
      tags: ['Kinderfreundlich', 'Hunde erlaubt', 'Picknick'],
      trail: { kicker: 'Betreiber', name: 'Heinz Sielmann Stiftung', meta: 'Ostprignitz-Ruppin, Brandenburg' },
      cta: { label: 'Auf die Warteliste', href: '#liste' },
    },
  },
  {
    id: 'wald',
    kind: 'chip',
    label: 'Wald',
    meta: '75 Trails',
    x: 66.3,
    y: 39,
    icon: TREE,
    pop: {
      kind: 'area',
      kicker: 'Gebiet',
      stats: [
        { label: 'Trails', value: 75 },
        { label: 'Stationen', value: 573 },
        { label: 'Arten', value: 113 },
      ],
      tags: ['Kinderwagen', 'Spielplatz', 'Einkehr'],
      trail: { kicker: 'Zum Beispiel', name: 'Baumkronenpfad Ivenacker Eichen', meta: '0,62 km · 60 Min.' },
      cta: { label: 'Auf die Warteliste', href: '#liste' },
    },
  },
  {
    id: 'kueste',
    kind: 'chip',
    label: 'Küste',
    meta: '6 Trails',
    x: 86.6,
    y: 24,
    icon: TREE,
    pop: {
      kind: 'area',
      kicker: 'Gebiet',
      stats: [
        { label: 'Trails', value: 6 },
        { label: 'Stationen', value: 52 },
        { label: 'Arten', value: 31 },
      ],
      tags: ['Kinderfreundlich', 'Kinderwagen', 'Einkehr'],
      trail: { kicker: 'Zum Beispiel', name: 'Erlebnisrundweg Friedrichskoog-Spitze', meta: '3,8 km · 55 Min.' },
      cta: { label: 'Auf die Warteliste', href: '#liste' },
    },
  },
  {
    id: 'heide',
    kind: 'chip',
    label: 'Heide',
    meta: '2 Trails',
    x: 88.6,
    y: 63.3,
    icon: TREE,
    pop: {
      kind: 'area',
      kicker: 'Gebiet',
      stats: [
        { label: 'Trails', value: 2 },
        { label: 'Stationen', value: 22 },
        { label: 'Arten', value: 24 },
      ],
      tags: ['Kinderfreundlich', 'Hunde erlaubt', 'Picknick'],
      trail: { kicker: 'Zum Beispiel', name: 'Archäologischer Wanderpfad Fischbeker Heide', meta: '3 km · 90 Min.' },
      cta: { label: 'Auf die Warteliste', href: '#liste' },
    },
  },
  {
    id: 'schutzhuette',
    kind: 'dot',
    label: 'Schutzhütte',
    x: 38.9,
    y: 28.5,
    icon: TREE,
    pop: { kind: 'species', ref: 'igel' },
  },
  { id: 'windmuehle', kind: 'dot', label: 'Windmühle', x: 72.5, y: 57.1, icon: TREE },
];
