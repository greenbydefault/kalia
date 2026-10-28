/**
 * Natur-Karten. Später aus dem Katalog (Gebiete) ableitbar, solange bleibt das hier die einzige Quelle.
 */
/**
 * Arten-Illustrationen für die Kacheln auf der Rückseite. Ein Pool für alle Gebiete:
 * Illustration ablegen unter public/img/arten/{id}.svg, hier eintragen, in `back.arten` nennen.
 */
export const artenPool = {
  libelle: 'Libelle',
  wollgras: 'Wollgras',
  graureiher: 'Graureiher',
  stockente: 'Stockente',
  schwan: 'Schwan',
  biber: 'Biber',
  blaesshuhn: 'Blässhuhn',
  eisvogel: 'Eisvogel',
  graugans: 'Graugans',
  haubentaucher: 'Haubentaucher',
  seeadler: 'Seeadler',
  kormoran: 'Kormoran',
  austernfischer: 'Austernfischer',
  silbermoewe: 'Silbermöwe',
  buntspecht: 'Buntspecht',
  eichelhaeher: 'Eichelhäher',
  eichhoernchen: 'Eichhörnchen',
  kleiber: 'Kleiber',
  buchfink: 'Buchfink',
  maeusebussard: 'Mäusebussard',
  reh: 'Reh',
  rotkehlchen: 'Rotkehlchen',
  moorfrosch: 'Moorfrosch',
} as const;
export type ArtId = keyof typeof artenPool;

/**
 * Drei feste Fakten-Slots für jedes Gebiet. Labels und Reihenfolge stehen hier einmal,
 * die Werte pro Gebiet in `back.fakten`. Werte kurz halten (2 Zeilen in ~75 px Breite).
 */
export const faktenSlots = [
  { key: 'zeit', label: 'Beste Zeit' },
  { key: 'mitbringen', label: 'Mitbringen' },
  { key: 'besonderes', label: 'Highlight' },
] as const;
export type Fakten = Record<(typeof faktenSlots)[number]['key'], string>;

/**
 * Rückseite einer Gebiets-Card. Nur Karten mit `back` flippen.
 * Szene liegt per Konvention unter /img/cards/{id}/szene.svg, Titel = Kartentitel, Label ist fest.
 * `text`: höchstens drei Zeilen in der schmalsten Karte (Vier-Spalten-Raster ab 70rem, 214 px Text),
 * gemessen rund 85 Zeichen. Längere Texte brechen den Build ab.
 */
export const BACK_TEXT_MAX = 85;
export type AreaBack = { text: string; fakten: Fakten; arten: ArtId[] };

/** Die drei Mini-Karten der Vorderseite als eigene Ebenen (gleiche Größe, 315 x 237). */
export type AreaLayers = { grey: string; blue: string; mid: string };

export type Area = {
  id: string;
  title: string;
  text: string;
  image: string;
  layers?: AreaLayers;
  back?: AreaBack;
};

