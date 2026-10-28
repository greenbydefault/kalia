import { clouds, cranes, flock, gulls, pct, rel } from './ambient';
import { mapPoints } from './map-points';

/**
 * Baut aus den Daten (map-points.ts, ambient.ts) das CSS für Positionen und Bahnen.
 * Wird als /positions.css ausgeliefert (pages/positions.css.ts). Kein style="" im Markup,
 * die Komponenten tragen nur Klassen (.map__point--{id}, .cloud--{i}, .bird--{i}, .gull--{i}).
 * Nachjustieren in den Datendateien, nicht hier.
 *
 * Bahnen: Start links außerhalb (inkl. Platz für Schatten), Ziel kurz hinter dem rechten Rand.
 * 10000 / w = Kartenbreite in Elementbreiten, daher reichen Prozent der eigenen Breite.
 */

const OFF_LEFT = -170;
const offRight = (w: number) => +(10000 / w + 70).toFixed(2);
const n = (v: number) => +v.toFixed(3);

/** Sehr schlichte, feste Streuung (Goldener Schnitt) statt Zufall, damit das CSS stabil bleibt */
const spread = (i: number, mul: number) => (i * mul) % 1;

function lane(w: number, dir: 1 | -1) {
  const r = offRight(w);
  return dir === 1 ? { from: OFF_LEFT, to: r } : { from: r, to: OFF_LEFT };
}

export function buildPositionsCss(): string {
  const out: string[] = ['/* GENERIERT aus data/map-points.ts und data/ambient.ts. Nicht von Hand ändern. */'];

  // Pins
  for (const p of mapPoints) {
    out.push(`.map__point--${p.id} { --x: ${p.x}; --y: ${p.y}; }`);
  }

  // Wolken (samt Schatten)
  clouds.forEach((c, i) => {
    const w = pct(c.cw);
    const { from, to } = lane(w, 1);
    out.push(
      `.cloud--${i} { --y: ${c.y}; --w: ${w}; --from: ${from}; --to: ${to}; animation-duration: ${c.dur}s; animation-delay: ${n(-c.start * c.dur)}s; }`,
      `.cloud--${i} .cloud__shadow { left: ${rel((c.cw - c.sw) / 2 + c.dx, c.cw)}%; top: ${rel((c.ch - c.sh) / 2 + c.dy, c.ch)}%; width: ${rel(c.sw, c.cw)}%; }`,
    );
  });

  // Kranichschwarm: eigene Keyframes, weil nach jeder Querung eine Pause kommt
  {
    const w = pct(flock.w);
    const { from, to } = lane(w, 1);
    const total = flock.dur + flock.pause;
    const run = n((flock.dur / total) * 100);
    out.push(
      `@keyframes flock-travel {`,
      `  0% { translate: ${from}% 140%; }`,
      `  ${run}%, 100% { translate: ${to}% -140%; }`,
      `}`,
      `.flock { --y: ${flock.y}; --w: ${w}; aspect-ratio: ${flock.w} / ${flock.h}; animation-name: flock-travel; animation-duration: ${total}s; animation-delay: ${n(-flock.start * flock.dur)}s; }`,
    );
    cranes.forEach((b, i) => {
      // Flügelschlag: Sekunden pro Pose, je Vogel leicht versetzt
      const pose = flock.flap * (0.85 + 0.3 * spread(i, 0.618));
      const delay = flock.flap * spread(i, 0.382);
      out.push(
        `.bird--${i} { left: ${rel(b.x, flock.w)}%; top: ${rel(b.y, flock.h)}%; width: ${rel(flock.birdW, flock.w)}%; }`,
        `.bird--${i} img { animation-duration: ${n(pose * 2)}s; animation-delay: ${n(delay)}s; }`,
      );
    });
  }

  // Möwen: Bahn + Schaukeln als zwei Animationen (Reihenfolge wie in .gull)
  gulls.forEach((g, i) => {
    const w = pct(g.w);
    const { from, to } = lane(w, g.dir);
    out.push(
      `.gull--${i} { --y: ${g.y}; --w: ${w}; --from: ${from}; --to: ${to}; --wy: ${g.wobble.y}; --wr: ${g.wobble.rot}; animation-duration: ${g.dur}s, ${g.wobble.dur}s; animation-delay: ${n(-g.start * g.dur)}s, 0s; }`,
    );
  });

  return out.join('\n') + '\n';
}
