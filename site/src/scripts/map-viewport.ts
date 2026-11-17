/**
 * Mobil ist die Karte breiter als der Bildschirm. Beim Start in die Mitte scrollen,
 * dort sitzen die Punkte aus map-points.ts (`mobile`). Nur solange der Nutzer noch nicht geschoben hat.
 * Erst nach dem Layout: scrollWidth zwingt den Browser sonst mitten im Start zum Umbruch.
 */
export function initMapViewport() {
  const viewport = document.querySelector<HTMLElement>('[data-map-viewport]');
  if (!viewport) return;

  let touched = false;
  const center = () => {
    if (touched) return;
    const max = viewport.scrollWidth - viewport.clientWidth;
    if (max <= 0) return;
    viewport.scrollLeft = max / 2;
  };

  requestAnimationFrame(() => requestAnimationFrame(center));
  // Breite steht manchmal erst nach dem ersten Layout (Schrift, Safe Area)
  const ro = new ResizeObserver(center);
  ro.observe(viewport);
  viewport.addEventListener(
    'pointerdown',
    () => {
      touched = true;
      ro.disconnect();
    },
    { once: true },
  );
}
