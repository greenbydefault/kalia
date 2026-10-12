#!/usr/bin/env python3
"""Laedt einen Trail-Seed in die Supabase-Tabellen (trails, stations, amenities,
species, trail_species).

Checklist neuer Trail:
  1. arten[] in tools/trails/<id>.json fuellen
  2. fehlende Arten in assets/seed/species.json anlegen
  3. python3 tools/validate_seeds.py
  4. dieses Script ausfuehren
  5. python3 tools/seed_pois.py  # wenn assets/seed/pois.json geaendert

Nutzung:
  export SUPABASE_URL="https://<projekt>.supabase.co"
  export SUPABASE_SERVICE_KEY="<service_role key>"   # niemals in die App!
  python3 tools/seed_supabase.py [--force] [assets/seed/<datei>.json]

Ohne Argument wird assets/seed/trail.json geladen.

DB ist Master (docs/adr/0002-db-master-admin-write.md): Das Admin-CMS
bearbeitet Katalog-Datensaetze direkt. Default = nur NEUE Datensaetze anlegen
(Trail-ID, Art-ID, Merkmal-ID die es noch nicht gibt). Bestehende werden nicht
ueberschrieben. --force stellt das alte Verhalten her (alles ueberschreiben),
z. B. nach geaenderter OSM-Geometrie. Danach ggf. export_catalog.py.

Idempotent: Der Trail wird ge-upsertet. Stationen werden ebenfalls
ge-upsertet (Konflikt auf trail_id+reihenfolge), damit ihre IDs stabil
bleiben – an Stationen haengen User-Bilder (images.station_id), die bei
einem Loeschen+Neuanlegen sonst kaskadiert wuerden. Nicht mehr im Seed
vorhandene Stationen werden entfernt. Amenities (ohne User-Content)
werden weiterhin geloescht und neu eingefuegt. Species-Katalog wird
komplett ge-upsertet; trail_species fuer den Trail ersetzt.
Nur Stdlib, keine Dependencies.
"""
import json
import os
import sys
import urllib.error
import urllib.request

from resolve_arten import (
    load_catalog,
    merkmale_rows,
    species_beziehungen_rows,
    species_merkmale_rows,
    species_rows,
)

SEED_PATH = os.path.join(os.path.dirname(__file__), "..", "assets", "seed", "trail.json")


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


