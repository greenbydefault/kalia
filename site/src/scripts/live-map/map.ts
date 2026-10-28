import { Map as MapLibreMap, NavigationControl, setWorkerUrl } from 'maplibre-gl';
// Worker als eigenes Asset: Vites Dep-Optimierung findet die Worker-Datei sonst nicht ("Worker failed to load")
import workerUrl from 'maplibre-gl/dist/maplibre-gl-worker.mjs?url';
import 'maplibre-gl/dist/maplibre-gl.css';
import { gsap } from 'gsap';
import {
  ATTRIBUTION,
  MAX_ZOOM,
  MIN_ZOOM,
  START_CENTER,
  START_ZOOM,
  TILE_MAX_ZOOM,
  TILE_SIZE,
  TILE_URL,
} from '../../data/live-map';
import { prefersReducedMotion } from '../motion';

export type LngLat = [number, number];
export type CameraTarget = { center: LngLat; zoom: number };

const WORLD = 512; // MapLibre: Weltbreite bei Zoom 0

/** Mercator-Pixel der Welt bei Zoom z. */
function toWorld([lng, lat]: LngLat, z: number) {
  const s = WORLD * 2 ** z;
  const sin = Math.sin((lat * Math.PI) / 180);
  return { x: ((lng + 180) / 360) * s, y: (0.5 - Math.log((1 + sin) / (1 - sin)) / (4 * Math.PI)) * s };
}

function fromWorld(p: { x: number; y: number }, z: number): LngLat {
  const s = WORLD * 2 ** z;
  const lng = (p.x / s) * 360 - 180;
  const n = Math.PI - (2 * Math.PI * p.y) / s;
  const lat = (180 / Math.PI) * Math.atan(0.5 * (Math.exp(n) - Math.exp(-n)));
  return [lng, lat];
}

/**
 * Kamerazentrum so, dass `point` bei Zoom `zoom` an der Bildschirmposition (sx, sy) des Kartenfensters steht.
 * Damit sitzt der Pin neben dem Popover statt mittig dahinter.
 */
export function centerForPointAt(point: LngLat, zoom: number, sx: number, sy: number, w: number, h: number): LngLat {
  const p = toWorld(point, zoom);
  return fromWorld({ x: p.x + (w / 2 - sx), y: p.y + (h / 2 - sy) }, zoom);
}

export function createMap(container: HTMLElement) {
  setWorkerUrl(workerUrl);
  const map = new MapLibreMap({
    container,
    style: {
      version: 8,
      sources: {
        osm: {
          type: 'raster',
          tiles: [TILE_URL],
          tileSize: TILE_SIZE,
          maxzoom: TILE_MAX_ZOOM,
          attribution: ATTRIBUTION,
        },
      },
      layers: [{ id: 'osm', type: 'raster', source: 'osm' }],
    },
    center: START_CENTER,
    zoom: START_ZOOM,
    minZoom: MIN_ZOOM,
    maxZoom: MAX_ZOOM,
    renderWorldCopies: false,
    attributionControl: { compact: true },
    dragRotate: false,
    pitchWithRotate: false,
    touchPitch: false,
    // Wheel-Zoom nur mit Strg/Cmd, mobil zwei Finger. Sonst frisst die Karte das Scrollen der Seite.
    cooperativeGestures: true,
    locale: {
      'CooperativeGesturesHandler.WindowsHelpText': 'Strg + Scrollen zum Zoomen der Karte',
      'CooperativeGesturesHandler.MacHelpText': '⌘ + Scrollen zum Zoomen der Karte',
      'CooperativeGesturesHandler.MobileHelpText': 'Zwei Finger zum Bewegen der Karte',
      'NavigationControl.ZoomIn': 'Vergrößern',
      'NavigationControl.ZoomOut': 'Verkleinern',
      'AttributionControl.ToggleAttribution': 'Quellenangabe ein-/ausblenden',
      'AttributionControl.MapFeedback': 'Kartenfeedback',
    },
  });
  map.touchZoomRotate.disableRotation();
  map.addControl(new NavigationControl({ showCompass: false }), 'top-right');
  return map;
}

/**
 * Kamera. GSAP tweent Center und Zoom, MapLibre bekommt pro Frame ein jumpTo.
 * Bei weiten Strecken zoomt die Fahrt in der Mitte kurz heraus. Nutzer-Eingaben brechen sie ab.
 */
export function createCamera(map: MapLibreMap) {
  let tween: gsap.core.Tween | null = null;

  const stop = () => {
    tween?.kill();
    tween = null;
  };

  // Nur echte Eingaben (originalEvent) brechen ab, jumpTo des Tweens selbst nicht.
  for (const ev of ['mousedown', 'touchstart', 'wheel'] as const) {
    map.on(ev, (e) => {
      const orig = (e as { originalEvent?: MouseEvent | TouchEvent | WheelEvent }).originalEvent;
      if (!orig) return;
      // Wheel ohne Strg/Cmd scrollt nur die Seite (cooperativeGestures), das ist keine Kamera-Eingabe
      if (ev === 'wheel' && !(orig as WheelEvent).ctrlKey && !(orig as WheelEvent).metaKey) return;
      stop();
    });
  }

  function fly(target: CameraTarget, { duration = 1, onComplete }: { duration?: number; onComplete?: () => void } = {}): number {
    stop();
    const from = map.getCenter();
    const z0 = map.getZoom();
    const z1 = Math.min(MAX_ZOOM, Math.max(MIN_ZOOM, target.zoom));

    if (prefersReducedMotion() || duration <= 0) {
      map.jumpTo({ center: target.center, zoom: z1 });
      onComplete?.();
      return 0;
    }

    // Wie weit ist die Strecke gemessen an der Fensterbreite? Weit = in der Mitte herauszoomen.
    const zMin = Math.min(z0, z1);
    const a = toWorld([from.lng, from.lat], zMin);
    const b = toWorld(target.center, zMin);
    const dist = Math.hypot(b.x - a.x, b.y - a.y);
    const width = map.getContainer().clientWidth || 800;
    const dip = dist > width ? Math.min(3, Math.log2(dist / width) * 0.7) : 0;

    const span = { t: 0 };
    const total = Math.min(2.2, duration + dip * 0.25);

    tween = gsap.to(span, {
      t: 1,
      duration: total,
      ease: 'power2.inOut',
      onUpdate: () => {
        const t = span.t;
        const zoom = z0 + (z1 - z0) * t - dip * Math.sin(Math.PI * t);
        // Center im Weltraster des jeweiligen Zooms interpolieren, damit die Fahrt gerade bleibt
        const p0 = toWorld([from.lng, from.lat], zMin);
        const p1 = toWorld(target.center, zMin);
        const c = fromWorld({ x: p0.x + (p1.x - p0.x) * t, y: p0.y + (p1.y - p0.y) * t }, zMin);
        map.jumpTo({ center: c, zoom });
      },
      onComplete: () => {
        tween = null;
        map.jumpTo({ center: target.center, zoom: z1 });
        onComplete?.();
      },
    });
    return total;
  }

  return { fly, stop };
}

export type Camera = ReturnType<typeof createCamera>;
