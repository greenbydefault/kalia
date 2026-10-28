import { gsap } from 'gsap';
import { prefersReducedMotion, stripEmptyStyle } from './motion';
import { pauseAudioIn, resetAudioIn } from './audio-player';

/**
 * Spotlight, Kombination A (Weich). Weicher Lichtkreis, ruhiger Zoom, die Karte blendet direkt
 * neben dem Chip ein, die Inhalte laufen gestaffelt nach, danach zählen die Zahlen hoch.
 *
 * Aufbau: .map__stage ist die Welt (nur transform wird animiert), das Popover liegt in .map daneben.
 * Zustände: idle → opening → open → closing → idle. Schließen ist immer dieselbe Timeline rückwärts.
 * Ablauf (s): andere Pins 0 · Spotlight + Kamera 0 · Chip-Icon-Puls 0.1 · Karte 0.5 · Inhalte 0.62.
 */

const ZOOM = 1.45;
const SPOT_R = 190; // Lochradius in Welt-px
const SPOT_R_START = 800;
const GAP = 18; // Chip → Popover
const EDGE = 12;
const MOBILE = '(max-width: 44.99rem)';

type Ctx = {
  btn: HTMLButtonElement;
  point: HTMLElement;
  pop: HTMLElement;
  icon: HTMLElement | null;
  others: HTMLElement[];
  items: HTMLElement[];
  counts: HTMLElement[];
  bars: HTMLElement[];
  tl: gsap.core.Timeline;
};

const clamp = (v: number, min: number, max: number) => Math.min(max, Math.max(min, v));
const fmt = (v: number, dec: number) =>
  v.toLocaleString('de-DE', { minimumFractionDigits: dec, maximumFractionDigits: dec });

