import { fetchTrails, type TrailPin } from './data';
import { createCamera, createMap } from './map';
import { createPins } from './pins';
import { createPopup } from './popup';
import { createSearch } from './search';

/** Baut die Live-Karte auf. Wird erst geladen, wenn die Sektion fast im Bild ist (siehe index.ts). */
export async function mountLiveMap(root: HTMLElement) {
  const frame = root.querySelector<HTMLElement>('[data-lm-frame]');
  const canvas = root.querySelector<HTMLElement>('[data-lm-canvas]');
  const note = root.querySelector<HTMLElement>('[data-lm-note]');
  if (!frame || !canvas) return;

  // Daten und Karte parallel starten
  const loading = fetchTrails().catch((err) => {
    console.warn('Live-Karte: Trails nicht geladen', err);
    return null;
  });

  const map = createMap(canvas);
  const camera = createCamera(map);

  const trails: TrailPin[] | null = await loading;
  if (!trails && note) {
    note.textContent = 'Die Pfade lassen sich gerade nicht laden. Die Karte läuft trotzdem, versucht es später noch einmal.';
    note.hidden = false;
  }

  // Popup und Pins kennen sich gegenseitig: Pins rufen popup.open, Popup braucht pins.button/setActive
  const handlers = {
    onTrail: (t: TrailPin) => popup.open(t),
    onCluster: (center: [number, number], zoom: number) => {
      popup.close({ refocus: false });
      camera.fly({ center, zoom }, { duration: 0.8 });
    },
  };
  const pins = createPins(map, trails ?? [], handlers);
  const popup = createPopup(frame, map, camera, pins);
  createSearch(frame, map, camera, popup, trails ?? []);

  root.dataset.ready = 'true';
}
