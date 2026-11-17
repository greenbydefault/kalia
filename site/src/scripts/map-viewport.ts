/**
 * Mobil ist die Karte breiter als der Bildschirm. Beim Start in die Mitte scrollen.
 * Erst nach dem ersten Frame: scrollWidth/scrollLeft zwingen den Browser sonst mitten im Start zum Layout (Forced Reflow).
 */
export function initMapViewport() {
  const viewport = document.querySelector<HTMLElement>('[data-map-viewport]');
  if (!viewport) return;
  requestAnimationFrame(() =>
    requestAnimationFrame(() => {
      viewport.scrollLeft = (viewport.scrollWidth - viewport.clientWidth) / 2;
    }),
  );
}
