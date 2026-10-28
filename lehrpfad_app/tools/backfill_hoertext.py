#!/usr/bin/env python3
"""Einmalig: schreibt `hoertext` aus den Seed-JSONs in trails.hoertext.

Migration 0034 legt die Spalte an, das Backfill laeuft mit dem Service-Key.
Nur Trails ohne Wert in der DB werden gesetzt (DB ist Master, ADR 0002);
--force ueberschreibt auch vorhandene Texte.

Nutzung:
  export SUPABASE_URL="https://<projekt>.supabase.co"
  export SUPABASE_SERVICE_KEY="<service_role key>"   # niemals in die App!
  python3 tools/backfill_hoertext.py [--force] [--dry-run]

Hinweis: Jedes Update erhoeht trails.data_version (Trigger). Das ist gewollt,
der Text ist neuer Paketinhalt.
Nur Stdlib.
"""
import glob
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request

SEED_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "seed")
NON_TRAIL = {"species", "merkmale", "pois", "nearby_zeiten", "art_pools", "orte_de", "index"}


def req(method, path, key, payload=None):
    url = os.environ["SUPABASE_URL"].rstrip("/") + "/rest/v1/" + path
    headers = {
        "apikey": key,
        "Authorization": "Bearer " + key,
        "Content-Type": "application/json",
        "Prefer": "return=minimal",
    }
    data = json.dumps(payload).encode() if payload is not None else None
    request = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request) as resp:
            body = resp.read()
            return json.loads(body) if body else None
    except urllib.error.HTTPError as e:
        sys.exit("HTTP %s bei %s %s: %s" % (e.code, method, path, e.read().decode()))


def main():
    force = "--force" in sys.argv[1:]
    dry = "--dry-run" in sys.argv[1:]
    key = os.environ.get("SUPABASE_SERVICE_KEY")
    if not key or not os.environ.get("SUPABASE_URL"):
        sys.exit("SUPABASE_URL und SUPABASE_SERVICE_KEY muessen gesetzt sein.")

    rows = req("GET", "trails?select=id,hoertext", key) or []
    db = {r["id"]: (r.get("hoertext") or "") for r in rows}

    done = skipped = 0
    for path in sorted(glob.glob(os.path.join(SEED_DIR, "*.json"))):
        if os.path.splitext(os.path.basename(path))[0] in NON_TRAIL:
            continue
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
        if not isinstance(data, dict) or "stationen" not in data:
            continue
        text = (data.get("hoertext") or "").strip()
        tid = data["id"]
        if not text or tid not in db:
            continue
        if db[tid] and not force:
            skipped += 1
            continue
        print("  %s%s" % (tid, " (dry)" if dry else ""))
        if not dry:
            req("PATCH", "trails?id=eq." + urllib.parse.quote(tid), key, {"hoertext": text})
        done += 1
    print("Fertig: %d gesetzt, %d uebersprungen (DB hatte schon Text)." % (done, skipped))


if __name__ == "__main__":
    main()