export function initSpotlight() {
  const map = document.querySelector<HTMLElement>('[data-map]');
  const viewport = map?.querySelector<HTMLElement>('[data-map-viewport]');
  const stage = map?.querySelector<HTMLElement>('[data-map-stage]');
  const spot = stage?.querySelector<HTMLElement>('[data-spot]');
  const scrim = stage?.querySelector<HTMLElement>('[data-spot-scrim]');
  if (!map || !viewport || !stage || !spot || !scrim) return;

  const triggers = stage.querySelectorAll<HTMLButtonElement>('[data-spotlight]');
  const points = Array.from(stage.querySelectorAll<HTMLElement>('[data-point]'));

  const cam = { x: 0, y: 0, s: 1 };
  let state: 'idle' | 'opening' | 'open' | 'closing' = 'idle';
  let ctx: Ctx | null = null;
  let pending: HTMLButtonElement | null = null;

  function applyCamera() {
    stage!.style.transform = `translate3d(${cam.x}px, ${cam.y}px, 0) scale(${cam.s})`;
    stage!.style.setProperty('--inv', String(1 / cam.s));
  }

  /** Kamera-Ziel und Popover-Platz. Alles in Koordinaten der .map (= Viewport, nicht Welt). */
  function plan(btn: HTMLElement, point: HTMLElement, pop: HTMLElement, reduced: boolean) {
    const W = stage!.offsetWidth;
    const H = stage!.offsetHeight;
    const vw = viewport!.clientWidth;
    const vh = viewport!.clientHeight;
    const mobile = window.matchMedia(MOBILE).matches;

    // Ohne Kamera-Zoom: Pin per Scroll in die Mitte holen, sonst sitzt er mobil am Rand
    if (reduced && W > vw) {
      viewport!.scrollLeft = clamp(point.offsetLeft - vw / 2, 0, W - vw);
    }
    const sL = viewport!.scrollLeft;

    // Pin-Mitte in Welt-px (left/top des Punkts, die Mitte kommt über translate(-50%))
    const px = point.offsetLeft;
    const py = point.offsetTop;

    // sichtbarer Teil der Karte im Fenster
    const r = map!.getBoundingClientRect();
    let v0 = Math.max(0, -r.top);
    let v1 = Math.min(vh, window.innerHeight - r.top);
    if (v1 - v0 < 240) [v0, v1] = [0, vh];

    const popW = pop.offsetWidth;
    const popH = pop.offsetHeight;
    const half = btn.offsetWidth / 2;

    let ax: number;
    let ay: number;
    if (mobile) {
      ax = vw / 2;
      ay = (v0 + Math.max(v0 + 120, v1 - popH)) / 2; // Mitte des freien Bereichs über dem Sheet
    } else {
      ax = (vw - (2 * half + GAP + popW)) / 2 + half; // Chip + Popover als Gruppe mittig
      ay = (v0 + v1) / 2;
    }

    const s = reduced ? 1 : ZOOM;
    const target = reduced
      ? { x: 0, y: 0, s: 1 }
      : {
          x: clamp(ax + sL - px * s, vw - W * s + sL, sL),
          y: clamp(ay - py * s, vh - H * s, 0),
          s,
        };

    // Pin auf dem Bildschirm nach dem Zoom
    const pinX = -sL + target.x + px * target.s;
    const pinY = target.y + py * target.s;

    let side: 1 | -1 = 1;
    if (!mobile) {
      const rightFits = pinX + half + GAP + popW <= vw - EDGE;
      const leftFits = pinX - half - GAP - popW >= EDGE;
      if (!rightFits && leftFits) side = -1;
      const left = side === 1 ? pinX + half + GAP : pinX - half - GAP - popW;
      const top = clamp(pinY - popH * 0.4, v0 + EDGE, Math.max(v0 + EDGE, v1 - popH - EDGE));
      pop.style.left = `${clamp(left, EDGE, vw - popW - EDGE)}px`;
      pop.style.top = `${top}px`;
      pop.style.setProperty('--ay', `${clamp(pinY - top, 28, popH - 28)}px`);
      pop.dataset.side = side === 1 ? 'right' : 'left';
    }

    return { target, px, py, side, mobile };
  }

  function open(btn: HTMLButtonElement) {
    const point = btn.closest<HTMLElement>('[data-point]');
    const pop = map!.querySelector<HTMLElement>(`#${btn.getAttribute('aria-controls')}`);
    if (!point || !pop) return;

    const reduced = prefersReducedMotion();
    const others = points.filter((p) => p !== point);
    // Beim Punkt skaliert .map__point > button schon per CSS (Gegenzoom), darum puffert das Bild darin
    const icon = btn.querySelector<HTMLElement>(btn.classList.contains('map-dot') ? 'img' : '.map-chip__icon');
    const items = Array.from(pop.querySelectorAll<HTMLElement>('[data-s]'));
    const counts = Array.from(pop.querySelectorAll<HTMLElement>('[data-count]'));
    const bars = Array.from(pop.querySelectorAll<HTMLElement>('[data-audio-bar]'));

    state = 'opening';
    btn.setAttribute('aria-expanded', 'true');
    point.classList.add('is-spotlit');
    viewport!.classList.add('is-focused');
    others.forEach((p) => (p.inert = true));

    // Popover erst unsichtbar zeigen, damit es messbar ist
    gsap.set(pop, { opacity: 0 });
    pop.hidden = false;
    spot!.hidden = false;

    const { target, px, py, side, mobile } = plan(btn, point, pop, reduced);
    gsap.set(spot, { '--spot-x': `${px}px`, '--spot-y': `${py}px` });

    const tl = gsap.timeline({
      onComplete: () => {
        if (state === 'opening') state = 'open';
      },
      onReverseComplete: finishClose,
    });

    if (reduced) {
      // kein Zoom, nur kurz einblenden
      gsap.set(others, { opacity: 0.25 });
      gsap.set(spot, { '--spot-r': `${SPOT_R}px` });
      tl.fromTo(spot, { opacity: 0 }, { opacity: 1, duration: 0.2 }, 0).fromTo(
        pop,
        { opacity: 0 },
        { opacity: 1, duration: 0.2 },
        0,
      );
    } else {
      tl.to(others, { opacity: 0.25, duration: 0.4 }, 0)
        .fromTo(
          spot,
          { opacity: 0, '--spot-r': `${SPOT_R_START}px` },
          { opacity: 1, '--spot-r': `${SPOT_R}px`, duration: 0.9, ease: 'power2.out' },
          0,
        )
        .to(cam, { ...target, duration: 0.85, ease: 'power2.inOut', onUpdate: applyCamera }, 0);

      if (icon) {
        tl.fromTo(
          icon,
          { scale: 1 },
          { scale: 1.15, duration: 0.2, yoyo: true, repeat: 1, ease: 'power2.out' },
          0.1,
        );
      }

      tl.fromTo(
        pop,
        mobile
          ? { opacity: 0, y: 28, scale: 1 }
          : {
              opacity: 0,
              scale: 0.94,
              y: 8,
              transformOrigin: side > 0 ? '0% 30%' : '100% 30%',
            },
        { opacity: 1, scale: 1, y: 0, duration: 0.45, ease: 'power3.out' },
        0.5,
      ).from(
        items,
        { y: 8, opacity: 0, duration: 0.35, stagger: 0.05, ease: 'power2.out' },
        0.62,
      );

      // Wellenform wächst nach den Inhalten ein
      if (bars.length) {
        tl.from(bars, { scaleY: 0, duration: 0.4, stagger: 0.012, ease: 'power2.out' }, 0.85);
      }

      counts.forEach((el) => {
        const end = Number(el.dataset.count);
        const dec = Number(el.dataset.dec) || 0;
        const o = { v: 0 };
        el.textContent = fmt(0, dec);
        tl.to(
          o,
          {
            v: end,
            duration: 0.9,
            ease: 'power2.out',
            onUpdate: () => (el.textContent = fmt(o.v, dec)),
          },
          0.75,
        );
      });
    }

    ctx = { btn, point, pop, icon, others, items, counts, bars, tl };
    pop.focus({ preventScroll: true });
  }

  function finishClose() {
    if (!ctx) return;
    const { btn, point, pop, icon, others, items, counts, bars, tl } = ctx;
    tl.kill();
    resetAudioIn(pop);

    // Zahlen zurück auf den Endwert (ohne JS und beim nächsten Öffnen)
    counts.forEach((el) => (el.textContent = fmt(Number(el.dataset.count), Number(el.dataset.dec) || 0)));

    // Erst die Tweens beenden, sonst rendern sie bei einem groben Tick nach dem Aufräumen noch einmal
    const els = [...items, pop, ...(icon ? [icon] : []), ...others, spot!];
    gsap.killTweensOf(els);
    gsap.killTweensOf(bars, 'scaleY');
    gsap.set(els, { clearProps: 'all' });
    gsap.set(bars, { clearProps: 'transform' });
    pop.hidden = true;
    spot!.hidden = true;
    others.forEach((p) => (p.inert = false));
    point.classList.remove('is-spotlit');
    btn.setAttribute('aria-expanded', 'false');
    viewport!.classList.remove('is-focused');

    cam.x = 0;
    cam.y = 0;
    cam.s = 1;
    stage!.style.removeProperty('transform');
    stage!.style.removeProperty('--inv');
    stripEmptyStyle(stage, spot, pop, icon, others, items);

    ctx = null;
    state = 'idle';

    if (pending) {
      const next = pending;
      pending = null;
      open(next);
    }
  }

  function close(speed = 1.7) {
    if (!ctx || state === 'closing') return;
    state = 'closing';
    pauseAudioIn(ctx.pop);
    ctx.btn.focus({ preventScroll: true });
    ctx.tl.timeScale(speed).reverse();
  }

  triggers.forEach((btn) => {
    btn.addEventListener('click', () => {
      if (ctx?.btn === btn) return close();
      if (ctx) {
        pending = btn;
        return close(2.6);
      }
      open(btn);
    });
  });

  map.querySelectorAll<HTMLElement>('[data-pop-close]').forEach((el) =>
    el.addEventListener('click', () => close()),
  );
  scrim.addEventListener('click', () => close());

  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') close();
  });

  // Nur bei Breitenänderung abbrechen: mobil feuert resize schon, wenn die Adressleiste ein-/ausfährt
  let openWidth = window.innerWidth;
  window.addEventListener('resize', () => {
    if (window.innerWidth === openWidth) return;
    openWidth = window.innerWidth;
    pending = null;
    finishClose();
  });
}
