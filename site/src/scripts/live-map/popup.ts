import { gsap } from 'gsap';
import type { Map as MapLibreMap } from 'maplibre-gl';
import { PIN_ZOOM, tagLabels } from '../../data/live-map';
import { prefersReducedMotion, stripEmptyStyle } from '../motion';
import type { TrailPin } from './data';
import { centerForPointAt, type Camera } from './map';
import type { Pins } from './pins';

/**
 * Kompakte Trail-Karte am Pin. Beim Öffnen fährt die GSAP-Kamera auf den Pin (er landet neben dem
 * Popover), die anderen Pins blenden ab (CSS, .has-active), das Popover läuft gestaffelt ein.
 * Mobil wird daraus ein Bottom-Sheet (Styles .pop). Schließen: X, Esc, Klick auf die Karte, Ziehen, Zoomen.
 */

const GAP = 18; // Pin → Popover
const EDGE = 12;
const PIN_W = 32;
const PIN_H = 36;
const MOBILE = '(max-width: 44.99rem)';

const fmt = (v: number, dec: number) =>
  v.toLocaleString('de-DE', { minimumFractionDigits: dec, maximumFractionDigits: dec });
const clamp = (v: number, min: number, max: number) => Math.min(max, Math.max(min, v));

/** `cc-by-sa-4.0` → `CC BY-SA 4.0` */
function licenseLabel(l: string): string {
  if (l === 'pd') return 'Gemeinfrei';
  const m = /^cc-(by(?:-sa)?)-(\d\.\d)$/.exec(l);
  if (m) return `CC ${m[1].toUpperCase()} ${m[2]}`;
  return l === 'cc0' ? 'CC0' : l.toUpperCase();
}

type Stat = { label: string; value: number; dec: number };

function statsOf(t: TrailPin): Stat[] {
  const out: Stat[] = [];
  if (t.km > 0) out.push({ label: 'Kilometer', value: t.km, dec: 1 });
  if (t.min > 0) out.push({ label: 'Minuten', value: t.min, dec: 0 });
  if (t.stationen > 0) out.push({ label: 'Stationen', value: t.stationen, dec: 0 });
  return out;
}

