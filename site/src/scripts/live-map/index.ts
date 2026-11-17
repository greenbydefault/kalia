/**
 * Live-Karte: Einstieg. MapLibre, Supercluster und das Karten-CSS sind ein eigener Chunk,
 * der erst lädt, wenn die Sektion fast im Bild ist (kein Gewicht im Hero).
 *
 * Zwei Stufen, beide in einer Leerlaufphase des Main-Threads statt mitten in einem Frame:
 * ab PRELOAD wird der Chunk geladen und ausgewertet (das ist der teure Parse), ab MOUNT wird die Karte gebaut.
 */
const PRELOAD = '1500px 0px';
const MOUNT = '400px 0px';

const idle = (fn: () => void, timeout: number) =>
  'requestIdleCallback' in window ? requestIdleCallback(fn, { timeout }) : setTimeout(fn, 1);

export function initLiveMap() {
  const root = document.querySelector<HTMLElement>('[data-live-map]');
  if (!root) return;

  let chunk: Promise<typeof import('./mount')> | null = null;
  // Schlägt das Vorladen fehl, versucht es der Start noch einmal
  const load = () =>
    (chunk ??= import('./mount').catch((err) => {
      chunk = null;
      throw err;
    }));

  const start = () => {
    load()
      .then((m) => m.mountLiveMap(root))
      .catch((err) => console.error('Live-Karte konnte nicht starten', err));
  };

  if (!('IntersectionObserver' in window)) return start();

  const near = (margin: string, fn: () => void) => {
    const io = new IntersectionObserver(
      (entries) => {
        if (!entries.some((e) => e.isIntersecting)) return;
        io.disconnect();
        fn();
      },
      { rootMargin: margin },
    );
    io.observe(root);
  };

  near(PRELOAD, () => idle(() => load().catch(() => {}), 2000));
  near(MOUNT, () => idle(start, 300));
}
