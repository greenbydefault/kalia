#!/usr/bin/env python3
"""Exportiert den Katalog aus Supabase zurueck nach assets/seed/*.json.

DB ist Master (docs/adr/0002-db-master-admin-write.md). Der gebuendelte Seed
ist nur noch Offline-Fallback der App und Erstimport. Dieses Script haelt ihn
aktuell: vor jedem App-Release laufen lassen.

Nutzung:
  export SUPABASE_URL="https://<projekt>.supabase.co"
  export SUPABASE_PUBLISHABLE_KEY="<publishable key>"   # reicht, Katalog ist public read
  python3 tools/export_catalog.py [--dry-run]

Schreibt:
  assets/seed/<trail>.json      bestehende Dateien: nur DB-Felder werden ersetzt,
                                Repo-only-Felder (bilderAsset, ...) bleiben.
                                Neue Trails: neue Datei + Hinweis fuer
                                SeedTrailRepository._seedPaths / pubspec.
  assets/seed/species.json      inkl. merkmale[] und beziehungen[]
  assets/seed/merkmale.json
  assets/seed/pois.json
  assets/seed/nearby_zeiten.json

Geometrie (route/area/Koordinaten) kommt aus der DB, das CMS aendert sie nicht.
Nur Stdlib.
"""
import glob
import json
import os
import re
import sys
import urllib.parse
import urllib.request

SEED_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "seed")
NON_TRAIL = {"species", "merkmale", "pois", "nearby_zeiten", "art_pools", "orte_de"}


def get(path):
    key = os.environ.get("SUPABASE_SERVICE_KEY") or os.environ.get("SUPABASE_PUBLISHABLE_KEY")
    if not key or not os.environ.get("SUPABASE_URL"):
        sys.exit("SUPABASE_URL und SUPABASE_PUBLISHABLE_KEY (oder SERVICE_KEY) setzen.")
    base = os.environ["SUPABASE_URL"].rstrip("/") + "/rest/v1/"
    out = []
    offset = 0
    while True:
        sep = "&" if "?" in path else "?"
        url = "%s%s%slimit=1000&offset=%d" % (base, path, sep, offset)
        req = urllib.request.Request(url, headers={"apikey": key, "Authorization": "Bearer " + key})
        with urllib.request.urlopen(req) as resp:
            rows = json.loads(resp.read())
        out.extend(rows)
        if len(rows) < 1000:
            return out
        offset += 1000


def detect_indent(path, default):
    try:
        with open(path, encoding="utf-8") as f:
            head = f.read(4000)
    except OSError:
        return default
    m = re.search(r"\n( +)\S", head)
    return len(m.group(1)) if m else default


def write_json(path, data, default_indent, dry):
    indent = detect_indent(path, default_indent)
    text = json.dumps(data, ensure_ascii=False, indent=indent) + "\n"
    if dry:
        print("  (dry) %s" % os.path.relpath(path))
        return
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)
    print("  %s" % os.path.relpath(path))


def drop_none(d):
    return {k: v for k, v in d.items() if v is not None}


def seed_files_by_trail_id():
    out = {}
    for path in glob.glob(os.path.join(SEED_DIR, "*.json")):
        if os.path.splitext(os.path.basename(path))[0] in NON_TRAIL:
            continue
        try:
            with open(path, encoding="utf-8") as f:
                data = json.load(f)
        except ValueError:
            continue
        if isinstance(data, dict) and "stationen" in data and "id" in data:
            out[data["id"]] = (path, data)
    return out


