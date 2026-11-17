/**
 * Wolken, Vögel, Mühle und Pin-Pulse laufen endlos. Ist die Karte komplett aus dem Bild, pausieren sie
 * (Klasse is-offscreen, siehe ambient.css und map.css). Sobald ein Pixel sichtbar ist, laufen sie weiter.
 */
export function initAmbient() {
  const map = document.querySelector<HTMLElement>('[data-map]');
  if (!map || !('IntersectionObserver' in window)) return;

  new IntersectionObserver((entries) => {
    for (const e of entries) map.classList.toggle('is-offscreen', !e.isIntersecting);
  }).observe(map);
}
