import { existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const pub = (p: string) => existsSync(fileURLToPath(new URL(`../../public${p}`, import.meta.url)));

export const MILL_TOWER = '/img/mill/mill-tower.svg';
export const MILL_WHEEL = '/img/mill/mill-wheel.svg';
export const MAP_WITHOUT_MILL = '/img/kalia-map-ohne-muehle-3840.webp';

/**
 * Windmühle dreht sich nur, wenn alle drei Dateien da sind: Turm, Rad und Karte ohne Mühle.
 * Sonst bleibt die Mühle im Kartenbild stehen. Dateien ablegen reicht, kein Code nötig.
 */
export const millSplit = pub(MILL_TOWER) && pub(MILL_WHEEL) && pub(MAP_WITHOUT_MILL);
