/**
 * Live-Karte: Einstieg. MapLibre, Supercluster und das Karten-CSS sind ein eigener Chunk,
 * der erst lädt, wenn die Sektion fast im Bild ist (kein Gewicht im Hero).
 */
export function initLiveMap() {
  const root = document.querySelector<HTMLElement>('[data-live-map]');
  if (!root) return;

  const start = () => {
    import('./mount')
      .then((m) => m.mountLiveMap(root))
      .catch((err) => console.error('Live-Karte konnte nicht starten', err));
  };

  if (!('IntersectionObserver' in window)) return start();

  const io = new IntersectionObserver(
    (entries) => {
      if (!entries.some((e) => e.isIntersecting)) return;
      io.disconnect();
      start();
    },
    { rootMargin: '400px 0px' },
  );
  io.observe(root);
}
