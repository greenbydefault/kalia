/**
 * Hörproben, zentral. Eine Stelle für Dateien, Länge und Wellenform, damit jede Karte oder
 * Sektion (AudioPlayer.astro) nur noch die ID kennt.
 *
 * Quelle der Dateien: `Sounds/Tiere/*.opus|m4a` im Repo-Root, nach `public/audio/…` kopiert.
 * Opus ist klein, m4a ist der Fallback für Browser ohne Opus (ältere Safari).
 * `duration` = Startanzeige in Sekunden, bis der Browser die echte Länge kennt.
 * `peaks` = Balkenhöhen 0 bis 1. Vorerst vom Entwurf übernommen, später durch berechnete Peaks ersetzbar.
 */

export type AudioClip = {
  sources: { src: string; type: string }[];
  duration: number;
  peaks: number[];
};

const fromDesign = (heights: number[]) => heights.map((h) => +(h / 20).toFixed(2));

export const audioClips: Record<string, AudioClip> = {
  igel: {
    sources: [
      { src: '/audio/tiere/igel.opus', type: 'audio/ogg; codecs=opus' },
      { src: '/audio/tiere/igel.m4a', type: 'audio/mp4' },
    ],
    duration: 42,
    peaks: fromDesign([
      4, 10, 16, 6, 18, 16, 10, 10, 12, 16, 12, 20, 12, 8, 4, 4, 10, 16, 10, 18, 18, 18, 10, 10, 10,
      10, 10, 18, 4, 4, 4, 18, 4, 10, 18, 16, 10, 16, 12, 12, 12, 4, 8, 6, 8, 4,
    ]),
  },
};
