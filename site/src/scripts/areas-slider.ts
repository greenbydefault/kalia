import { gsap } from 'gsap';
import { ScrollToPlugin } from 'gsap/ScrollToPlugin';
import { pressFeedback, prefersReducedMotion } from './motion';

gsap.registerPlugin(ScrollToPlugin);

/**
 * Gebiets-Slider. Scrollen selbst ist nativ (Touch, Trackpad, Tastatur, Scroll-Snap).
 * Die Buttons fahren per GSAP eine Karte weiter. Schritt = Abstand zweier Karten,
 * Ziel = nächstes Vielfaches davon, begrenzt auf den scrollbaren Bereich.
 */
const EDGE = 2;

export function initAreasSlider() {
  document.querySelectorAll<HTMLElement>('[data-areas-slider]').forEach((root) => {
    const viewport = root.querySelector<HTMLElement>('[data-slider-viewport]');
    const nav = root.querySelector<HTMLElement>('[data-slider-nav]');
    const prev = root.querySelector<HTMLButtonElement>('[data-slider-prev]');
    const next = root.querySelector<HTMLButtonElement>('[data-slider-next]');
    const slides = viewport ? Array.from(viewport.querySelectorAll<HTMLElement>('.areas > li')) : [];
    if (!viewport || !nav || !prev || !next || slides.length < 2) return;

    const step = () => slides[1].offsetLeft - slides[0].offsetLeft;
    const max = () => viewport.scrollWidth - viewport.clientWidth;

    const update = () => {
      const m = max();
      nav.hidden = m <= EDGE;
      const x = viewport.scrollLeft;
      prev.setAttribute('aria-disabled', String(x <= EDGE));
      next.setAttribute('aria-disabled', String(x >= m - EDGE));
    };

    const stop = () => {
      gsap.killTweensOf(viewport);
      viewport.classList.remove('is-animating');
    };

    const go = (dir: 1 | -1) => {
      const s = step();
      if (s <= 0) return;
      const target = Math.min(max(), Math.max(0, (Math.round(viewport.scrollLeft / s) + dir) * s));
      stop();
      if (prefersReducedMotion()) {
        viewport.scrollTo({ left: target });
        return;
      }
      viewport.classList.add('is-animating');
      gsap.to(viewport, {
        scrollTo: { x: target, autoKill: false },
        duration: 0.7,
        ease: 'power3.inOut',
        onComplete: () => viewport.classList.remove('is-animating'),
        onInterrupt: () => viewport.classList.remove('is-animating'),
      });
    };

    prev.addEventListener('click', () => {
      if (prev.getAttribute('aria-disabled') !== 'true') go(-1);
    });
    next.addEventListener('click', () => {
      if (next.getAttribute('aria-disabled') !== 'true') go(1);
    });

    // Nutzer greift ein: Button-Animation abbrechen, Snap wieder an
    ['wheel', 'touchstart', 'pointerdown'].forEach((t) =>
      viewport.addEventListener(t, stop, { passive: true }),
    );

    viewport.addEventListener('scroll', update, { passive: true });
    new ResizeObserver(update).observe(viewport);
    update();

    pressFeedback(prev);
    pressFeedback(next);
  });
}
