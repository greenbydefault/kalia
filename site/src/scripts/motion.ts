import { gsap } from 'gsap';

/** `?motion=1` in der URL erzwingt volle Animation (zum Testen, wenn das System "Bewegung reduzieren" an hat). */
const forced = () => new URLSearchParams(location.search).get('motion') === '1';

export const prefersReducedMotion = () =>
  !forced() && window.matchMedia('(prefers-reduced-motion: reduce)').matches;

/** Setzt data-motion am html, damit CSS den Override kennt. */
export function applyMotionOverride() {
  if (forced()) document.documentElement.dataset.motion = '1';
}

/**
 * Nach gsap.set(…, { clearProps }) bleibt ein leeres style="" am Element stehen.
 * Das hier entfernt das Attribut, damit nach einer Animation kein Inline-Rest im DOM bleibt.
 */
export function stripEmptyStyle(...targets: (Element | Element[] | null | undefined)[]) {
  for (const el of targets.flat()) {
    if (el && el.getAttribute('style') === '') el.removeAttribute('style');
  }
}

/**
 * Klick-Feedback für runde Buttons: beim Drücken ein kleines Stück kleiner,
 * beim Loslassen mit leichtem Überschwingen zurück (back.out geht kurz über 1, dann auf 1).
 * Nur Zeiger-Ereignisse, die Tastatur löst über :focus-visible keine Skalierung aus.
 */
export function pressFeedback(el: HTMLElement, { down = 0.92 }: { down?: number } = {}) {
  if (prefersReducedMotion()) return;
  let pressed = false;

  const press = () => {
    if (el.getAttribute('aria-disabled') === 'true') return;
    pressed = true;
    gsap.to(el, { scale: down, duration: 0.12, ease: 'power2.out', overwrite: 'auto' });
  };
  const release = () => {
    if (!pressed) return;
    pressed = false;
    gsap.to(el, {
      scale: 1,
      duration: 0.5,
      ease: 'back.out(5)',
      overwrite: 'auto',
      onComplete: () => {
        gsap.set(el, { clearProps: 'transform' });
        stripEmptyStyle(el);
      },
    });
  };

  el.addEventListener('pointerdown', press);
  el.addEventListener('pointerup', release);
  el.addEventListener('pointerleave', release);
  el.addEventListener('pointercancel', release);
}
