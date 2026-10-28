import { Marker, type Map as MapLibreMap } from 'maplibre-gl';
import Supercluster from 'supercluster';
import { gsap } from 'gsap';
import { PIN_ICON_DEFAULT, pinIconByTyp } from '../../data/live-map';
import { prefersReducedMotion } from '../motion';
import type { TrailPin } from './data';
import type { LngLat } from './map';

type Handlers = {
  onTrail: (trail: TrailPin, button: HTMLButtonElement) => void;
  /** Cluster angeklickt: Ziel für die GSAP-Kamera */
  onCluster: (center: LngLat, zoom: number) => void;
};

type Entry = { marker: Marker; button: HTMLButtonElement };

// Ab diesem Zoom sind alle Pins einzeln. PIN_ZOOM (12,5) liegt darüber, ein angefahrener Trail steckt nie in einem Cluster.
const CLUSTER_MAX_ZOOM = 11;
const CLUSTER_RADIUS = 56;

const SVG_NS = 'http://www.w3.org/2000/svg';

/** Pin: Körper + Icon aus den <symbol>s in LiveMap.astro. Das Icon je Ortstyp kommt aus data/live-map.ts. */
function pinSvg(typ: string) {
  const icon = pinIconByTyp[typ] ?? PIN_ICON_DEFAULT;
  const svg = document.createElementNS(SVG_NS, 'svg');
  svg.setAttribute('viewBox', '0 0 24 27');
  svg.setAttribute('aria-hidden', 'true');
  for (const id of ['pin-body', `pin-icon-${icon}`]) {
    const use = document.createElementNS(SVG_NS, 'use');
    use.setAttribute('href', `#${id}`);
    svg.append(use);
  }
  return svg;
}

export function createPins(map: MapLibreMap, trails: TrailPin[], handlers: Handlers) {
  const byId = new Map(trails.map((t) => [t.id, t]));
  const index = new Supercluster<{ id: string }>({ radius: CLUSTER_RADIUS, maxZoom: CLUSTER_MAX_ZOOM, minPoints: 2 });
  index.load(
    trails.map((t) => ({
      type: 'Feature' as const,
      properties: { id: t.id },
      geometry: { type: 'Point' as const, coordinates: [t.lon, t.lat] },
    })),
  );

  const entries = new Map<string, Entry>();
  let activeId: string | null = null;
  let firstDrop = true;
  let raf = 0;

  function makeTrail(t: TrailPin): Entry {
    const wrap = document.createElement('div');
    wrap.className = 'live-marker';
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'live-pin';
    button.dataset.trail = t.id;
    button.setAttribute('aria-label', `${t.name}, ${t.typLabel}`);
    button.setAttribute('aria-haspopup', 'dialog');
    button.setAttribute('aria-expanded', 'false');
    button.append(pinSvg(t.typ));
    button.addEventListener('click', (e) => {
      e.stopPropagation();
      handlers.onTrail(t, button);
    });
    wrap.append(button);
    const marker = new Marker({ element: wrap, anchor: 'bottom' }).setLngLat([t.lon, t.lat]).addTo(map);
    return { marker, button };
  }

  function makeCluster(id: number, count: number, coords: LngLat): Entry {
    const wrap = document.createElement('div');
    wrap.className = 'live-marker';
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'live-cluster';
    button.dataset.size = count >= 25 ? 'l' : count >= 8 ? 'm' : 's';
    button.setAttribute('aria-label', `${count} Pfade, zum Hineinzoomen aktivieren`);
    const num = document.createElement('span');
    num.textContent = String(count);
    button.append(num);
    button.addEventListener('click', (e) => {
      e.stopPropagation();
      const zoom = Math.min(index.getClusterExpansionZoom(id), CLUSTER_MAX_ZOOM + 1.5);
      handlers.onCluster(coords, Math.max(zoom, map.getZoom() + 1));
    });
    wrap.append(button);
    const marker = new Marker({ element: wrap, anchor: 'center' }).setLngLat(coords).addTo(map);
    return { marker, button };
  }

  function applyActive() {
    for (const [key, { button }] of entries) {
      if (!key.startsWith('t:')) continue;
      const on = key === `t:${activeId}`;
      button.classList.toggle('is-active', on);
      button.setAttribute('aria-expanded', String(on));
    }
  }

  function refresh() {
    const b = map.getBounds();
    const padLng = (b.getEast() - b.getWest()) * 0.15;
    const padLat = (b.getNorth() - b.getSouth()) * 0.15;
    const bbox: [number, number, number, number] = [
      Math.max(-180, b.getWest() - padLng),
      Math.max(-85, b.getSouth() - padLat),
      Math.min(180, b.getEast() + padLng),
      Math.min(85, b.getNorth() + padLat),
    ];
    const items = index.getClusters(bbox, Math.max(0, Math.floor(map.getZoom())));

    const seen = new Set<string>();
    const fresh: HTMLElement[] = [];

    for (const f of items) {
      const [lng, lat] = f.geometry.coordinates;
      const props = f.properties as { cluster?: boolean; cluster_id?: number; point_count?: number; id?: string };
      const key = props.cluster ? `c:${props.cluster_id}` : `t:${props.id}`;
      seen.add(key);
      if (entries.has(key)) continue;

      let entry: Entry | null = null;
      if (props.cluster) entry = makeCluster(props.cluster_id as number, props.point_count as number, [lng, lat]);
      else {
        const t = byId.get(props.id as string);
        if (t) entry = makeTrail(t);
      }
      if (!entry) continue;
      entries.set(key, entry);
      fresh.push(entry.button);
    }

    for (const [key, entry] of entries) {
      if (seen.has(key)) continue;
      entry.marker.remove();
      entries.delete(key);
    }

    applyActive();
    if (fresh.length) appear(fresh);
  }

  /** Erste Welle: Pins fallen gestaffelt ein. Danach nur ein kurzes Einblenden. */
  function appear(buttons: HTMLElement[]) {
    if (prefersReducedMotion()) return;
    if (firstDrop) {
      firstDrop = false;
      gsap.from(buttons, {
        y: -28,
        opacity: 0,
        scale: 0.8,
        duration: 0.55,
        ease: 'back.out(1.8)',
        stagger: { each: 0.035, from: 'random' },
        clearProps: 'all',
        onComplete: () => buttons.forEach((el) => el.getAttribute('style') === '' && el.removeAttribute('style')),
      });
      return;
    }
    gsap.from(buttons, {
      opacity: 0,
      scale: 0.85,
      duration: 0.3,
      ease: 'power2.out',
      clearProps: 'all',
      onComplete: () => buttons.forEach((el) => el.getAttribute('style') === '' && el.removeAttribute('style')),
    });
  }

  // Während einer GSAP-Fahrt feuert jeder Frame move/moveend: pro Frame höchstens ein Abgleich
  const schedule = () => {
    if (raf) return;
    raf = requestAnimationFrame(() => {
      raf = 0;
      refresh();
    });
  };
  map.on('moveend', schedule);
  map.on('zoomend', schedule);
  refresh();

  return {
    trail: (id: string) => byId.get(id),
    button: (id: string) => entries.get(`t:${id}`)?.button ?? null,
    setActive(id: string | null) {
      activeId = id;
      applyActive();
    },
    refresh,
  };
}

export type Pins = ReturnType<typeof createPins>;