def existing_ids(table, key):
    rows = req("GET", "%s?select=id" % table, key) or []
    return {r["id"] for r in rows}


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    force = "--force" in sys.argv[1:]
    key = os.environ.get("SUPABASE_SERVICE_KEY")
    if not key or not os.environ.get("SUPABASE_URL"):
        sys.exit("SUPABASE_URL und SUPABASE_SERVICE_KEY muessen gesetzt sein.")

    seed_path = args[0] if args else SEED_PATH
    with open(seed_path, encoding="utf-8") as f:
        t = json.load(f)

    trail_id = t["id"]
    route = t.get("route") or []
    area = t.get("area") or []
    form = t.get("form") or "linie"
    if route:
        start_lat, start_lon = route[0][0], route[0][1]
    elif area:
        start_lat = sum(p[0] for p in area) / len(area)
        start_lon = sum(p[1] for p in area) / len(area)
    else:
        sys.exit("Trail hat weder route noch area")

    trail_row = {
        "id": trail_id,
        "name": t["name"],
        "typ": t["typ"],
        "form": form,
        "kurzbeschreibung": t["kurzbeschreibung"],
        "beschreibung": t["beschreibung"],
        "laenge_km": t["laengeKm"],
        "dauer_min": t["dauerMin"],
        "rundkurs": t.get("rundkurs", False),
        "markierung": t["markierung"],
        "betreiber": t["betreiber"],
        "region": t["region"],
        "website": t.get("website"),
        "eintritt": bool(t.get("eintritt")),
        "eintritt_preise": t.get("eintrittPreise"),
        "oeffnungszeiten": t.get("oeffnungszeiten"),
        "besuchshinweise": t.get("besuchshinweise"),
        "anreise": t["anreise"],
        "start_name": t["startName"],
        "arten": t["arten"],
        "lebensraeume": t.get("lebensraeume") or [],
        "naturraum": t.get("naturraum") or "",
        "tags": t.get("tags", []),
        "route": route,
        "area": area,
        "start_lat": start_lat,
        "start_lon": start_lon,
    }
    trail_is_new = not req("GET", "trails?id=eq.%s&select=id" % trail_id, key)
    write_trail = force or trail_is_new
    if not write_trail:
        print("Trail '%s' existiert (DB ist Master) - Trail, Stationen, Amenities "
              "und Arten-Zuordnung bleiben. --force zum Ueberschreiben." % trail_id)

    if write_trail:
        req("POST", "trails", key, trail_row, prefer="resolution=merge-duplicates,return=minimal")
        req("DELETE", "amenities?trail_id=eq." + trail_id, key)

    stations = [
        {
            "trail_id": trail_id,
            "osm_id": s["osmId"],
            "lat": s["lat"],
            "lon": s["lon"],
            "km": s["km"],
            "reihenfolge": s["reihenfolge"],
            "titel": s["titel"],
            "thema": s["thema"],
            "kurztext": s["kurztext"],
            "erlebnisse": s["erlebnisse"],
            "barrierefrei": s.get("barrierefrei", False),
            "steckbrief": s.get("steckbrief"),
        }
        for s in t["stationen"]
    ]
    amenities = [
        {
            "trail_id": trail_id,
            "osm_id": a["osmId"],
            "lat": a["lat"],
            "lon": a["lon"],
            "kategorie": a["kategorie"],
            "name": a.get("name"),
        }
        for a in t["amenities"]
    ]

    if write_trail:
        # Stationen upserten statt loeschen: IDs bleiben stabil, damit
        # images.station_id-Referenzen (User-Uploads) erhalten bleiben.
        existing = req("GET", "stations?trail_id=eq.%s&select=id,reihenfolge" % trail_id, key) or []
        keep = {s["reihenfolge"] for s in stations}
        for row in existing:
            if row["reihenfolge"] not in keep:
                req("DELETE", "stations?id=eq.%d" % row["id"], key)
        req("POST", "stations?on_conflict=trail_id,reihenfolge", key, stations,
            prefer="resolution=merge-duplicates,return=minimal")

        req("POST", "amenities", key, amenities)

    by_id, lookup = load_catalog()

    # Katalog: Default nur neue IDs, --force ueberschreibt alles.
    sp_rows = species_rows(by_id)
    mk_rows = merkmale_rows()
    if force:
        new_species = {r["id"] for r in sp_rows}
        req("POST", "species?on_conflict=id", key, sp_rows,
            prefer="resolution=merge-duplicates,return=minimal")
        req("POST", "merkmale?on_conflict=id", key, mk_rows,
            prefer="resolution=merge-duplicates,return=minimal")
        req("DELETE", "species_merkmale?species_id=neq.''", key)
        req("DELETE", "species_beziehungen?id=neq.-1", key)
    else:
        have_species = existing_ids("species", key)
        have_merkmale = existing_ids("merkmale", key)
        new_species = {r["id"] for r in sp_rows} - have_species
        new_sp_rows = [r for r in sp_rows if r["id"] in new_species]
        new_mk_rows = [r for r in mk_rows if r["id"] not in have_merkmale]
        if new_mk_rows:
            req("POST", "merkmale?on_conflict=id", key, new_mk_rows,
                prefer="resolution=ignore-duplicates,return=minimal")
        if new_sp_rows:
            req("POST", "species?on_conflict=id", key, new_sp_rows,
                prefer="resolution=ignore-duplicates,return=minimal")
        if new_species:
            print("Neue Arten: %s" % ", ".join(sorted(new_species)))

    sm = [r for r in species_merkmale_rows(by_id) if r["species_id"] in new_species]
    if sm:
        req("POST", "species_merkmale", key, sm)
    sb = [r for r in species_beziehungen_rows(by_id) if r["from_id"] in new_species]
    if sb:
        req("POST", "species_beziehungen", key, sb)

    slugs = []
    if write_trail:
        nachweis = t.get("artenNachweis") or {}
        zeilen = []
        gesehen = set()
        for name in t["arten"]:
            sid = lookup.get(str(name).casefold())
            if sid is None or sid in gesehen:
                continue
            gesehen.add(sid)
            stufe = nachweis.get(name) or nachweis.get(sid) or "belegt"
            if stufe not in ("belegt", "typisch"):
                stufe = "belegt"
            zeilen.append({
                "trail_id": trail_id,
                "species_id": sid,
                "nachweis": stufe,
                "sortierung": len(zeilen) + 1,
            })
        req("DELETE", "trail_species?trail_id=eq." + trail_id, key)
        if zeilen:
            req("POST", "trail_species", key, zeilen)
        slugs = [z["species_id"] for z in zeilen]

    print("OK: Trail '%s' (%s): %d Stationen, %d Amenities, %d Arten."
          % (trail_id, "geschrieben" if write_trail else "unveraendert",
             len(stations) if write_trail else 0,
             len(amenities) if write_trail else 0, len(slugs)))


if __name__ == "__main__":
    main()
