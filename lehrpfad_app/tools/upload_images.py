#!/usr/bin/env python3
"""Laedt offizielle Bilder (Betreiber-Material) in Supabase Storage + images-Tabelle.

Nutzung:
  export SUPABASE_URL="https://<projekt>.supabase.co"
  export SUPABASE_SERVICE_KEY="<service_role key>"   # niemals in die App!
  python3 tools/upload_images.py [tools/official_images/manifest.json]

Manifest-Format (JSON-Liste), Dateipfade relativ zum Manifest:
  [
    {"file": "moor_einstieg.jpg", "trail_id": "von-moor-zu-moor",
     "station": null,  "credit": "Naturpark Stechlin"},
    {"file": "barschsee.jpg",     "trail_id": "von-moor-zu-moor",
     "station": 4,     "credit": "Naturpark Stechlin"}
  ]

  station = null        -> Bild fuer die ganze Strecke
  station = <Nummer>    -> reihenfolge der Station (wird auf stations.id aufgeloest)

Pro Bild werden drei AVIF-Varianten erzeugt (200/600/1600 px laengste Kante)
und unter {trail_id}/{image_id}/{thumb,small,medium}.avif gespeichert –
dieselbe Konvention wie bei User-Uploads aus der App. Eintraege bekommen
source='official' und status='approved' (keine Moderation noetig).

Idempotent: die Bild-ID ist uuid5(trail_id + Dateiname), erneutes Ausfuehren
ueberschreibt Dateien und DB-Eintrag.

Dependencies: pip install pillow pillow-avif-plugin
WICHTIG Urheberrecht: nur Bilder mit ausdruecklicher Nutzungserlaubnis
hochladen und den Rechteinhaber im credit-Feld nennen.
"""
import io
import json
import os
import sys
import urllib.error
import urllib.request
import uuid

try:
    from PIL import Image, ImageOps
    import pillow_avif  # noqa: F401  (registriert AVIF in Pillow)
except ImportError:
    sys.exit("Fehlende Dependencies: pip install pillow pillow-avif-plugin")

MANIFEST_PATH = os.path.join(
    os.path.dirname(__file__), "official_images", "manifest.json"
)
BUCKET = "trail-images"
VARIANTS = {"thumb": 200, "small": 600, "medium": 1600}
# Fester Namespace, damit IDs ueber Laeufe hinweg stabil bleiben
ID_NAMESPACE = uuid.UUID("3f8b2c1e-7a4d-4e5f-9c6b-2d8a1e0f5b3a")


def rest(method, path, key, payload=None, prefer="return=minimal"):
    url = os.environ["SUPABASE_URL"].rstrip("/") + "/rest/v1/" + path
    headers = {
        "apikey": key,
        "Authorization": "Bearer " + key,
        "Content-Type": "application/json",
        "Prefer": prefer,
    }
    data = json.dumps(payload).encode() if payload is not None else None
    request = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request) as resp:
            body = resp.read()
            return json.loads(body) if body else None
    except urllib.error.HTTPError as e:
        sys.exit("HTTP %s bei %s %s: %s" % (e.code, method, path, e.read().decode()))


def storage_upload(path, data, key):
    url = (
        os.environ["SUPABASE_URL"].rstrip("/")
        + "/storage/v1/object/" + BUCKET + "/" + path
    )
    headers = {
        "apikey": key,
        "Authorization": "Bearer " + key,
        "Content-Type": "image/avif",
        "x-upsert": "true",
        "cache-control": "31536000",
    }
    request = urllib.request.Request(url, data=data, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(request) as resp:
            resp.read()
    except urllib.error.HTTPError as e:
        sys.exit("HTTP %s bei Storage-Upload %s: %s" % (e.code, path, e.read().decode()))


def avif_variant(img, max_edge):
    longest = max(img.width, img.height)
    if longest > max_edge:
        if img.width >= img.height:
            work = img.resize((max_edge, round(img.height * max_edge / img.width)),
                              Image.LANCZOS)
        else:
            work = img.resize((round(img.width * max_edge / img.height), max_edge),
                              Image.LANCZOS)
    else:
        work = img
    buf = io.BytesIO()
    work.save(buf, format="AVIF", quality=60)
    return buf.getvalue()


def main():
    key = os.environ.get("SUPABASE_SERVICE_KEY")
    if not key or not os.environ.get("SUPABASE_URL"):
        sys.exit("SUPABASE_URL und SUPABASE_SERVICE_KEY muessen gesetzt sein.")

    manifest_path = sys.argv[1] if len(sys.argv) > 1 else MANIFEST_PATH
    base_dir = os.path.dirname(os.path.abspath(manifest_path))
    with open(manifest_path, encoding="utf-8") as f:
        entries = json.load(f)

    for entry in entries:
        trail_id = entry["trail_id"]
        credit = entry.get("credit", "")
        file_path = os.path.join(base_dir, entry["file"])
        if not os.path.exists(file_path):
            sys.exit("Datei nicht gefunden: %s" % file_path)

        # Station (reihenfolge) auf stations.id aufloesen
        station_id = None
        if entry.get("station") is not None:
            rows = rest(
                "GET",
                "stations?trail_id=eq.%s&reihenfolge=eq.%d&select=id"
                % (trail_id, entry["station"]),
                key,
            )
            if not rows:
                sys.exit("Station %d von Trail '%s' nicht gefunden."
                         % (entry["station"], trail_id))
            station_id = rows[0]["id"]

        image_id = str(uuid.uuid5(ID_NAMESPACE, "%s:%s" % (trail_id, entry["file"])))

        with Image.open(file_path) as im:
            img = ImageOps.exif_transpose(im).convert("RGB")
            width, height = img.width, img.height
            for variant, max_edge in VARIANTS.items():
                data = avif_variant(img, max_edge)
                storage_upload("%s/%s/%s.avif" % (trail_id, image_id, variant),
                               data, key)

        rest("POST", "images", key, {
            "id": image_id,
            "trail_id": trail_id,
            "station_id": station_id,
            "uploader_id": None,
            "source": "official",
            "status": "approved",
            "credit": credit,
            "width": width,
            "height": height,
        }, prefer="resolution=merge-duplicates,return=minimal")

        print("OK: %s -> %s (%s)" % (entry["file"], image_id,
              "Station %d" % entry["station"] if station_id else "ganze Strecke"))

    print("Fertig: %d Bild(er) verarbeitet." % len(entries))


if __name__ == "__main__":
    main()
