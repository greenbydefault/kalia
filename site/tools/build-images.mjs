/**
 * Erzeugt die AVIF-Dateien der Landingpage aus den vorhandenen WebP-Quellen (public/img/).
 * Aufruf: npm run images (nur bei neuer Karte oder neuen Platzhaltern, die .avif liegen im Repo).
 *
 * Karte (Hero):
 *   <base>-1920.avif, <base>-3840.avif   volles Bild (Desktop)
 *   <base>-m-1280.avif, <base>-m-1920.avif   Mobil-Ausschnitt, oben und unten beschnitten
 * Der Ausschnitt muss zu --crop-t / --crop-k in styles/components/map.css passen (Werte unten).
 *
 * Ausflug: Platzhalter-Karte und -Screen als AVIF (die .webp bleiben als Quelle liegen).
 * Nur die Variante "ohne Mühle" (siehe data/assets.ts). Fehlt die Trennung, bleibt die Karte bei WebP.
 */
import { existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import sharp from 'sharp';

const img = (p) => fileURLToPath(new URL(`../public/img/${p}`, import.meta.url));

const FULL_W = 3840;
const FULL_H = 2508;
// Mobil: 8 % oben und 12 % unten weg. Pins liegen bei y = 24 … 68,5 %, die Kamera braucht Luft darum.
const CROP_TOP = Math.round(FULL_H * 0.08); // 201
const CROP_H = Math.round(FULL_H * 0.8); // 2006

const avif = (quality) => ({ quality, effort: 6 });

async function map(base) {
  const src = img(`${base}-3840.webp`);
  if (!existsSync(src)) return;
  const full = () => sharp(src);
  const crop = () => sharp(src).extract({ left: 0, top: CROP_TOP, width: FULL_W, height: CROP_H });

  await full().resize(1920).avif(avif(50)).toFile(img(`${base}-1920.avif`));
  await full().resize(3840).avif(avif(50)).toFile(img(`${base}-3840.avif`));
  await crop().resize(1280).avif(avif(52)).toFile(img(`${base}-m-1280.avif`));
  await crop().resize(1920).avif(avif(50)).toFile(img(`${base}-m-1920.avif`));
  console.log(`${base}: ok (Ausschnitt oben ${CROP_TOP} px, Höhe ${CROP_H} px)`);
}

async function plain(file, quality) {
  const src = img(`ausflug/${file}.webp`);
  if (!existsSync(src)) return;
  await sharp(src).avif(avif(quality)).toFile(img(`ausflug/${file}.avif`));
  console.log(`ausflug/${file}: ok`);
}

await map('kalia-map-ohne-muehle');
await plain('karte-platzhalter', 38);
await plain('screen-platzhalter', 60);
