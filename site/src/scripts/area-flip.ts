import { gsap } from 'gsap';
import { prefersReducedMotion, stripEmptyStyle } from './motion';

/**
 * Gebiets-Card, Flip-Animation Variante A (Fächer).
 * Die drei Mini-Karten fächern auf und schieben sich zum Stapel, dann hebt die Karte ab,
 * dreht sich um die Y-Achse und landet. Gesamtdauer 2,15 s.
 *
 * Aufbau: .area-flip (perspective) > .area-flip__inner (preserve-3d) > Vorder- und Rückseite,
 * dazu .area-flip__shadow als eigenes Element unter der Karte. GSAP bewegt nur x, y, rotation, scale.
 * Zustände: idle → opening → open → closing. Zurück = dieselbe Timeline rückwärts mit timeScale(1.6).
 * Klick während der Bewegung kehrt die Richtung um.
 *
 * Alle Pixelwerte der Vorlage gelten für eine Mini-Karten-Fläche von 315 px Breite und werden
 * auf die echte Breite skaliert (c.k).
 */

const ART_W = 315;
const BACK_SPEED = 1.6;

type State = 'idle' | 'opening' | 'open' | 'closing';

type Ctx = {
  root: HTMLElement;
  inner: HTMLElement;
  shadow: HTMLElement;
  front: HTMLElement;
  back: HTMLElement;
  plus: HTMLElement;
  close: HTMLElement;
  minisBox: HTMLElement;
  mc: { g: HTMLElement; b: HTMLElement; m: HTMLElement };
  minis: HTMLElement[];
  sceneArt: HTMLElement;
  bTitle: HTMLElement;
  bText: HTMLElement;
  bLabel: HTMLElement;
  factItems: HTMLElement[];
  tileItems: HTMLElement[];
  state: State;
  hovered: boolean;
  tl: gsap.core.Timeline | null;
  k: () => number;
};

type Variant = {
  build: (c: Ctx) => gsap.core.Timeline;
  hover: (c: Ctx) => void;
};

/* ── Gemeinsame Helfer ─────────────────────────────────────── */

function hidePlus(tl: gsap.core.Timeline, c: Ctx, at: number) {
  return tl.to(c.plus, { rotation: 90, scale: 0.6, autoAlpha: 0, duration: 0.3, ease: 'power2.in' }, at);
}

function lift(tl: gsap.core.Timeline, c: Ctx, at: number) {
  return tl
    .to(c.inner, { y: -10, scale: 1.03, duration: 0.35, ease: 'power2.out' }, at)
    .to(c.shadow, { y: 10, autoAlpha: 0.5, duration: 0.35, ease: 'power2.out' }, at);
}

function land(tl: gsap.core.Timeline, c: Ctx, at: number) {
  return tl
    .to(c.inner, { y: 0, scale: 1, duration: 0.45, ease: 'power2.inOut' }, at)
    .to(c.shadow, { y: 0, autoAlpha: 1, duration: 0.45, ease: 'power2.inOut' }, at);
}

function flip(
  tl: gsap.core.Timeline,
  c: Ctx,
  at: number,
  { axis = 'y', dur = 0.8, ease = 'power3.inOut' }: { axis?: 'x' | 'y'; dur?: number; ease?: string } = {},
) {
  const rot = axis === 'x' ? 'rotationX' : 'rotationY';
  const squash = axis === 'x' ? 'scaleY' : 'scaleX';
  return tl
    .to(c.inner, { [rot]: 180, duration: dur, ease }, at)
    .to(c.shadow, { [squash]: 0.35, duration: dur / 2, ease: 'sine.in' }, at)
    .to(c.shadow, { [squash]: 1, duration: dur / 2, ease: 'sine.out' }, at + dur / 2);
}

