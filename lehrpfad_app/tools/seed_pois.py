#!/usr/bin/env python3
"""Laedt assets/seed/pois.json in die Supabase-Tabelle pois.

Idempotent: Upsert auf id. Offline-Seed und Live-Katalog bleiben gleich.

Nutzung:
  export SUPABASE_URL="https://<projekt>.supabase.co"
  export SUPABASE_SERVICE_KEY="<service_role key>"
  python3 tools/seed_pois.py
"""
import json
import os
import sys
import urllib.error
import urllib.request

SEED_PATH = os.path.join(os.path.dirname(__file__), "..", "assets", "seed", "pois.json")


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


def main():
    key = os.environ.get("SUPABASE_SERVICE_KEY")
    if not key or not os.environ.get("SUPABASE_URL"):
        sys.exit("SUPABASE_URL und SUPABASE_SERVICE_KEY muessen gesetzt sein.")

    path = sys.argv[1] if len(sys.argv) > 1 else SEED_PATH
    with open(path, encoding="utf-8") as f:
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


if __name__ == "__main__":
    main()