export function createPopup(frame: HTMLElement, map: MapLibreMap, camera: Camera, pins: Pins) {
  const pop = frame.querySelector<HTMLElement>('[data-lm-pop]');
  if (!pop) throw new Error('LiveMap: Popover fehlt');
  const kicker = pop.querySelector<HTMLElement>('[data-lm-kicker]')!;
  const title = pop.querySelector<HTMLElement>('[data-lm-title]')!;
  const region = pop.querySelector<HTMLElement>('[data-lm-region]')!;
  const statsEl = pop.querySelector<HTMLElement>('[data-lm-stats]')!;
  const tagsEl = pop.querySelector<HTMLElement>('[data-lm-tags]')!;
  const photo = pop.querySelector<HTMLImageElement>('[data-lm-photo]')!;
  const credit = pop.querySelector<HTMLAnchorElement>('[data-lm-credit]')!;
  const closeBtn = pop.querySelector<HTMLButtonElement>('[data-lm-close]')!;
  const cta = pop.querySelector<HTMLElement>('[data-lm-cta]')!;

  let current: TrailPin | null = null;
  let tl: gsap.core.Timeline | null = null;
  let delay: gsap.core.Tween | null = null;
  let counts: { el: HTMLElement; end: number; dec: number }[] = [];

  function fill(t: TrailPin) {
    kicker.textContent = t.typLabel;
    title.textContent = t.name;
    region.textContent = t.region || t.ort;
    region.hidden = !region.textContent;

    // Hero-Foto (Wikimedia Commons u. a.) mit Namensnennung, sonst bleibt der Platzhalter sichtbar
    const ph = t.photo;
    photo.hidden = true;
    credit.hidden = true;
    photo.onload = () => {
      photo.hidden = false;
      credit.hidden = !ph;
    };
    photo.onerror = () => {
      photo.hidden = true;
      credit.hidden = true;
    };
    photo.alt = ph ? `Foto: ${t.name}` : '';
    if (ph) {
      photo.src = ph.url;
      credit.textContent = `${ph.credit ? `Foto: ${ph.credit} · ` : ''}${licenseLabel(ph.license)}`;
      credit.href = ph.sourceUrl || ph.licenseUrl || '#';
    } else {
      photo.removeAttribute('src');
    }

    const stats = statsOf(t);
    statsEl.replaceChildren(
      ...stats.map((s) => {
        const box = document.createElement('div');
        box.className = 'pop__stat';
        box.dataset.s = '';
        const dt = document.createElement('dt');
        dt.className = 'pop__label';
        dt.textContent = s.label;
        const dd = document.createElement('dd');
        dd.className = 'pop__num';
        dd.textContent = fmt(s.value, s.dec);
        box.append(dt, dd);
        return box;
      }),
    );
    statsEl.style.setProperty('--n', String(Math.max(1, stats.length)));
    statsEl.hidden = stats.length === 0;
    counts = stats.map((s, i) => ({
      el: statsEl.querySelectorAll<HTMLElement>('.pop__num')[i],
      end: s.value,
      dec: s.dec,
    }));

    tagsEl.replaceChildren(
      ...t.tags.slice(0, 3).map((tag) => {
        const li = document.createElement('li');
        li.className = 'pop__tag';
        li.textContent = tagLabels[tag];
        return li;
      }),
    );
    tagsEl.hidden = t.tags.length === 0;
  }

  /** Popover-Platz und Pin-Bildschirmposition für die Kamera. Alles in Koordinaten des Kartenfensters. */
  function plan(t: TrailPin) {
    const W = frame.clientWidth;
    const H = frame.clientHeight;
    const popW = pop!.offsetWidth;
    const popH = pop!.offsetHeight;
    const mobile = window.matchMedia(MOBILE).matches;

    let ax: number;
    let ay: number; // Pin-Spitze
    if (mobile) {
      ax = W / 2;
      ay = Math.max(PIN_H + 56, (H - popH) * 0.62);
    } else {
      ax = (W - (PIN_W + GAP + popW)) / 2 + PIN_W / 2;
      ay = H * 0.58;
    }

    const zoom = Math.max(map.getZoom(), PIN_ZOOM);
    const center = centerForPointAt([t.lon, t.lat], zoom, ax, ay, W, H);

    if (!mobile) {
      const bodyY = ay - PIN_H / 2;
      const top = clamp(bodyY - popH * 0.4, EDGE, Math.max(EDGE, H - popH - EDGE));
      const left = clamp(ax + PIN_W / 2 + GAP, EDGE, W - popW - EDGE);
      pop!.style.left = `${left}px`;
      pop!.style.top = `${top}px`;
      pop!.style.setProperty('--ay', `${clamp(bodyY - top, 28, popH - 28)}px`);
      pop!.dataset.side = 'right';
    }
    return { center, zoom, mobile };
  }

  function open(t: TrailPin) {
    if (current) reset();
    current = t;
    fill(t);

    // erst unsichtbar zeigen, damit es messbar ist
    gsap.set(pop, { opacity: 0 });
    pop!.hidden = false;
    frame.classList.add('has-active');
    pins.setActive(t.id);

    const { center, zoom, mobile } = plan(t);
    const reduced = prefersReducedMotion();
    const items = Array.from(pop!.querySelectorAll<HTMLElement>('[data-s]'));

    tl = gsap.timeline({ paused: true });
    if (reduced) {
      tl.fromTo(pop, { opacity: 0 }, { opacity: 1, duration: 0.2 });
    } else {
      tl.fromTo(
        pop,
        mobile
          ? { opacity: 0, y: 28, scale: 1 }
          : { opacity: 0, scale: 0.94, y: 8, transformOrigin: '0% 30%' },
        { opacity: 1, scale: 1, y: 0, duration: 0.45, ease: 'power3.out' },
        0,
      ).from(items, { y: 8, opacity: 0, duration: 0.35, stagger: 0.05, ease: 'power2.out' }, 0.12);

      counts.forEach(({ el, end, dec }) => {
        const o = { v: 0 };
        el.textContent = fmt(0, dec);
        tl!.to(o, { v: end, duration: 0.9, ease: 'power2.out', onUpdate: () => (el.textContent = fmt(o.v, dec)) }, 0.25);
      });
    }

    const flight = camera.fly({ center, zoom }, { duration: 0.9 });
    // Popover erscheint, wenn die Kamera etwa zwei Drittel der Fahrt hinter sich hat
    delay = gsap.delayedCall(reduced ? 0 : flight * 0.6, () => tl?.play());
    pop!.focus({ preventScroll: true });
  }

  /** Aufräumen ohne Animation (Wechsel auf einen anderen Pin, Resize). */
  function reset() {
    delay?.kill();
    tl?.kill();
    delay = null;
    tl = null;
    counts.forEach(({ el, end, dec }) => (el.textContent = fmt(end, dec)));
    const items = Array.from(pop!.querySelectorAll<HTMLElement>('[data-s]'));
    gsap.killTweensOf([pop, ...items]);
    gsap.set([pop, ...items], { clearProps: 'all' });
    stripEmptyStyle(pop, items);
    pop!.hidden = true;
    pop!.style.removeProperty('left');
    pop!.style.removeProperty('top');
    frame.classList.remove('has-active');
    pins.setActive(null);
    current = null;
  }

  function close({ refocus = true }: { refocus?: boolean } = {}) {
    if (!current) return;
    const id = current.id;
    const btn = pins.button(id);
    delay?.kill();
    tl?.kill();
    frame.classList.remove('has-active');
    pins.setActive(null);
    current = null;

    if (prefersReducedMotion() || pop!.hidden) {
      finish();
    } else {
      gsap.to(pop, { opacity: 0, y: 6, duration: 0.18, ease: 'power2.in', onComplete: finish });
    }
    if (refocus) btn?.focus({ preventScroll: true });

    function finish() {
      // zwischenzeitlich schon wieder geöffnet? dann nichts anfassen
      if (current) return;
      reset();
    }
  }

  closeBtn.addEventListener('click', () => close());
  cta.addEventListener('click', () => close({ refocus: false }));
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && current) close();
  });

  // Klick auf die Karte (nicht auf Pins, die stoppen die Weitergabe) und echte Nutzer-Bewegung schließen
  map.on('click', () => close({ refocus: false }));
  map.on('dragstart', (e) => {
    if ((e as { originalEvent?: Event }).originalEvent) close({ refocus: false });
  });
  map.on('zoomstart', (e) => {
    if ((e as { originalEvent?: Event }).originalEvent) close({ refocus: false });
  });

  let width = window.innerWidth;
  window.addEventListener('resize', () => {
    if (window.innerWidth === width) return;
    width = window.innerWidth;
    if (current) {
      camera.stop();
      reset();
    }
  });

  return { open, close, isOpen: () => current !== null };
}

export type Popup = ReturnType<typeof createPopup>;