function revealBack(tl: gsap.core.Timeline, c: Ctx, at: number) {
  return tl
    .fromTo(c.sceneArt, { scale: 1.12 }, { scale: 1, duration: 0.8, ease: 'power3.out' }, at)
    .fromTo(
      [c.bTitle, c.bText, c.bLabel],
      { y: 10, autoAlpha: 0 },
      { y: 0, autoAlpha: 1, duration: 0.4, stagger: 0.06, ease: 'power2.out' },
      at + 0.2,
    )
    .fromTo(
      c.factItems,
      { y: 10, autoAlpha: 0 },
      { y: 0, autoAlpha: 1, duration: 0.4, stagger: 0.06, ease: 'power2.out' },
      at + 0.28,
    )
    .fromTo(
      c.tileItems,
      { x: 24, autoAlpha: 0 },
      { x: 0, autoAlpha: 1, duration: 0.45, stagger: 0.06, ease: 'power3.out' },
      at + 0.32,
    )
    .fromTo(
      c.close,
      { scale: 0.5, rotation: -90, autoAlpha: 0 },
      { scale: 1, rotation: 0, autoAlpha: 1, duration: 0.4, ease: 'back.out(2)' },
      at + 0.45,
    );
}

/* ── Variante A: Fächer ────────────────────────────────────── */

function openA(c: Ctx) {
  const { g, b, m } = c.mc;
  const k = c.k();
  const tl = gsap.timeline();
  hidePlus(tl, c, 0);
  // 1. Fächer geht auf
  tl.to(g, { x: -22 * k, y: -4 * k, rotation: -7, duration: 0.45, ease: 'power2.out' }, 0)
    .to(b, { x: 22 * k, y: -4 * k, rotation: 7, duration: 0.45, ease: 'power2.out' }, 0.04)
    .to(m, { y: -16 * k, scale: 1.05, duration: 0.45, ease: 'power2.out' }, 0.02)
    // 2. Alle drei rutschen zu einem Stapel in der Mitte
    .to(g, { x: 56 * k, y: 2 * k, rotation: 6, duration: 0.42, ease: 'power3.inOut' }, 0.5)
    .to(b, { x: -58 * k, y: 2 * k, rotation: -6, duration: 0.42, ease: 'power3.inOut' }, 0.52)
    .to(m, { y: -4 * k, scale: 1, duration: 0.42, ease: 'power3.inOut' }, 0.5);
  // 3. Karte hebt ab, dreht sich, landet
  lift(tl, c, 0.8);
  flip(tl, c, 0.86, { axis: 'y', dur: 0.8, ease: 'power3.inOut' });
  revealBack(tl, c, 1.2);
  land(tl, c, 1.5);
  return tl;
}

/** Hover: der Fächer öffnet sich nur angedeutet. */
function hoverA(c: Ctx) {
  const { g, b, m } = c.mc;
  const k = c.k();
  const d = { duration: 0.35, ease: 'power2.out', overwrite: 'auto' } as const;
  gsap.to(g, { x: -6 * k, rotation: -2, ...d });
  gsap.to(b, { x: 6 * k, rotation: 2, ...d });
  gsap.to(m, { y: -5 * k, ...d });
}

const VARIANTS: Record<string, Variant> = { A: { build: openA, hover: hoverA } };
const variant = 'A';

/** Reduzierte Bewegung: kein Flip, nur 0,2 s Überblenden. */
function buildReduced(c: Ctx) {
  c.root.classList.add('is-reduced');
  return gsap
    .timeline()
    .to(c.front, { autoAlpha: 0, duration: 0.2, ease: 'none' }, 0)
    .fromTo(c.back, { autoAlpha: 0 }, { autoAlpha: 1, duration: 0.2, ease: 'none' }, 0);
}

/* ── Ruhe und Zustände ─────────────────────────────────────── */

function rest(c: Ctx) {
  gsap.to(c.minis, {
    x: 0,
    y: 0,
    rotation: 0,
    scale: 1,
    duration: 0.35,
    ease: 'power2.out',
    overwrite: 'auto',
    // Ruhepose = Stylesheet: kein Inline-Style zurücklassen (feuert nicht, wenn ein Hover den Tween abbricht)
    onComplete: () => {
      gsap.set(c.minis, { clearProps: 'all' });
      stripEmptyStyle(c.minis);
    },
  });
}

function setAria(c: Ctx, open: boolean) {
  c.front.setAttribute('aria-hidden', String(open));
  c.front.setAttribute('aria-expanded', String(open));
  c.back.setAttribute('aria-hidden', String(!open));
  c.front.inert = open;
  c.back.inert = !open;
}

