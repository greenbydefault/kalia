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
  badge: 'In vier Schritten',
  /** Zeilen der Sektionsüberschrift, Umbruch wie im Entwurf. */
  title: ['So einfach', 'wird euer nächster Ausflug'],
  lead: 'Kalia hilft euch, den passenden Pfad zu finden, entspannt hinzukommen und unterwegs mehr zu entdecken. Gemacht für Familien mit Kindern.',
};

export const aktionen = {
  cta: { label: 'Auf die Warteliste', href: '#liste' },
};

const BG = '/img/ausflug/karte-platzhalter.avif';
const SCREEN = '/img/ausflug/screen-platzhalter.avif';
const CHIP_ICON: IconName = 'hinkommen';
const chips = (...labels: string[]): AusflugChip[] => labels.map((label) => ({ label, icon: CHIP_ICON }));
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
    link: { label: 'schaut auf der Karte, was in eurer Nähe liegt.', href: '#karte' },
    bg: BG,
    screen: { src: SCREEN, alt: 'Kalia-App: Karte mit dem Waldlehrpark Warberge und seinen Eckdaten.' },
  },
  {
    id: 'ausflug-hinkommen',
    label: 'Hinkommen',
    icon: 'hinkommen',
    title: ['Fahrt direkt', 'zum Startpunkt'],
    text: 'Bei jedem Pfad steht, wie lange ihr ab eurem Startpunkt mit dem Auto braucht. Ein Tipp öffnet die Navigation in Google Maps, Apple Karten oder OpenStreetMap, direkt zum Parkplatz, wenn es einen gibt. Café, Badestelle oder Hofladen bis 20 Minuten vom Pfad stehen gleich dabei.',
    facts: [
      { label: 'Anfahrt', value: 'In Minuten ab eurem Startpunkt' },
      { label: 'Navigation', value: 'Google, Apple oder OSM' },
      { label: 'Rund um den Pfad', value: 'Orte bis 20 Min entfernt' },
    ],
    chipsLabel: 'In der Nähe',
    chips: chips('Café', 'Restaurant', 'Badestelle', 'Hofladen', 'Museum'),
    link: { label: 'sucht euren Ort auf der Karte.', href: '#karte' },
    bg: BG,
    screen: { src: SCREEN, alt: 'Kalia-App: Navigation zum Startpunkt eines Pfades mit Auswahl der Karten-App.' },
  },
  {
    id: 'ausflug-zuhoeren',
    label: 'Zuhören',
    icon: 'zuhoeren',
    title: ['Hört zu,', 'was am Weg passiert'],
    text: 'Zu jedem Pfad und zu vielen Arten am Weg gibt es ein kurzes Hörstück, eingesprochen und keine Minute lang. Ihr tippt auf Hören, steckt das Handy weg und lauft weiter. Niemand muss eine Tafel vorlesen, die Augen bleiben beim Weg.',
    facts: [
      { label: 'Länge', value: 'Unter einer Minute' },
      { label: 'Pfade', value: 'Ein Hörstück pro Pfad' },
      { label: 'Arten', value: 'Tiere, Pflanzen, Spielgeräte' },
    ],
    chipsLabel: 'Zu hören',
    chips: chips('Pfade', 'Vögel', 'Bäume', 'Amphibien', 'Spielgeräte'),
    link: { label: 'findet einen Pfad in eurer Nähe.', href: '#karte' },
    bg: BG,
    screen: { src: SCREEN, alt: 'Kalia-App: Hörstück zu einem Pfad im Player.' },
  },
  {
    id: 'ausflug-sammeln',
    label: 'Sammeln',
    icon: 'sammeln',
    title: ['Sammelt,', 'was ihr unterwegs seht'],
    text: 'Am Steg sitzt ein Eisvogel? Antippen, "Hab gesehen" wählen, schon liegt er in eurer Sammlung. Tiere, Pflanzen und Spielgeräte, nach Gruppen sortiert. Was noch fehlt, zeigt Kalia mit dem Pfad in eurer Nähe, auf dem die Chancen gut stehen. Alles bleibt auf dem Handy, ohne Konto.',
    facts: [
      { label: 'Freischalten', value: 'Vor Ort mit Hab gesehen' },
      { label: 'Noch offen', value: 'Mit Pfad in eurer Nähe' },
      { label: 'Konto', value: 'Nicht nötig' },
    ],
    chipsLabel: 'Sammelt',
    chips: chips('Vögel', 'Bäume', 'Säugetiere', 'Insekten', 'Spielgeräte'),
    link: { label: 'schaut, welche Arten es zu sammeln gibt.', href: '#gebiete' },
    bg: BG,
    screen: { src: SCREEN, alt: 'Kalia-App: Sammlung mit gefundenen und offenen Arten.' },
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