def export_trails(dry):
    cols = (
        "id,name,typ,form,kurzbeschreibung,beschreibung,laenge_km,dauer_min,rundkurs,"
        "markierung,betreiber,region,website,eintritt,eintritt_preise,oeffnungszeiten,"
        "besuchshinweise,anreise,start_name,arten,lebensraeume,naturraum,tags,route,area"
    )
    trails = get("trails?select=%s&order=id" % cols)
    stations = get("stations?select=trail_id,osm_id,lat,lon,km,reihenfolge,titel,thema,"
                   "kurztext,erlebnisse,barrierefrei,steckbrief&order=trail_id,reihenfolge")
    amenities = get("amenities?select=trail_id,osm_id,lat,lon,kategorie,name&order=id")
    ts = get("trail_species?select=trail_id,nachweis,species(name_de)&nachweis=eq.typisch")
    st_by, am_by, nw_by = {}, {}, {}
    for s in stations:
        st_by.setdefault(s["trail_id"], []).append(s)
    for a in amenities:
        am_by.setdefault(a["trail_id"], []).append(a)
    for r in ts:
        nw_by.setdefault(r["trail_id"], {})[r["species"]["name_de"]] = "typisch"

    existing = seed_files_by_trail_id()
    new_files = []
    print("Trails:")
    for t in trails:
        tid = t["id"]
        path, data = existing.get(tid, (os.path.join(SEED_DIR, tid + ".json"), {}))
        if tid not in existing:
            new_files.append(tid)
        form = t.get("form")
        fields = {
            "id": tid,
            "name": t["name"],
            "typ": t["typ"],
            "kurzbeschreibung": t["kurzbeschreibung"],
            "beschreibung": t["beschreibung"],
            "laengeKm": t["laenge_km"],
            "dauerMin": t["dauer_min"],
            "rundkurs": t["rundkurs"],
            "markierung": t["markierung"],
            "betreiber": t["betreiber"],
            "region": t["region"],
            "anreise": t["anreise"],
            "startName": t["start_name"],
            "arten": t["arten"] or [],
            "tags": t["tags"] or [],
            "lebensraeume": t["lebensraeume"] or [],
            "naturraum": t["naturraum"] or "",
        }
        optional = {
            "form": form if form and form != "linie" else None,
            "website": t.get("website"),
            "eintritt": True if t.get("eintritt") else None,
            "eintrittPreise": t.get("eintritt_preise"),
            "oeffnungszeiten": t.get("oeffnungszeiten"),
            "besuchshinweise": t.get("besuchshinweise"),
        }
        data.update(fields)
        for k, v in optional.items():
            if v in (None, ""):
                data.pop(k, None)
            else:
                data[k] = v
        if t.get("route"):
            data["route"] = t["route"]
        else:
            data.pop("route", None)
        if t.get("area"):
            data["area"] = t["area"]
        else:
            data.pop("area", None)
        data["stationen"] = [
            drop_none({
                "osmId": s["osm_id"], "lat": s["lat"], "lon": s["lon"], "km": s["km"],
                "reihenfolge": s["reihenfolge"], "titel": s["titel"], "thema": s["thema"],
                "kurztext": s["kurztext"], "erlebnisse": s["erlebnisse"] or [],
                "barrierefrei": s["barrierefrei"], "steckbrief": s.get("steckbrief"),
            })
            for s in st_by.get(tid, [])
        ]
        data["amenities"] = [
            drop_none({
                "osmId": a["osm_id"], "lat": a["lat"], "lon": a["lon"],
                "kategorie": a["kategorie"], "name": a.get("name"),
            })
            for a in am_by.get(tid, [])
        ]
        nachweis = nw_by.get(tid)
        if nachweis:
            full = {n: "belegt" for n in data["arten"]}
            full.update(nachweis)
            data["artenNachweis"] = full
        else:
            data.pop("artenNachweis", None)
        write_json(path, data, 1, dry)
    if new_files:
        print("\nNeue Trails ohne Seed-Datei, jetzt angelegt:")
        for tid in new_files:
            print("  - %s: in SeedTrailRepository._seedPaths eintragen" % tid)


