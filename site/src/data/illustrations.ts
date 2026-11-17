import { existsSync } from 'node:fs';
import { join } from 'node:path';
import cms from './illustrations.json';

/**
 * Arten-Illustrationen. Quelle ist das CMS (Spalte species.illustration_path, dieselbe wie in der App),
 * `tools/sync-illustrations.mjs` schreibt illustrations.json vor dem Build.
 * Übergang: Gibt es für eine Art noch keinen CMS-Eintrag, greift die alte Datei unter
 * public/img/arten/{id}.svg. Sobald tools/upload_illustrations.py gelaufen ist, kann der Ordner weg.
 */
export type Illustration = { src: string; name?: string };

const table = cms as Record<string, { url: string; name: string }>;

export function illustration(id: string): Illustration | null {
  const hit = table[id];
  if (hit) return { src: hit.url, name: hit.name };
  const legacy = `/img/arten/${id}.svg`;
  return existsSync(join(process.cwd(), 'public', legacy)) ? { src: legacy } : null;
}
