#!/usr/bin/env python3
"""Karten-Ausschnitt aus OSM-Tiles als Standbild (Hintergrund der Ausflug-Sektion, site/src/data/ausflug.ts).

Einmaliger Abruf, kein Dauerbetrieb: wenige Tiles, nacheinander, mit eigenem User-Agent (Tile Usage Policy
https://operations.osmfoundation.org/policies/tiles/). Das Ergebnis ist ein Platzhalter. Später je Tab ein Bild
aus Figma oder der App ablegen und den Pfad in ausflug.ts ändern.

Aufruf (aus dem Repo-Root):
  python3 tools/osm_cutout.py [lng lat zoom [breite hoehe [ausgabe]]]
Standard: Prignitz, Zoom 11, 1200 x 1090, site/public/img/ausflug/karte-platzhalter.webp
Braucht Pillow. Quelle © OpenStreetMap-Mitwirkende (ODbL), die Seite nennt sie unter dem Bild.
"""
import io
import math
import sys
import time
import urllib.request
from pathlib import Path

from PIL import Image

TILE = 256
URL = "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
UA = "kalia-landingpage-cutout/1.0 (einmaliger Abruf fuer ein Standbild)"


def world_px(lng: float, lat: float, z: int) -> tuple[float, float]:
    n = TILE * 2**z
    sin = math.sin(math.radians(lat))
    return (lng + 180) / 360 * n, (0.5 - math.log((1 + sin) / (1 - sin)) / (4 * math.pi)) * n


def main() -> None:
    a = sys.argv[1:]
    lng, lat, z = (float(a[0]), float(a[1]), int(a[2])) if len(a) >= 3 else (12.75, 53.19, 11)
    w, h = (int(a[3]), int(a[4])) if len(a) >= 5 else (1200, 1090)
    out = Path(a[5]) if len(a) >= 6 else Path("site/public/img/ausflug/karte-platzhalter.webp")

    cx, cy = world_px(lng, lat, z)
    left, top = cx - w / 2, cy - h / 2
    x0, x1 = int(left // TILE), int((left + w) // TILE)
    y0, y1 = int(top // TILE), int((top + h) // TILE)
    print(f"{(x1 - x0 + 1) * (y1 - y0 + 1)} Tiles, Zoom {z}")

    canvas = Image.new("RGB", ((x1 - x0 + 1) * TILE, (y1 - y0 + 1) * TILE))
    for ty in range(y0, y1 + 1):
        for tx in range(x0, x1 + 1):
            req = urllib.request.Request(URL.format(z=z, x=tx, y=ty), headers={"User-Agent": UA})
            with urllib.request.urlopen(req, timeout=30) as r:
                tile = Image.open(io.BytesIO(r.read())).convert("RGB")
            canvas.paste(tile, ((tx - x0) * TILE, (ty - y0) * TILE))
            time.sleep(0.4)

    ox, oy = int(left - x0 * TILE), int(top - y0 * TILE)
    cut = canvas.crop((ox, oy, ox + w, oy + h))
    out.parent.mkdir(parents=True, exist_ok=True)
    cut.save(out, "WEBP", quality=55, method=6)
    print(f"{out} ({out.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
