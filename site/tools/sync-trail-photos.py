#!/usr/bin/env python3
"""Hero-Fotos der Trails für die Landing-Karte übernehmen.

Quelle: lehrpfad_app/assets/images/trails/<id>/credits.json + <slug>.small.avif
Pro Trail das erste Foto mit kind=ort (wie der Hero in der App).

Schreibt:
  site/public/img/trails/<id>.avif      (Variante small)
  site/src/data/trail-photos.json       { <id>: { credit, license, licenseUrl, sourceUrl } }

Die Lizenzen (CC BY / CC BY-SA) verlangen Namensnennung, die Karte zeigt sie am Foto.
Nutzung: python3 site/tools/sync-trail-photos.py
Nur Stdlib. Idempotent, entfernt Fotos von Trails, die es nicht mehr gibt.
"""
import json
import os
import shutil

HERE = os.path.dirname(os.path.abspath(__file__))
SITE = os.path.join(HERE, "..")
SRC = os.path.join(SITE, "..", "lehrpfad_app", "assets", "images", "trails")
OUT_DIR = os.path.join(SITE, "public", "img", "trails")
OUT_JSON = os.path.join(SITE, "src", "data", "trail-photos.json")


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    photos = {}
    for trail in sorted(os.listdir(SRC)):
        credits = os.path.join(SRC, trail, "credits.json")
        if not os.path.isfile(credits):
            continue
        with open(credits, encoding="utf-8") as f:
            entries = json.load(f)
        hero = next((e for e in entries if e.get("kind") == "ort"), None)
        if not hero:
            continue
        slug = hero["file"].rsplit(".", 1)[0]
        src = os.path.join(SRC, trail, f"{slug}.small.avif")
        if not os.path.isfile(src):
            print(f"fehlt: {src}")
            continue
        shutil.copyfile(src, os.path.join(OUT_DIR, f"{trail}.avif"))
        photos[trail] = {
            "credit": " ".join(hero.get("credit", "").split()),
            "license": hero.get("license", ""),
            "licenseUrl": hero.get("licenseUrl", ""),
            "sourceUrl": hero.get("sourceUrl", ""),
        }

    for name in os.listdir(OUT_DIR):
        if name.endswith(".avif") and name[:-5] not in photos:
            os.remove(os.path.join(OUT_DIR, name))

    with open(OUT_JSON, "w", encoding="utf-8") as f:
        json.dump(photos, f, ensure_ascii=False, indent=1, sort_keys=True)
        f.write("\n")
    print(f"{len(photos)} Fotos")


if __name__ == "__main__":
    main()
