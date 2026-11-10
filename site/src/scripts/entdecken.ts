import { initTabs } from './tabs';

/**
 * Entdecken (Gebiete | Arten): der Umschalter selbst steckt in tabs.ts.
 * Hier nur, was zu den Karten gehört: offene Flip-Karten zurückdrehen und Slider auf Anfang.
 */
export function initEntdecken() {
  initTabs('[data-entdecken]', {
    beforeSwap(oldPanel) {
      oldPanel.querySelectorAll<HTMLElement>('[data-front][aria-expanded="true"]').forEach((front) => {
        front.closest<HTMLElement>('[data-area-flip]')?.querySelector<HTMLElement>('[data-close]')?.click();
      });
    },
    afterSwap(newPanel) {
      newPanel.querySelectorAll<HTMLElement>('[data-slider-viewport]').forEach((v) => (v.scrollLeft = 0));
    },
  });
}
