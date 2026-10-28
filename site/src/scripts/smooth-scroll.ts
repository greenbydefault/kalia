import Lenis from 'lenis';
import { gsap } from 'gsap';
import { prefersReducedMotion } from './motion';

/**
 * Smooth Scroll für die Seite (Lenis), getaktet über den GSAP-Ticker.
 * Touch bleibt nativ (Lenis glättet nur Wheel/Trackpad-Maus). Anker-Links scrollt Lenis selbst.
 * Bei "Bewegung reduzieren" läuft nichts.
 */
export function initSmoothScroll() {
  if (prefersReducedMotion()) return;

  const lenis = new Lenis({
    duration: 1.1,
    easing: (t) => 1 - Math.pow(1 - t, 4), // easeOutQuart
    anchors: { offset: -64 },
  });

  gsap.ticker.add((time) => lenis.raf(time * 1000));
  gsap.ticker.lagSmoothing(0);

  // Spotlight offen: Seite nicht unter der Karte wegscrollen
  const map = document.querySelector<HTMLElement>('[data-map-viewport]');
  if (map) {
    new MutationObserver(() => {
      if (map.classList.contains('is-focused')) lenis.stop();
      else lenis.start();
    }).observe(map, { attributes: true, attributeFilter: ['class'] });
  }
}
