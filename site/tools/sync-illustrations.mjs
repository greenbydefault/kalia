#!/usr/bin/env node
/**
 * Arten-Illustrationen aus dem CMS für die Landingpage übernehmen.
 *
 * Quelle: Supabase, Tabelle `species`, Spalte `illustration_path`
 * (`storage:catalog-media/species/<id>/illu-<hash>.svg`). Dieselbe Spalte liest die App.
 *
 * Schreibt `src/data/illustrations.json`:  { <id>: { url, name } }
 * `url` ist die öffentliche Storage-URL. Der Dateiname trägt einen Hash, ein Tausch im CMS ist
 * also eine neue URL und der lange Cache (1 Jahr) bleibt korrekt. Die Datei selbst liegt weiter
 * im Storage, nichts wird kopiert, der Browser lädt nur, was er anzeigt.
 *
 * Läuft vor `astro build` (prebuild). Ohne Konfiguration oder bei Netzfehler bleibt die
 * eingecheckte JSON unverändert und der Build läuft weiter (Warnung statt Abbruch).
 * Env: PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_PUBLISHABLE_KEY (Prozess-Env oder site/.env).
 * Nutzung: node tools/sync-illustrations.mjs
 */
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const SITE = join(dirname(fileURLToPath(import.meta.url)), '..');
const OUT = join(SITE, 'src', 'data', 'illustrations.json');

function loadDotEnv() {
  const file = join(SITE, '.env');
  if (!existsSync(file)) return {};
  const out = {};
  for (const line of readFileSync(file, 'utf8').split('\n')) {
    const m = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*?)\s*$/);
    if (m) out[m[1]] = m[2].replace(/^["']|["']$/g, '');
  }
  return out;
}

const dot = loadDotEnv();
const url = (process.env.PUBLIC_SUPABASE_URL || dot.PUBLIC_SUPABASE_URL || '').replace(/\/+$/, '');
const key = process.env.PUBLIC_SUPABASE_PUBLISHABLE_KEY || dot.PUBLIC_SUPABASE_PUBLISHABLE_KEY || '';

/** `storage:<bucket>/<objekt>` -> öffentliche URL, https bleibt, alles andere null. */
function resolve(path) {
  if (/^https?:\/\//.test(path)) return path;
  if (!path.startsWith('storage:')) return null;
  return `${url}/storage/v1/object/public/${path.slice('storage:'.length)}`;
}

async function main() {
  if (!url || !key) {
    console.warn('[illustrations] Supabase nicht konfiguriert, behalte src/data/illustrations.json');
    return;
  }
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), 15000);
  try {
    const res = await fetch(
      `${url}/rest/v1/species?select=id,name_de,illustration_path&illustration_path=not.is.null&order=id`,
      { headers: { apikey: key }, signal: ctrl.signal },
    );
    if (!res.ok) throw new Error(`Supabase ${res.status}`);
    const rows = await res.json();
    const out = {};
    for (const r of rows) {
      const u = resolve(r.illustration_path || '');
      if (u) out[r.id] = { url: u, name: r.name_de };
    }
    const json = JSON.stringify(out, null, 2) + '\n';
    const old = existsSync(OUT) ? readFileSync(OUT, 'utf8') : '';
    if (json !== old) writeFileSync(OUT, json);
    console.log(`[illustrations] ${Object.keys(out).length} Illustrationen${json === old ? ' (unverändert)' : ''}`);
  } catch (e) {
    console.warn(`[illustrations] Sync fehlgeschlagen (${e.message}), behalte src/data/illustrations.json`);
  } finally {
    clearTimeout(timer);
  }
}

await main();
