/**
 * Arten-Karten, zentral. Eine Karte = ein Eintrag, genutzt von SpeciesCard.astro
 * (Variante `pop` im Hero, `inline` für andere Abschnitte).
 * Texte aus `lehrpfad_app/assets/seed/species.json` (Stand Okt 2026), fest eingetragen, nicht live.
 * Vor Livegang gegen den Katalog prüfen. Ton: `audio` verweist auf data/audio.ts.
 */

export type SpeciesCardData = {
  id: string;
  name: string;
  kicker: string;
  illustration: string;
  illustrationAlt: string;
  chips: { label: string; accent?: boolean }[];
  text: string;
  audio: string;
};

export const speciesCards: Record<string, SpeciesCardData> = {
  igel: {
    id: 'igel',
    name: 'Igel',
    kicker: 'Fauna',
    illustration: '/img/cards/igel.svg',
    illustrationAlt: 'Illustration eines Igels',
    // Gruppe · Merkmal · Seltenheit (species.json: gruppe, merkmal, seltenheit; Labels aus seltenheitKatalog)
    chips: [{ label: 'Säugetier', accent: true }, { label: 'Nachtaktiv' }, { label: 'Mittel' }],
    text: 'Nachts knistert das Laub – tagsüber verrät oft nur das Versteck, dass er da war. Er rollt sich zur Kugel, wenn Gefahr droht. Nachtjäger: Käfer, Regenwürmer und Schnecken stehen auf dem Speiseplan.',
    audio: 'igel',
  },
};
