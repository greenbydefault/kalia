/** Mobil ist die Karte breiter als der Bildschirm. Beim Start in die Mitte scrollen. */
export function initMapViewport() {
  const viewport = document.querySelector<HTMLElement>('[data-map-viewport]');
  if (!viewport) return;
  viewport.scrollLeft = (viewport.scrollWidth - viewport.clientWidth) / 2;
}
