import { existsSync } from 'node:fs';
import { join } from 'node:path';

// process.cwd() statt import.meta.url: im Build liegt dieses Modul in einem Chunk, der relative Pfad zu public/ stimmt dort nicht
const pub = (p: string) => existsSync(join(process.cwd(), 'public', p));

export const MILL_TOWER = '/img/mill/mill-tower.svg';
export const MILL_WHEEL = '/img/mill/mill-wheel.svg';
export const MAP_WITHOUT_MILL = '/img/kalia-map-ohne-muehle-3840.webp';

/**
 * Windmühle dreht sich nur, wenn alle drei Dateien da sind: Turm, Rad und Karte ohne Mühle.
 * Sonst bleibt die Mühle im Kartenbild stehen. Dateien ablegen reicht, kein Code nötig.
 */
export const millSplit = pub(MILL_TOWER) && pub(MILL_WHEEL) && pub(MAP_WITHOUT_MILL);
