#!/usr/bin/env python3
"""Laedt assets/seed/pois.json und assets/seed/nearby_zeiten.json nach Supabase.

- pois: Upsert auf id.
- trail_pois (Fahrzeit Trail -> Ort): pro Trail erst alle alten Zeilen loeschen, dann
  einfuegen. So bleiben keine Orte stehen, die ueber 20 Min gefallen sind.

Idempotent. Offline-Seed und Live-Katalog bleiben gleich.

Nutzung:
  export SUPABASE_URL="https://<projekt>.supabase.co"
  export SUPABASE_SERVICE_KEY="<service_role key>"
  python3 tools/seed_pois.py                 # pois + alle Fahrzeiten
  python3 tools/seed_pois.py --trail <id>    # pois + nur Fahrzeiten dieses Trails
  python3 tools/seed_pois.py --nur-pois      # nur pois
"""
import argparse
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request

SEED_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "seed")
SEED_PATH = os.path.join(SEED_DIR, "pois.json")
ZEITEN_PATH = os.path.join(SEED_DIR, "nearby_zeiten.json")
BATCH = 500


def req(method, path, key, payload=None, prefer="return=minimal"):
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


def row(p):
    return {
        "id": p["id"],
        "name": p["name"],
        "kategorie": p["kategorie"],
        "kurztext": p.get("kurztext") or "",
        "lat": p["lat"],
        "lon": p["lon"],
        "website": p.get("website"),
        "oeffnungszeiten": p.get("oeffnungszeiten"),
        "opening_hours": p.get("opening_hours"),
        "telefon": p.get("telefon"),
    }


def zeiten_rows(trail_id, eintraege):
    return [{"trail_id": trail_id, "poi_id": e["poi"], "sek": e["sek"]} for e in eintraege]


def seed_zeiten(key, nur_trail=None):
    with open(ZEITEN_PATH, encoding="utf-8") as f:
        zeiten = json.load(f)
    if nur_trail:
        if nur_trail not in zeiten:
            sys.exit("Trail %r nicht in nearby_zeiten.json" % nur_trail)
        zeiten = {nur_trail: zeiten[nur_trail]}
    rows = 0
    for trail_id in sorted(zeiten):
        req("DELETE", "trail_pois?trail_id=eq." + urllib.parse.quote(trail_id, safe=""), key)
        neu = zeiten_rows(trail_id, zeiten[trail_id])
        for i in range(0, len(neu), BATCH):
            req("POST", "trail_pois", key, neu[i : i + BATCH])
        rows += len(neu)
    print("OK: %d Fahrzeiten fuer %d Trails geladen." % (rows, len(zeiten)))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("path", nargs="?", default=SEED_PATH, help="pois.json (Default: Seed)")
    ap.add_argument("--trail", metavar="ID", help="nur Fahrzeiten dieses Trails")
    ap.add_argument("--nur-pois", action="store_true", help="keine Fahrzeiten")
    args = ap.parse_args()

    key = os.environ.get("SUPABASE_SERVICE_KEY")
    if not key or not os.environ.get("SUPABASE_URL"):
        sys.exit("SUPABASE_URL und SUPABASE_SERVICE_KEY muessen gesetzt sein.")

    with open(args.path, encoding="utf-8") as f:
        pois = json.load(f)

    rows = [row(p) for p in pois]
    req(
        "POST",
        "pois?on_conflict=id",
        key,
        rows,
        prefer="resolution=merge-duplicates,return=minimal",
    )
    print("OK: %d Orte in der Naehe geladen." % len(rows))

    if not args.nur_pois:
        seed_zeiten(key, args.trail)


if __name__ == "__main__":
    main()
