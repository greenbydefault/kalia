import { gsap } from 'gsap';
import { prefersReducedMotion, stripEmptyStyle } from './motion';

/**
 * FAQ-Akkordeon. <details> bleibt die Basis (ohne JS geht es nativ auf/zu),
 * GSAP animiert nur die Höhe des Panels. Immer nur ein Eintrag offen.
 * Unterbrechbar: Klick mitten in der Animation startet von der aktuellen Höhe.
 */

/** Inline-Reste der Animation entfernen (Eigenschaften und leeres style-Attribut) */
const clean = (...els: HTMLElement[]) => {
  gsap.killTweensOf(els); // sonst rendert ein im selben Tick endender Tween den Inline-Stil gleich wieder
  gsap.set(els, { clearProps: 'all' });
  stripEmptyStyle(els);
};

const isOpen = (d: HTMLDetailsElement) => d.open && !d.classList.contains('is-closing');

export function initFaq() {
  const root = document.querySelector<HTMLElement>('[data-faq]');
  if (!root) return;
  const items = Array.from(root.querySelectorAll<HTMLDetailsElement>('.faq__item'));

  function panelOf(d: HTMLDetailsElement) {
    return d.querySelector<HTMLElement>('.faq__panel')!;
  }

  function show(d: HTMLDetailsElement) {
    const panel = panelOf(d);
    const answer = panel.firstElementChild as HTMLElement;
    gsap.killTweensOf([panel, answer]);
    d.classList.remove('is-closing');

    if (prefersReducedMotion()) {
      d.open = true;
      clean(panel, answer);
      return;
    }

    if (!d.open) {
      d.open = true;
      gsap.set(panel, { height: 0 });
      gsap.set(answer, { opacity: 0, y: -6 });
    }
    gsap.to(panel, {
      height: 'auto',
      duration: 0.55,
      ease: 'power3.out',
      onComplete: () => clean(panel),
    });
    // Jeder Tween räumt sich selbst auf: bei einem Lag-Tick enden beide im selben Frame,
    // und ein Aufräumen des Nachbarn würde vor dem letzten Render dieses Tweens laufen.
    gsap.to(answer, {
      opacity: 1,
      y: 0,
      duration: 0.45,
      delay: 0.08,
      ease: 'power2.out',
      onComplete: () => clean(answer),
    });
  }

  function hide(d: HTMLDetailsElement) {
    if (!d.open) return;
    const panel = panelOf(d);
    const answer = panel.firstElementChild as HTMLElement;
    gsap.killTweensOf([panel, answer]);

    if (prefersReducedMotion()) {
      d.open = false;
      clean(panel, answer);
      return;
    }

    d.classList.add('is-closing');
    gsap.to(answer, { opacity: 0, duration: 0.2, ease: 'power1.out' });
    gsap.to(panel, {
      height: 0,
      duration: 0.4,
      ease: 'power2.inOut',
      onComplete: () => {
        d.open = false;
        d.classList.remove('is-closing');
        clean(panel, answer);
      },
    });
  }

  items.forEach((d) => {
    d.querySelector('summary')!.addEventListener('click', (event) => {
      event.preventDefault();
      if (isOpen(d)) return hide(d);
      items.forEach((other) => other !== d && hide(other));
      show(d);
    });
  });
}
