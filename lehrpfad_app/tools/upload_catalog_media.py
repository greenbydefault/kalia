#!/usr/bin/env python3
"""Einmal-Import: gebuendelte Katalog-Medien nach Supabase Storage.

  Trail-Hero  assets/images/trails/<id>/credits.json + <slug>.{thumb,small,medium}.avif
              -> Bucket trail-images ({trail}/{image}/{variant}.avif)
              + images-Zeile (source=official, status=approved), sort = Position
  Art-Audio   assets/audio/species/<id>.mp3  (nur mit --species-audio)
              -> Bucket catalog-media (species/<id>/audio.mp3)
              + species.audio_path = 'storage:catalog-media/species/<id>/audio.mp3'

Nutzung:
  export SUPABASE_URL="https://<projekt>.supabase.co"
  export SUPABASE_SERVICE_KEY="<service_role key>"   # niemals in die App!
  python3 tools/upload_catalog_media.py [--trail <id>] [--species-audio] [--dry-run]

Idempotent: die Bild-ID ist deterministisch (uuid5 aus Trail + Dateiname),
Uploads laufen mit upsert.

Reihenfolge beim Rollout: erst eine App-Version mit Remote-Support
(TrailHero.slidesFor, Audio-URL) ausliefern, dann dieses Script. Aeltere
App-Staende wuerden die Hero-Bilder doppelt zeigen bzw. `storage:`-Audio
nicht abspielen.
Nur Stdlib.
"""
import json
import os
import sys
import urllib.error
import urllib.request
import uuid

ROOT = os.path.join(os.path.dirname(__file__), "..")
TRAILS_DIR = os.path.join(ROOT, "assets", "images", "trails")
AUDIO_DIR = os.path.join(ROOT, "assets", "audio", "species")
NAMESPACE = uuid.UUID("6f1c1d5e-0a5b-4f43-9a6a-1e6f2b8f0c11")
VARIANTS = ("thumb", "small", "medium")


def env():
    key = os.environ.get("SUPABASE_SERVICE_KEY")
    url = os.environ.get("SUPABASE_URL", "").rstrip("/")
    if not key or not url:
        sys.exit("SUPABASE_URL und SUPABASE_SERVICE_KEY muessen gesetzt sein.")
    return url, key


def http(method, url, key, body=None, headers=None):
    h = {"apikey": key, "Authorization": "Bearer " + key}
    h.update(headers or {})
    request = urllib.request.Request(url, data=body, headers=h, method=method)
    try:
        with urllib.request.urlopen(request) as resp:
            raw = resp.read()
            return json.loads(raw) if raw and raw[:1] in (b"{", b"[") else raw
    except urllib.error.HTTPError as e:
        sys.exit("HTTP %s bei %s %s: %s" % (e.code, method, url, e.read().decode()))


def upload(url, key, bucket, path, data, content_type):
    http("POST", "%s/storage/v1/object/%s/%s" % (url, bucket, path), key, data,
         {"Content-Type": content_type, "x-upsert": "true", "Cache-Control": "max-age=31536000"})


def slug_of(file):
    base = file.split("/")[-1]
    for ext in (".jpg", ".jpeg", ".png", ".webp", ".avif"):
        if base.lower().endswith(ext):
            return base[: -len(ext)]
    return base


def hero(url, key, only, dry):
    count = 0
    for tid in sorted(os.listdir(TRAILS_DIR)):
        folder = os.path.join(TRAILS_DIR, tid)
        creds = os.path.join(folder, "credits.json")
        if not os.path.isfile(creds) or (only and tid != only):
            continue
        with open(creds, encoding="utf-8") as f:
            entries = json.load(f)
        sort = 0
        for e in entries:
            if e.get("kind") == "placeholder":
                continue
            slug = slug_of(e["file"])
            files = {v: os.path.join(folder, "%s.%s.avif" % (slug, v)) for v in VARIANTS}
            if not all(os.path.isfile(p) for p in files.values()):
                print("  uebersprungen (Varianten fehlen): %s/%s" % (tid, slug))
                continue
            sort += 1
            iid = str(uuid.uuid5(NAMESPACE, "%s/%s" % (tid, slug)))
            sizes = {}
            for v, p in files.items():
                with open(p, "rb") as f:
                    data = f.read()
                sizes[v] = len(data)
                if not dry:
                    upload(url, key, "trail-images", "%s/%s/%s.avif" % (tid, iid, v), data, "image/avif")
            row = {
                "id": iid, "trail_id": tid, "station_id": None, "uploader_id": None,
                "source": "official", "status": "approved",
                "credit": e.get("credit", ""), "caption": e.get("caption", ""),
                "license": e.get("license", ""), "license_url": e.get("licenseUrl", ""),
                "source_url": e.get("sourceUrl", ""), "kind": e.get("kind"),
                "sort": sort, "mime_type": "image/avif",
                "thumb_bytes": sizes["thumb"], "small_bytes": sizes["small"],
                "medium_bytes": sizes["medium"],
            }
            if not dry:
                http("POST", url + "/rest/v1/images?on_conflict=id", key,
                     json.dumps(row).encode(),
                     {"Content-Type": "application/json",
                      "Prefer": "resolution=merge-duplicates,return=minimal"})
            count += 1
            print("  %s/%s" % (tid, slug))
    print("Hero-Bilder: %d%s" % (count, " (dry-run)" if dry else ""))


def audio(url, key, dry):
    count = 0
    for name in sorted(os.listdir(AUDIO_DIR)):
        if not name.endswith(".mp3"):
            continue
        sid = name[:-4]
        path = "species/%s/audio.mp3" % sid
        if not dry:
            with open(os.path.join(AUDIO_DIR, name), "rb") as f:
                upload(url, key, "catalog-media", path, f.read(), "audio/mpeg")
            http("PATCH", "%s/rest/v1/species?id=eq.%s" % (url, sid), key,
                 json.dumps({"audio_path": "storage:catalog-media/" + path}).encode(),
                 {"Content-Type": "application/json", "Prefer": "return=minimal"})
        count += 1
        print("  %s" % sid)
    print("Art-Audio: %d%s" % (count, " (dry-run)" if dry else ""))


def main():
    args = sys.argv[1:]
    dry = "--dry-run" in args
    only = args[args.index("--trail") + 1] if "--trail" in args else None
    url, key = env()
    hero(url, key, only, dry)
    if "--species-audio" in args:
        audio(url, key, dry)


if __name__ == "__main__":
    main()
