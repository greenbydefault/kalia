import { gsap } from 'gsap';
import type { Map as MapLibreMap } from 'maplibre-gl';
import { ORTE_URL, PLACE_ZOOM, RADIUS_KM } from '../../data/live-map';
import type { TrailPin } from './data';
import type { Camera } from './map';
import type { Popup } from './popup';

/**
 * Suche am unteren Kartenrand: Ort oder PLZ (gebündelte Liste, lazy beim ersten Fokus) sowie Gebiete
 * und Trails aus den geladenen Daten. Kein Drittanbieter. Gleiche Faltung wie PlaceIndex in der App.
 *
 * Ergebnis: Trails im Umkreis (30 Min. ≈ 17 km) → Kamera fittet auf die nächsten.
 * Keine Trails → Kamera fährt auf den Ort, Button wird zum Link auf die Warteliste.
 */

type Ort = { name: string; plz: string; lat: number; lon: number; fold: string };

type Hit = {
  kind: 'gebiet' | 'ort' | 'trail';
  label: string;
  sub: string;
  rank: number;
  lat: number;
  lon: number;
  trails?: TrailPin[];
  trail?: TrailPin;
};

const KIND_ORDER = { gebiet: 0, ort: 1, trail: 2 } as const;
const MAX_HITS = 6;
const NEAREST = 6;

const fold = (s: string) =>
  s
    .toLowerCase()
    .replaceAll('ä', 'ae')
    .replaceAll('ö', 'oe')
    .replaceAll('ü', 'ue')
    .replaceAll('ß', 'ss')
    .trim();

function rankOf(hay: string, q: string) {
  if (hay === q) return 0;
  if (hay.startsWith(q)) return 1;
  if (hay.includes(q)) return 2;
  return -1;
}

function haversineKm(aLat: number, aLon: number, bLat: number, bLon: number) {
  const r = Math.PI / 180;
  const dLat = (bLat - aLat) * r;
  const dLon = (bLon - aLon) * r;
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(aLat * r) * Math.cos(bLat * r) * Math.sin(dLon / 2) ** 2;
  return 12742 * Math.asin(Math.sqrt(h));
}

