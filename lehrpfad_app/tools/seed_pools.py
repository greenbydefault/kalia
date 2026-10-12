#!/usr/bin/env python3
"""Laedt assets/seed/art_pools.json in die DB (lebensraeume, pool_naturraeume,
pool_arten). Einmal-Import fuer das Admin-CMS (Migration 0029).

Nutzung:
  export SUPABASE_URL="https://<projekt>.supabase.co"
  export SUPABASE_SERVICE_KEY="<service_role key>"   # niemals in die App!
  python3 tools/seed_pools.py [--force]

Default: nur Lebensraeume/Pools anlegen, die es noch nicht gibt (DB ist Master).
--force ersetzt Pool-Zuordnungen aller Lebensraeume aus der JSON.
Arten-IDs, die nicht in `species` stehen, werden uebersprungen und gemeldet.
Nur Stdlib.
"""
import json
import os
import sys
import urllib.error
import urllib.request

POOLS_PATH = os.path.join(os.path.dirname(__file__), "..", "assets", "seed", "art_pools.json")

LEBENSRAUM_NAMEN = [
    ("kuestenwald-kiefer", "Küstenwald (Kiefer)"),
    ("buchenwald", "Buchenwald"),
    ("eichen-mischwald", "Eichen-Mischwald"),
    ("kiefernforst", "Kiefernforst"),
    ("auwald", "Auwald"),
    ("moor", "Moor"),
    ("heide", "Heide"),
    ("streuobst-hecke", "Streuobstwiese & Hecke"),
    ("teich-tuempel", "Teich & Tümpel"),
    ("fliessgewaesser", "Fließgewässer"),
    ("see-ufer", "See & Ufer"),
    ("salzwiese-watt", "Salzwiese & Watt"),
    ("duene-strand", "Düne & Strand"),
    ("trockenrasen", "Trockenrasen"),
    ("nadelforst", "Nadelforst"),
    ("hof-nutztier", "Hof & Nutztiere"),
    ("mediterraner-wald", "Mediterraner Wald"),
    ("alpen-wald", "Alpenwald"),
]


def req(method, path, key, payload=None, prefer="return=minimal"):
    url = os.environ["SUPABASE_URL"].rstrip("/") + "/rest/v1/" + path
    headers = {"apikey": key, "Authorization": "Bearer " + key,
               "Content-Type": "application/json", "Prefer": prefer}
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
    key = os.environ.get("SUPABASE_SERVICE_KEY")
    if not key or not os.environ.get("SUPABASE_URL"):
        sys.exit("SUPABASE_URL und SUPABASE_SERVICE_KEY muessen gesetzt sein.")
    with open(POOLS_PATH, encoding="utf-8") as f:
        pools = json.load(f)["pools"]

    species_ids = {r["id"] for r in req("GET", "species?select=id", key) or []}
    have = {r["id"] for r in req("GET", "lebensraeume?select=id", key) or []}
    names = dict(LEBENSRAUM_NAMEN)
    order = {k: i for i, (k, _) in enumerate(LEBENSRAUM_NAMEN)}

    neue = [k for k, _ in LEBENSRAUM_NAMEN if force or k not in have]
    if neue:
        req("POST", "lebensraeume?on_conflict=id", key,
            [{"id": k, "name_de": names[k], "sortierung": order[k]} for k in neue],
            prefer="resolution=merge-duplicates,return=minimal")

    fehlend = set()
    for p in pools:
        lr = p["lebensraum"]
        if lr not in neue:
            continue
        req("DELETE", "pool_naturraeume?lebensraum=eq." + lr, key)
        req("DELETE", "pool_arten?lebensraum=eq." + lr, key)
        nr = [{"lebensraum": lr, "naturraum": n} for n in p.get("naturraeume", [])]
        if nr:
            req("POST", "pool_naturraeume", key, nr)
        arten = []
        for a in p.get("arten", []):
            if a["id"] not in species_ids:
                fehlend.add(a["id"])
                continue
            arten.append({
                "lebensraum": lr, "species_id": a["id"],
                "rolle": a.get("rolle", ""), "sichtbarkeit": a.get("sichtbarkeit", ""),
                "saison": a.get("saison", ""), "quelle": a.get("quelle", ""),
            })
        if arten:
            req("POST", "pool_arten", key, arten)
        print("%s: %d Naturraeume, %d Arten" % (lr, len(nr), len(arten)))
    if fehlend:
        print("Uebersprungen (nicht in species): %s" % ", ".join(sorted(fehlend)))
    if not neue:
        print("Nichts zu tun (alle Lebensraeume vorhanden). --force zum Ersetzen.")


if __name__ == "__main__":
    main()