function toggle(c: Ctx) {
  const hadFocus = c.root.contains(document.activeElement);
  if (c.state === 'idle') {
    gsap.killTweensOf(c.minis);
    c.tl = prefersReducedMotion() ? buildReduced(c) : VARIANTS[variant].build(c);
    c.tl.eventCallback('onComplete', () => {
      c.state = 'open';
    });
    c.tl.eventCallback('onReverseComplete', () => settle(c));
    c.state = 'opening';
    setAria(c, true);
    if (hadFocus) c.close.focus({ preventScroll: true });
  } else if (c.state === 'opening' || c.state === 'open') {
    c.state = 'closing';
    c.tl?.timeScale(BACK_SPEED).reverse();
    setAria(c, false);
    // Klick vor dem ersten Tick: Timeline steht schon auf 0, onReverseComplete würde nie feuern
    if (c.tl && c.tl.time() === 0) settle(c);
    if (hadFocus) c.front.focus({ preventScroll: true });
  } else if (c.state === 'closing') {
    c.state = 'opening';
    c.tl?.timeScale(1).play();
    setAria(c, true);
    if (hadFocus) c.close.focus({ preventScroll: true });
  }
}

/** Nach dem Zurückdrehen: alles Inline-Zeug weg, sonst bleiben Inhalte beim nächsten Öffnen unsichtbar.
 *  Die Mini-Karten bleiben absichtlich stehen (Hover-Pose), rest/hover tweent sie von dort weiter. */
function settle(c: Ctx) {
  c.tl?.kill();
  c.tl = null;
  c.root.classList.remove('is-reduced');
  const els = [
    c.inner,
    c.shadow,
    c.plus,
    c.close,
    c.front,
    c.back,
    c.sceneArt,
    c.bTitle,
    c.bText,
    c.bLabel,
    ...c.factItems,
    ...c.tileItems,
  ];
  // Erst die Tweens beenden: bei einem groben Tick rendern Kind-Tweens sonst nach dem Aufräumen
  // noch einmal ihren Startzustand ins style-Attribut.
  gsap.killTweensOf(els);
  gsap.set(els, { clearProps: 'all' });
  stripEmptyStyle(els);
  c.state = 'idle';
  if (c.hovered) VARIANTS[variant].hover(c);
  else rest(c);
}

/* ── Start ─────────────────────────────────────────────────── */

function q<T extends HTMLElement>(root: ParentNode, sel: string) {
  const el = root.querySelector<T>(sel);
  if (!el) throw new Error(`area-flip: ${sel} fehlt`);
  return el;
}

function createCtx(root: HTMLElement): Ctx {
  const minisBox = q(root, '[data-minis]');
  const g = q(root, '[data-mini="grey"]');
  const b = q(root, '[data-mini="blue"]');
  const m = q(root, '[data-mini="mid"]');
  return {
    root,
    inner: q(root, '[data-inner]'),
    shadow: q(root, '[data-shadow]'),
    front: q(root, '[data-front]'),
    back: q(root, '[data-back]'),
    plus: q(root, '[data-plus]'),
    close: q(root, '[data-close]'),
    minisBox,
    mc: { g, b, m },
    minis: [g, b, m],
    sceneArt: q(root, '[data-scene-art]'),
    bTitle: q(root, '[data-b-title]'),
    bText: q(root, '[data-b-text]'),
    bLabel: q(root, '[data-b-label]'),
    factItems: Array.from(root.querySelectorAll<HTMLElement>('[data-fact]')),
    tileItems: Array.from(root.querySelectorAll<HTMLElement>('[data-tile]')),
    state: 'idle',
    hovered: false,
    tl: null,
    k: () => (minisBox.offsetWidth || ART_W) / ART_W,
  };
}

export function initAreaFlip() {
  document.querySelectorAll<HTMLElement>('[data-area-flip]').forEach((root) => {
    const c = createCtx(root);

    root.addEventListener('click', () => toggle(c));

    c.front.addEventListener('keydown', (e) => {
      if (e.target !== c.front) return;
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault();
        toggle(c);
      }
    });

    // Hover nur bei echter Maus
    root.addEventListener('pointerenter', (e) => {
      if (e.pointerType !== 'mouse') return;
      c.hovered = true;
      if (c.state === 'idle') VARIANTS[variant].hover(c);
    });
    root.addEventListener('pointerleave', (e) => {
      if (e.pointerType !== 'mouse') return;
      c.hovered = false;
      if (c.state === 'idle') rest(c);
    });
  });
}
