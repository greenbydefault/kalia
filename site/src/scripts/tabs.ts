import { gsap } from 'gsap';
import { pressFeedback, prefersReducedMotion, stripEmptyStyle } from './motion';

/**
 * Umschalter (Tabs) nach WAI-ARIA: Roving tabindex, Pfeiltasten wechseln und aktivieren sofort, Pos1/Ende springen.
 * Markup: components/Umschalter.astro, Styles: styles/components/umschalter.css.
 *
 * Ablauf beim Wechsel: Marker gleitet sofort, altes Panel blendet nach oben aus, dann Tausch (hidden),
 * dann steigen die neuen Elemente auf. Animiert werden `[data-lead]` (zuerst) und `[data-reveal]` (gestaffelt).
 * Die Textfarbe der Tabs wechselt per CSS über aria-selected. Reduzierte Bewegung: Wechsel ohne Animation.
 *
 * Schritt-Buttons (`[data-tab-step="-1" | "1"]`) wechseln zum vorherigen/nächsten Tab, an den Enden aria-disabled.
 */
const PROPS = 'opacity,visibility,transform';
const ITEMS = ':scope [data-lead], :scope [data-reveal]';

export interface TabsHooks {
  /** Im Moment des Tauschs, bevor das alte Panel verschwindet (offene Elemente schließen). Inhalt ist schon ausgeblendet. */
  beforeSwap?: (oldPanel: HTMLElement) => void;
  /** Direkt nachdem das neue Panel sichtbar ist, aber bevor es einblendet (Scrollposition, Messungen). */
  afterSwap?: (newPanel: HTMLElement) => void;
}

export function initTabs(selector: string, hooks: TabsHooks = {}) {
  document.querySelectorAll<HTMLElement>(selector).forEach((root) => {
    const list = root.querySelector<HTMLElement>('[role="tablist"]');
    const tabs = Array.from(root.querySelectorAll<HTMLElement>('[role="tab"]'));
    const marker = root.querySelector<HTMLElement>('[data-marker]');
    if (!list || tabs.length < 2 || !marker) return;

    const steps = Array.from(root.querySelectorAll<HTMLButtonElement>('[data-tab-step]'));
    const panelOf = (tab: HTMLElement) => root.querySelector<HTMLElement>(`#${tab.getAttribute('aria-controls')}`)!;

    let active = tabs.find((t) => t.getAttribute('aria-selected') === 'true') ?? tabs[0];
    let tl: gsap.core.Timeline | null = null;

    /** Marker sitzt unter dem aktiven Tab. Gemessen, damit gleich und unterschiedlich breite Tabs funktionieren. */
    const place = (tab: HTMLElement) => {
      // getBoundingClientRect statt offsetLeft/offsetWidth: Subpixel-genau bei Spalten wie 184,6 px
      const l = list.getBoundingClientRect();
      const t = tab.getBoundingClientRect();
      return { x: t.left - l.left - list.clientLeft + list.scrollLeft, width: t.width };
    };

    /** Scrollt die Leiste (schmale Bildschirme), damit der aktive Tab mittig steht. */
    const reveal = (tab: HTMLElement) => {
      if (list.scrollWidth <= list.clientWidth) return;
      list.scrollTo({
        left: tab.offsetLeft - (list.clientWidth - tab.offsetWidth) / 2,
        behavior: prefersReducedMotion() ? 'auto' : 'smooth',
      });
    };

    const updateSteps = () => {
      const i = tabs.indexOf(active);
      steps.forEach((s) => {
        const target = i + Number(s.dataset.tabStep);
        s.setAttribute('aria-disabled', String(target < 0 || target >= tabs.length));
      });
    };

    const select = (next: HTMLElement, { focus = false } = {}) => {
      if (next === active) return;
      const prev = active;
      active = next;

      // Zustand sofort, unabhängig von der Animation
      tabs.forEach((t) => {
        const on = t === next;
        t.setAttribute('aria-selected', String(on));
        t.tabIndex = on ? 0 : -1;
      });
      if (focus) next.focus();
      updateSteps();
      reveal(next);

      const oldPanel = panelOf(prev);
      const newPanel = panelOf(next);

      const swap = () => {
        hooks.beforeSwap?.(oldPanel);
        oldPanel.hidden = true;
        newPanel.hidden = false;
        hooks.afterSwap?.(newPanel);
      };

      // Schnelles Hin- und Herklicken: laufende Animation zu Ende bringen
      if (tl) {
        tl.progress(1).kill();
        tl = null;
      }

      if (prefersReducedMotion()) {
        gsap.set(marker, place(next));
        swap();
        return;
      }

      const oldItems = Array.from(oldPanel.querySelectorAll<HTMLElement>(ITEMS));
      const newLead = newPanel.querySelector<HTMLElement>(':scope [data-lead]');
      const newCards = Array.from(newPanel.querySelectorAll<HTMLElement>(':scope [data-reveal]'));
      const cleanup = () => {
        gsap.set([...oldItems, ...(newLead ? [newLead] : []), ...newCards], { clearProps: PROPS });
        stripEmptyStyle(oldItems, newLead, newCards);
      };

      tl = gsap
        .timeline({ onComplete: cleanup, onInterrupt: cleanup })
        .to(marker, { ...place(next), duration: 0.4, ease: 'power3.out', overwrite: 'auto' }, 0)
        .to(oldItems, { autoAlpha: 0, y: -8, duration: 0.2, ease: 'power2.in', stagger: 0.03 }, 0)
        .add(swap)
        .set(oldItems, { clearProps: PROPS });

      if (newLead) tl.fromTo(newLead, { autoAlpha: 0, y: 8 }, { autoAlpha: 1, y: 0, duration: 0.35, ease: 'power3.out' });
      tl.fromTo(
        newCards,
        { autoAlpha: 0, y: 16 },
        { autoAlpha: 1, y: 0, duration: 0.5, ease: 'power3.out', stagger: 0.06 },
        newLead ? '<0.05' : undefined,
      );
    };

    tabs.forEach((tab, i) => {
      tab.addEventListener('click', () => select(tab));
      tab.addEventListener('keydown', (e) => {
        const map: Record<string, number> = {
          ArrowRight: i + 1,
          ArrowLeft: i - 1,
          Home: 0,
          End: tabs.length - 1,
        };
        if (!(e.key in map)) return;
        e.preventDefault();
        select(tabs[(map[e.key] + tabs.length) % tabs.length], { focus: true });
      });
    });

    steps.forEach((s) => {
      s.addEventListener('click', () => {
        if (s.getAttribute('aria-disabled') === 'true') return;
        const next = tabs[tabs.indexOf(active) + Number(s.dataset.tabStep)];
        if (next) select(next);
      });
      pressFeedback(s);
    });

    // Marker folgt Größenänderungen (Fenster, Webfont). Der erste Aufruf setzt die Startposition.
    new ResizeObserver(() => {
      if (tl) return;
      gsap.set(marker, place(active));
      list.dataset.ready = '';
    }).observe(list);
    updateSteps();
  });
}