export function createSearch(
  frame: HTMLElement,
  map: MapLibreMap,
  camera: Camera,
  popup: Popup,
  trails: TrailPin[],
) {
  const form = frame.querySelector<HTMLFormElement>('[data-lm-search]');
  const input = form?.querySelector<HTMLInputElement>('[data-lm-input]');
  const list = form?.querySelector<HTMLUListElement>('[data-lm-suggest]');
  const submit = form?.querySelector<HTMLButtonElement>('[data-lm-submit]');
  const waitlist = form?.querySelector<HTMLAnchorElement>('[data-lm-waitlist]');
  const note = frame.querySelector<HTMLElement>('[data-lm-note]');
  if (!form || !input || !list || !submit || !waitlist || !note) return;

  // ── Daten ──────────────────────────────────────────────
  let orte: Ort[] = [];
  let orteState: 'idle' | 'loading' | 'ready' | 'failed' = 'idle';

  async function loadOrte() {
    if (orteState !== 'idle') return;
    orteState = 'loading';
    try {
      const res = await fetch(ORTE_URL);
      if (!res.ok) throw new Error(String(res.status));
      const rows = (await res.json()) as [string, string, number, number][];
      orte = rows.map(([name, plz, lat, lon]) => ({ name, plz, lat, lon, fold: fold(name) }));
      orteState = 'ready';
      if (document.activeElement === input) render(); // Treffer nachliefern, falls schon getippt
    } catch {
      orteState = 'failed';
    }
  }

  // Gebiete: Teile der Region (kommagetrennt, z. B. "Röbel/Müritz, Mecklenburgische Seenplatte") und Ort der Trails, je Wert eine Gruppe
  const groups = new Map<string, { label: string; fold: string; trails: TrailPin[] }>();
  for (const t of trails) {
    for (const value of [...t.region.split(','), t.ort]) {
      const v = value.trim();
      if (!v) continue;
      const key = fold(v);
      const g = groups.get(key) ?? { label: v, fold: key, trails: [] };
      if (!g.trails.includes(t)) g.trails.push(t);
      groups.set(key, g);
    }
  }
  const trailFold = trails.map((t) => ({ t, fold: fold(t.name) }));

  const centroid = (ts: TrailPin[]) => ({
    lat: ts.reduce((s, t) => s + t.lat, 0) / ts.length,
    lon: ts.reduce((s, t) => s + t.lon, 0) / ts.length,
  });

  function search(raw: string): Hit[] {
    const q = fold(raw);
    if (q.length < 2) return [];
    const hits: Hit[] = [];

    if (/^\d/.test(q)) {
      const seen = new Set<string>();
      for (const o of orte) {
        if (!o.plz.startsWith(q) || seen.has(o.plz)) continue;
        seen.add(o.plz);
        hits.push({ kind: 'ort', label: `${o.plz} ${o.name}`, sub: 'Postleitzahl', rank: 1, lat: o.lat, lon: o.lon });
        if (seen.size >= 4) break;
      }
      return hits;
    }

    for (const g of groups.values()) {
      const rank = rankOf(g.fold, q);
      if (rank < 0) continue;
      const c = centroid(g.trails);
      hits.push({
        kind: 'gebiet',
        label: g.label,
        sub: `Gebiet · ${g.trails.length} ${g.trails.length === 1 ? 'Pfad' : 'Pfade'}`,
        rank,
        trails: g.trails,
        ...c,
      });
    }

    const seen = new Set<string>();
    const ortHits: Hit[] = [];
    for (const o of orte) {
      const rank = rankOf(o.fold, q);
      if (rank < 0 || seen.has(o.name)) continue;
      seen.add(o.name);
      ortHits.push({ kind: 'ort', label: o.name, sub: `Ort · ${o.plz}`, rank, lat: o.lat, lon: o.lon });
    }
    ortHits.sort((a, b) => a.rank - b.rank || a.label.length - b.label.length);
    hits.push(...ortHits.slice(0, 5));

    for (const { t, fold: f } of trailFold) {
      const rank = rankOf(f, q);
      if (rank < 0) continue;
      hits.push({ kind: 'trail', label: t.name, sub: t.typLabel, rank, lat: t.lat, lon: t.lon, trail: t });
    }

    return hits
      .sort((a, b) => a.rank - b.rank || KIND_ORDER[a.kind] - KIND_ORDER[b.kind] || a.label.length - b.label.length)
      .slice(0, MAX_HITS);
  }

  // ── Anzeige ────────────────────────────────────────────
  let hits: Hit[] = [];
  let active = -1;
  let noteTimer: gsap.core.Tween | null = null;

  function showNote(text: string, { sticky = false }: { sticky?: boolean } = {}) {
    noteTimer?.kill();
    note!.textContent = text;
    note!.hidden = !text;
    if (text && !sticky) noteTimer = gsap.delayedCall(6, () => (note!.hidden = true));
  }

  function setMode(mode: 'search' | 'waitlist') {
    submit!.hidden = mode === 'waitlist';
    waitlist!.hidden = mode === 'search';
  }

  function render() {
    hits = search(input!.value);
    active = -1;
    list!.replaceChildren(
      ...hits.map((h, i) => {
        const li = document.createElement('li');
        li.id = `lm-opt-${i}`;
        li.className = 'live-search__option';
        li.setAttribute('role', 'option');
        li.setAttribute('aria-selected', 'false');
        const a = document.createElement('span');
        a.className = 'live-search__label';
        a.textContent = h.label;
        const b = document.createElement('span');
        b.className = 'live-search__sub';
        b.textContent = h.sub;
        li.append(a, b);
        // mousedown statt click: der Fokus soll nicht vorher aus dem Feld wandern
        li.addEventListener('mousedown', (e) => {
          e.preventDefault();
          choose(h);
        });
        return li;
      }),
    );
    const open = hits.length > 0;
    list!.hidden = !open;
    input!.setAttribute('aria-expanded', String(open));
    input!.removeAttribute('aria-activedescendant');
  }

  function setActive(i: number) {
    active = i;
    list!.querySelectorAll('[role="option"]').forEach((el, idx) => {
      el.setAttribute('aria-selected', String(idx === i));
      el.classList.toggle('is-active', idx === i);
    });
    if (i >= 0) input!.setAttribute('aria-activedescendant', `lm-opt-${i}`);
    else input!.removeAttribute('aria-activedescendant');
  }

  function closeList() {
    list!.hidden = true;
    input!.setAttribute('aria-expanded', 'false');
  }

  // ── Kamera ─────────────────────────────────────────────
  function fit(points: { lat: number; lon: number }[]) {
    const w = Math.min(...points.map((p) => p.lon));
    const e = Math.max(...points.map((p) => p.lon));
    const s = Math.min(...points.map((p) => p.lat));
    const n = Math.max(...points.map((p) => p.lat));
    const small = frame.clientWidth < 520;
    const cam = map.cameraForBounds(
      [
        [w, s],
        [e, n],
      ],
      {
        padding: { top: 70, bottom: small ? 130 : 120, left: 60, right: 60 },
        maxZoom: 13,
      },
    );
    if (!cam) return;
    const c = cam.center as { lng: number; lat: number };
    camera.fly({ center: [c.lng, c.lat], zoom: cam.zoom ?? 12 }, { duration: 1.1 });
  }

  function choose(h: Hit) {
    input!.value = h.label;
    closeList();
    popup.close({ refocus: false });

    if (h.kind === 'trail' && h.trail) {
      setMode('search');
      showNote('');
      popup.open(h.trail);
      return;
    }

    if (h.kind === 'gebiet' && h.trails) {
      setMode('search');
      showNote(`${h.trails.length} ${h.trails.length === 1 ? 'Pfad' : 'Pfade'} in ${h.label}`);
      fit(h.trails);
      return;
    }

    // Ort: Trails im Umkreis, nächste zuerst
    const near = trails
      .map((t) => ({ t, d: haversineKm(h.lat, h.lon, t.lat, t.lon) }))
      .filter((x) => x.d <= RADIUS_KM)
      .sort((a, b) => a.d - b.d);

    if (near.length) {
      setMode('search');
      showNote(`${near.length} ${near.length === 1 ? 'Pfad' : 'Pfade'} bei ${h.label}`);
      fit([{ lat: h.lat, lon: h.lon }, ...near.slice(0, NEAREST).map((x) => x.t)]);
    } else {
      setMode('waitlist');
      showNote(`Bei ${h.label} ist Kalia noch nicht. Tragt euch ein, dann erfahrt ihr es zuerst.`, { sticky: true });
      camera.fly({ center: [h.lon, h.lat], zoom: PLACE_ZOOM }, { duration: 1.1 });
    }
  }

  // ── Ereignisse ─────────────────────────────────────────
  input.addEventListener('focus', () => {
    void loadOrte();
    render();
  });
  input.addEventListener('input', () => {
    void loadOrte();
    setMode('search');
    showNote('');
    render();
  });
  input.addEventListener('blur', () => closeList());

  input.addEventListener('keydown', (e) => {
    if (e.key === 'ArrowDown' && hits.length) {
      e.preventDefault();
      list.hidden = false;
      setActive((active + 1) % hits.length);
    } else if (e.key === 'ArrowUp' && hits.length) {
      e.preventDefault();
      setActive((active - 1 + hits.length) % hits.length);
    } else if (e.key === 'Escape' && !list.hidden) {
      e.stopPropagation();
      closeList();
    }
  });

  form.addEventListener('submit', (e) => {
    e.preventDefault();
    const q = input.value.trim();
    if (q.length < 2) {
      showNote('Gib eine Stadt, ein Gebiet oder eine Postleitzahl ein.');
      input.focus();
      return;
    }
    const pick = active >= 0 ? hits[active] : (hits[0] ?? search(q)[0]);
    if (pick) return choose(pick);
    if (orteState === 'loading') return showNote('Einen Moment, die Ortsliste lädt noch.');
    showNote('Dazu finde ich nichts. Probier eine Stadt oder eine Postleitzahl.');
  });
}
