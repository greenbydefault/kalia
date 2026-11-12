import type { IconName } from '../icons';

/**
 * Sektion "So einfach wird euer nächster Ausflug" (components/Ausflug.astro): ein Eintrag pro Tab.
 * Texte und Bilder stehen nur hier, am Markup ändert sich beim Befüllen nichts.
 *
 * Bilder liegen unter public/img/ausflug/. Karte (`bg`) und App-Ansicht (`screen`) sind Platzhalter:
 * Datei austauschen oder den Pfad pro Tab ändern. Beide Bilder gleich groß halten
 * (Karte 1200 x 1090, App-Ansicht 390 x 844), sonst springt das Layout.
 * `placeholder: true` erzeugt beim Build eine Warnung, bis der Tab fertig ist.
 */
export const TEXT_MAX = 300;

export interface AusflugChip {
  label: string;
  /** TODO(icon): Chip-Icons folgen, bis dahin überall das gleiche. */
  icon?: IconName;
}

export interface AusflugTab {
  id: string;
  label: string;
  icon: IconName;
  /** Zeilen der Überschrift, der Umbruch folgt dem Entwurf. */
  title: string[];
  text: string;
  /** Genau drei Kacheln: Label oben, Wert fett darunter. */
  facts: { label: string; value: string }[];
  chipsLabel: string;
  chips: AusflugChip[];
  link: { label: string; href: string };
  /** Dekorativer Karten-Hintergrund (alt ist leer). */
  bg: string;
  /** Inhalt im Handy und seine Beschreibung für Screenreader. */
  screen: { src: string; alt: string };
  placeholder?: boolean;
}

export const kopf = {
  /** TODO(text): Badge aus dem Entwurf, Wortlaut offen. */
  badge: 'Gebiete',
  /** Zeilen der Sektionsüberschrift, Umbruch wie im Entwurf. */
  title: ['So einfach', 'wird euer nächster Ausflug'],
  lead: 'Kalia hilft euch, den passenden Pfad zu finden, entspannt hinzukommen und unterwegs mehr zu entdecken. Gemacht für Familien mit Kindern.',
};

export const aktionen = {
  cta: { label: 'Auf die Warteliste', href: '#liste' },
};

const BG = '/img/ausflug/karte-platzhalter.webp';
const SCREEN = '/img/ausflug/screen-platzhalter.webp';
const CHIP_ICON: IconName = 'hinkommen';
const chips = (...labels: string[]): AusflugChip[] => labels.map((label) => ({ label, icon: CHIP_ICON }));

/** Platzhalter in Länge und Form der fertigen Texte, damit das Layout stimmt. */
const todoFacts = [
  { label: 'Kachel eins', value: 'Wert folgt später' },
  { label: 'Kachel zwei', value: 'Wert folgt später' },
  { label: 'Kachel drei', value: 'Wert folgt später' },
];
const todoLink = { label: 'Platzhalter für den Textlink.', href: '#karte' };
const todoScreenAlt = 'Platzhalter: Ansicht der Kalia-App, folgt.';

export const ausflugTabs: AusflugTab[] = [
  {
    id: 'ausflug-finden',
    label: 'Finden',
    icon: 'suchen',
    title: ['Findet', 'den passenden Pfad'],
    text: 'Ob Bohlenweg durchs Moor, Dünenpfad an der Küste oder Rundweg durch den Wald: Kalia zeigt euch kurze Naturpfade in eurer Nähe. Filtert nach Länge, Dauer, Kinderwagen oder Einkehr und wisst schon vor dem Losfahren, ob der Weg zu eurem Tag passt.',
    facts: [
      { label: 'Länge und Dauer', value: 'Für jeden Pfad angegeben' },
      { label: 'Kinderwagen', value: 'Bei jedem Pfad markiert' },
      { label: 'Neue Pfade', value: 'Täglich mehr' },
    ],
    chipsLabel: 'Filtert nach',
    chips: chips('Kinderwagen', 'Spielplatz', 'Einkehr', 'Rundweg', 'Rollstuhltauglich'),
    // TODO(text): Wortlaut aus dem Entwurf übernommen, offensichtlich Platzhalter.
    link: { label: 'Pfad in euer näher neuer Ansicht.', href: '#karte' },
    bg: BG,
    screen: { src: SCREEN, alt: 'Kalia-App: Karte mit dem Waldlehrpark Warberge und seinen Eckdaten.' },
  },
  {
    id: 'ausflug-hinkommen',
    label: 'Hinkommen',
    icon: 'hinkommen',
    title: ['Titel für', 'Hinkommen'],
    text: 'Platzhalter: Hier steht später, wie Kalia euch zum Pfad bringt. Zwei, drei Sätze zur Anreise, zur Wegbeschreibung und zu dem, was euch am Start erwartet, damit der Ausflug schon vor dem Losfahren sicher steht und niemand suchen muss.',
    facts: todoFacts,
    chipsLabel: 'Beschriftung folgt',
    chips: chips('Stichwort eins', 'Stichwort zwei', 'Stichwort drei', 'Stichwort vier', 'Stichwort fünf'),
    link: todoLink,
    bg: BG,
    screen: { src: SCREEN, alt: todoScreenAlt },
    placeholder: true,
  },
  {
    id: 'ausflug-zuhoeren',
    label: 'Zuhören',
    icon: 'zuhoeren',
    title: ['Titel für', 'Zuhören'],
    text: 'Platzhalter: Hier steht später, wie Kalia den Weg zum Hören macht. Zwei, drei Sätze zu den kurzen Audiotexten, zu Arten am Wegesrand und dazu, dass Kinder zuhören können, ohne dass jemand vorlesen muss oder das Handy in der Hand bleibt.',
    facts: todoFacts,
    chipsLabel: 'Beschriftung folgt',
    chips: chips('Stichwort eins', 'Stichwort zwei', 'Stichwort drei', 'Stichwort vier', 'Stichwort fünf'),
    link: todoLink,
    bg: BG,
    screen: { src: SCREEN, alt: todoScreenAlt },
    placeholder: true,
  },
  {
    id: 'ausflug-sammeln',
    label: 'Sammeln',
    icon: 'sammeln',
    title: ['Titel für', 'Sammeln'],
    text: 'Platzhalter: Hier steht später, was es zu sammeln gibt. Zwei, drei Sätze zu Arten, Karten und Entdeckungen, die Kinder unterwegs freischalten, und dazu, wie aus einem einzelnen Ausflug nach und nach eine kleine eigene Sammlung wird.',
    facts: todoFacts,
    chipsLabel: 'Beschriftung folgt',
    chips: chips('Stichwort eins', 'Stichwort zwei', 'Stichwort drei', 'Stichwort vier', 'Stichwort fünf'),
    link: todoLink,
    bg: BG,
    screen: { src: SCREEN, alt: todoScreenAlt },
    placeholder: true,
  },
];

const open: string[] = [];
for (const t of ausflugTabs) {
  if (t.text.length > TEXT_MAX) {
    throw new Error(`ausflug.ts: Text "${t.id}" hat ${t.text.length} Zeichen, erlaubt sind ${TEXT_MAX}`);
  }
  if (t.facts.length !== 3) throw new Error(`ausflug.ts: "${t.id}" braucht genau drei Fakten, hat ${t.facts.length}`);
  if (t.placeholder) open.push(t.id);
}
if (open.length) console.warn(`[ausflug] ${open.length} Tabs mit Platzhaltertext: ${open.join(', ')}`);