export const areas: Area[] = [
  {
    id: 'moor',
    title: 'Moor',
    text: 'Holzstege, Aussichtsturm, Libellen und Reiher. Hier wird es still und ein bisschen geheimnisvoll.',
    image: '/img/cards/moor.svg',
    layers: {
      grey: '/img/cards/moor/grau.svg',
      blue: '/img/cards/moor/blau.svg',
      mid: '/img/cards/moor/mitte.svg',
    },
    // Texte aus species.json (Biber: baut nachts, Schwan: gleitet)
    back: {
      text: 'Holzstege über nassem Grund. Der Biber baut nachts, der Schwan gleitet vorbei.',
      // Platzhalter, vor Livegang gegen Katalog prüfen
      fakten: { zeit: 'Mai – Juni', mitbringen: 'Festes Schuhwerk', besonderes: 'Moor wächst 1 mm/Jahr' },
      arten: ['stockente', 'schwan', 'biber', 'moorfrosch'],
    },
  },
  {
    id: 'kueste',
    title: 'Küste',
    text: 'Leuchtturm, Möwen, Wind in den Haaren. Kurze Wege am Wasser, die sich nach Urlaub anfühlen.',
    image: '/img/cards/kueste.svg',
    layers: {
      grey: '/img/cards/kueste/grau.svg',
      blue: '/img/cards/kueste/blau.svg',
      mid: '/img/cards/kueste/mitte.svg',
    },
    // Texte aus species.json (Seeadler: kreist, Kormoran: trocknet die Flügel auf Pfählen)
    back: {
      text: 'Der Seeadler kreist überm Watt, der Kormoran trocknet die Flügel am Pfahl.',
      // Platzhalter, vor Livegang gegen Katalog prüfen
      fakten: { zeit: 'April – Juli', mitbringen: 'Fernglas', besonderes: 'Seeadler: 2,40 m breit' },
      arten: ['seeadler', 'kormoran', 'austernfischer', 'silbermoewe'],
    },
  },
  {
    id: 'heide',
    title: 'Heide',
    text: 'Weite Flächen, blühende Heide und Schafe am Wegrand. Viel Platz zum Laufen.',
    image: '/img/cards/heide.svg',
    layers: {
      grey: '/img/cards/heide/grau.svg',
      blue: '/img/cards/heide/blau.svg',
      mid: '/img/cards/heide/mitte.svg',
    },
    // Test-Inhalt: Arten sind Platzhalter.
    back: {
      text: 'Im Spätsommer blüht alles lila. Schafe halten das Kraut kurz, die Libelle jagt.',
      // Platzhalter, vor Livegang gegen Katalog prüfen
      fakten: { zeit: 'Aug – Sep', mitbringen: 'Sonnenschutz', besonderes: 'Schafe pflegen die Heide' },
      arten: ['libelle', 'wollgras', 'graureiher'],
    },
  },
  {
    id: 'fluss-seen',
    title: 'Fluss & Seen',
    text: 'Schwäne, Schilf und Weiden am Ufer. Zum Schauen, Staunen und Steine werfen.',
    image: '/img/cards/fluss-seen.svg',
    layers: {
      grey: '/img/cards/fluss-seen/grau.svg',
      blue: '/img/cards/fluss-seen/blau.svg',
      mid: '/img/cards/fluss-seen/mitte.svg',
    },
    // Texte aus species.json (Eisvogel: Sturz vom Ast)
    back: {
      text: 'Schilf am Rand, ein Ast überm Wasser. Von dort stürzt der Eisvogel kopfüber.',
      // Platzhalter, vor Livegang gegen Katalog prüfen
      fakten: { zeit: 'April – Juni', mitbringen: 'Fernglas', besonderes: 'Schwimmende Nester' },
      arten: ['blaesshuhn', 'eisvogel', 'graugans', 'haubentaucher'],
    },
  },
  {
    id: 'baumkronenpfad',
    title: 'Baumkronenpfad',
    text: 'Stege und Türme zwischen den Wipfeln. Der Specht klopft fast auf Augenhöhe.',
    image: '/img/cards/baumkronenpfad/mitte.svg',
    layers: {
      grey: '/img/cards/baumkronenpfad/grau.svg',
      blue: '/img/cards/baumkronenpfad/blau.svg',
      mid: '/img/cards/baumkronenpfad/mitte.svg',
    },
    // Texte aus species.json (Buntspecht: klopft, Kleiber: läuft kopfabwärts)
    back: {
      text: 'Der Specht klopft auf Augenhöhe, der Kleiber läuft kopfunter den Stamm hinab.',
      // Platzhalter, vor Livegang gegen Katalog prüfen
      fakten: { zeit: 'Mai – Sep', mitbringen: 'Fernglas', besonderes: 'Wipfel auf Augenhöhe' },
      arten: ['buntspecht', 'eichelhaeher', 'eichhoernchen', 'kleiber'],
    },
  },
  {
    id: 'wald',
    title: 'Wald',
    text: 'Hohe Tannen, Farn und Fliegenpilze. Am Waldrand steht ein Reh und wartet, ob ihr leise genug seid.',
    image: '/img/cards/wald/mitte.svg',
    layers: {
      grey: '/img/cards/wald/grau.svg',
      blue: '/img/cards/wald/blau.svg',
      mid: '/img/cards/wald/mitte.svg',
    },
    // Texte aus species.json (Reh: am Waldrand, weg zwischen zwei Blicken; Mäusebussard: kreist über der Schneise)
    back: {
      text: 'Am Waldrand steht ein Reh, über der Schneise kreist der Mäusebussard.',
      // Platzhalter, vor Livegang gegen Katalog prüfen
      fakten: { zeit: 'Mai – Okt', mitbringen: 'Zeckenschutz', besonderes: 'Rehe bellen wie Hunde' },
      arten: ['reh', 'maeusebussard', 'buchfink', 'rotkehlchen'],
    },
  },
];

for (const a of areas) {
  if (a.back && a.back.text.length > BACK_TEXT_MAX) {
    throw new Error(`areas.ts: Rückseitentext "${a.id}" hat ${a.back.text.length} Zeichen, erlaubt sind ${BACK_TEXT_MAX}`);
  }
}