def export_species(dry):
    path = os.path.join(SEED_DIR, "species.json")
    rows = get("species?select=*&order=id")
    sm = get("species_merkmale?select=species_id,merkmal_id")
    sb = get("species_beziehungen?select=from_id,typ,to_species_id,name_de,name_lat,kurztext,sortierung&order=from_id,sortierung")
    merk_by, bez_by = {}, {}
    for r in sm:
        merk_by.setdefault(r["species_id"], []).append(r["merkmal_id"])
    for r in sb:
        b = {"typ": r["typ"]}
        if r.get("to_species_id"):
            b["toSpeciesId"] = r["to_species_id"]
        for k, col in (("nameDe", "name_de"), ("nameLat", "name_lat"), ("kurztext", "kurztext")):
            if r.get(col):
                b[k] = r[col]
        bez_by.setdefault(r["from_id"], []).append(b)

    old = {}
    order = []
    if os.path.exists(path):
        with open(path, encoding="utf-8") as f:
            for s in json.load(f):
                old[s["id"]] = s
                order.append(s["id"])
    by_id = {r["id"]: r for r in rows}
    ids = [i for i in order if i in by_id] + sorted(i for i in by_id if i not in old)

    out = []
    for sid in ids:
        r = by_id[sid]
        s = dict(old.get(sid, {}))
        s.update({
            "id": sid,
            "nameDe": r["name_de"],
            "nameLat": r["name_lat"] or "",
            "kategorie": r["kategorie"],
            "kurztext": r["kurztext"] or "",
            "aliases": r["aliases"] or [],
            "imagePath": r.get("image_path"),
            "imageCredit": r.get("image_credit") or "",
            "content": r.get("content") or {},
        })
        if r.get("audio_path"):
            s["audioPath"] = r["audio_path"]
        else:
            s.pop("audioPath", None)
        if r.get("icon_key"):
            s["iconKey"] = r["icon_key"]
        else:
            s.pop("iconKey", None)
        if r["kategorie"] != "geraete" or r.get("gruppe"):
            s["gruppe"] = r.get("gruppe") or ""
            s["seltenheit"] = r.get("seltenheit") or ""
            s["gefahr"] = r.get("gefahr") or 0
            s["nahrung"] = r.get("nahrung") or []
            s["taxonomie"] = {
                "reich": r.get("tax_reich") or "", "stamm": r.get("tax_stamm") or "",
                "klasse": r.get("tax_klasse") or "", "ordnung": r.get("tax_ordnung") or "",
                "familie": r.get("tax_familie") or "",
            }
            s["masse"] = r.get("masse") or []
            s["merkmale"] = merk_by.get(sid, [])
            s["beziehungen"] = bez_by.get(sid, [])
        out.append(s)
    print("Arten: %d" % len(out))
    write_json(path, out, 4, dry)


def export_merkmale(dry):
    rows = get("merkmale?select=*&order=sortierung,id")
    out = [{
        "id": r["id"], "nameDe": r["name_de"], "beschreibung": r["beschreibung"],
        "iconKey": r["icon_key"], "gruppe": r["gruppe"], "sortierung": r["sortierung"],
    } for r in rows]
    print("Merkmale: %d" % len(out))
    write_json(os.path.join(SEED_DIR, "merkmale.json"), out, 2, dry)


def export_pois(dry):
    rows = get("pois?select=*&order=id")
    out = []
    for r in rows:
        o = {"id": r["id"], "name": r["name"], "kategorie": r["kategorie"],
             "kurztext": r["kurztext"], "lat": r["lat"], "lon": r["lon"]}
        for k, col in (("website", "website"), ("oeffnungszeiten", "oeffnungszeiten"),
                       ("opening_hours", "opening_hours"), ("telefon", "telefon")):
            if r.get(col):
                o[k] = r[col]
        out.append(o)
    print("Orte: %d" % len(out))
    write_json(os.path.join(SEED_DIR, "pois.json"), out, 2, dry)
    zeiten = {}
    for t in get("trails?select=id&order=id"):
        zeiten[t["id"]] = []
    for r in get("trail_pois?select=trail_id,poi_id,sek&order=trail_id,sek"):
        zeiten.setdefault(r["trail_id"], []).append({"poi": r["poi_id"], "sek": r["sek"]})
    write_json(os.path.join(SEED_DIR, "nearby_zeiten.json"), zeiten, 2, dry)


def main():
    dry = "--dry-run" in sys.argv[1:]
    export_trails(dry)
    export_species(dry)
    export_merkmale(dry)
    export_pois(dry)
    print("Fertig." + (" (dry-run)" if dry else " Diff pruefen, dann committen."))


if __name__ == "__main__":
    main()
