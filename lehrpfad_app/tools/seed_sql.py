#!/usr/bin/env python3
"""Erzeugt idempotentes Import-SQL aus einem Trail-Seed (Alternative zu
seed_supabase.py, wenn statt REST/API-Key der SQL-Zugang genutzt wird).

Spiegelt die Logik von seed_supabase.py: Trail upserten, Stationen upserten
(Konflikt auf trail_id+reihenfolge, damit images.station_id-Referenzen
stabil bleiben), nicht mehr vorhandene Stationen loeschen, Amenities
loeschen + neu einfuegen, Species-Katalog upserten, trail_species ersetzen.
Die geography-Spalten (start_pos/pos) werden wie beim REST-Import durch
Trigger aus lat/lon gefuellt.

Checklist neuer Trail: arten[] + species.json, dann validate_seeds.py.

Nutzung:
  python3 tools/seed_sql.py assets/seed/raddusch.json > /tmp/raddusch.sql
  python3 tools/seed_sql.py --no-catalog assets/seed/raddusch.json
      # ohne Species-Katalog (nur Trail/Stationen/Amenities/trail_species)
"""
import json
import sys

from resolve_arten import load_catalog, resolve_names, species_rows


def q(val):
    """SQL-String-Literal oder NULL."""
    if val is None:
        return "NULL"
    return "'" + str(val).replace("'", "''") + "'"


def str_array(items):
    return "ARRAY[" + ", ".join(q(i) for i in items) + "]::text[]"


def jsonb(val):
    return q(json.dumps(val, ensure_ascii=False, separators=(",", ":"))) + "::jsonb"


def start_point(t):
    route = t.get("route") or []
    if route:
        return route[0]
    area = t.get("area") or []
    if area:
        return [
            sum(p[0] for p in area) / len(area),
            sum(p[1] for p in area) / len(area),
        ]
    sys.exit("Trail hat weder route noch area")


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    no_catalog = "--no-catalog" in sys.argv
    with open(args[0], encoding="utf-8") as f:
        t = json.load(f)

    trail_id = t["id"]
    route = t.get("route") or []
    area = t.get("area") or []
    form = t.get("form") or "linie"
    start = start_point(t)

    print("BEGIN;")
    print(
        "INSERT INTO trails (id, name, typ, form, kurzbeschreibung, beschreibung,"
        " laenge_km, dauer_min, rundkurs, markierung, betreiber, region,"
        " website, eintritt, eintritt_preise, oeffnungszeiten, besuchshinweise,"
        " anreise, start_name, arten, tags, route, area,"
        " start_lat, start_lon)"
        f"\nVALUES ({q(trail_id)}, {q(t['name'])}, {q(t['typ'])}, {q(form)},"
        f" {q(t['kurzbeschreibung'])}, {q(t['beschreibung'])},"
        f" {t['laengeKm']}, {t['dauerMin']}, {str(t['rundkurs']).lower()},"
        f" {q(t['markierung'])}, {q(t['betreiber'])}, {q(t['region'])},"
        f" {q(t.get('website'))}, {str(bool(t.get('eintritt'))).lower()},"
        f" {q(t.get('eintrittPreise'))}, {q(t.get('oeffnungszeiten'))},"
        f" {q(t.get('besuchshinweise'))}, {q(t['anreise'])}, {q(t['startName'])},"
        f" {str_array(t['arten'])}, {str_array(t.get('tags', []))},"
        f" {jsonb(route)}, {jsonb(area)}, {start[0]}, {start[1]})"
        "\nON CONFLICT (id) DO UPDATE SET"
        " name = EXCLUDED.name, typ = EXCLUDED.typ, form = EXCLUDED.form,"
        " kurzbeschreibung = EXCLUDED.kurzbeschreibung,"
        " beschreibung = EXCLUDED.beschreibung,"
        " laenge_km = EXCLUDED.laenge_km, dauer_min = EXCLUDED.dauer_min,"
        " rundkurs = EXCLUDED.rundkurs, markierung = EXCLUDED.markierung,"
        " betreiber = EXCLUDED.betreiber, region = EXCLUDED.region,"
        " website = EXCLUDED.website, eintritt = EXCLUDED.eintritt,"
        " eintritt_preise = EXCLUDED.eintritt_preise,"
        " oeffnungszeiten = EXCLUDED.oeffnungszeiten,"
        " besuchshinweise = EXCLUDED.besuchshinweise,"
        " anreise = EXCLUDED.anreise,"
        " start_name = EXCLUDED.start_name, arten = EXCLUDED.arten,"
        " tags = EXCLUDED.tags, route = EXCLUDED.route, area = EXCLUDED.area,"
        " start_lat = EXCLUDED.start_lat, start_lon = EXCLUDED.start_lon;"
    )

    # Stationen upserten (IDs stabil halten), Ueberzaehlige loeschen
    keep = ", ".join(str(s["reihenfolge"]) for s in t["stationen"])
    print(f"DELETE FROM stations WHERE trail_id = {q(trail_id)}"
          f" AND reihenfolge NOT IN ({keep});")
    for s in t["stationen"]:
        steckbrief = q(json.dumps(s["steckbrief"], ensure_ascii=False)) + "::jsonb" \
            if s.get("steckbrief") else "NULL"
        print(
            "INSERT INTO stations (trail_id, osm_id, lat, lon, km,"
            " reihenfolge, titel, thema, kurztext, erlebnisse, barrierefrei,"
            " steckbrief)"
            f"\nVALUES ({q(trail_id)}, {s['osmId']}, {s['lat']}, {s['lon']},"
            f" {s['km']}, {s['reihenfolge']}, {q(s['titel'])}, {q(s['thema'])},"
            f" {q(s['kurztext'])}, {str_array(s['erlebnisse'])},"
            f" {str(s['barrierefrei']).lower()}, {steckbrief})"
            "\nON CONFLICT (trail_id, reihenfolge) DO UPDATE SET"
            " osm_id = EXCLUDED.osm_id, lat = EXCLUDED.lat, lon = EXCLUDED.lon,"
            " km = EXCLUDED.km, titel = EXCLUDED.titel, thema = EXCLUDED.thema,"
            " kurztext = EXCLUDED.kurztext, erlebnisse = EXCLUDED.erlebnisse,"
            " barrierefrei = EXCLUDED.barrierefrei,"
            " steckbrief = EXCLUDED.steckbrief;"
        )

    print(f"DELETE FROM amenities WHERE trail_id = {q(trail_id)};")
    for a in t["amenities"]:
        print(
            "INSERT INTO amenities (trail_id, osm_id, lat, lon, kategorie, name)"
            f"\nVALUES ({q(trail_id)}, {a['osmId']}, {a['lat']}, {a['lon']},"
            f" {q(a['kategorie'])}, {q(a.get('name'))});"
        )

    by_id, lookup = load_catalog()
    if not no_catalog:
        for s in species_rows(by_id):
            print(
                "INSERT INTO species (id, name_de, name_lat, kategorie, kurztext,"
                " content, aliases, image_path, image_credit, audio_path, icon_key)"
                f"\nVALUES ({q(s['id'])}, {q(s['name_de'])}, {q(s['name_lat'])},"
                f" {q(s['kategorie'])}, {q(s['kurztext'])}, {jsonb(s['content'])},"
                f" {str_array(s['aliases'])}, {q(s['image_path'])},"
                f" {q(s['image_credit'])}, {q(s['audio_path'])},"
                f" {q(s.get('icon_key') or '')})"
                "\nON CONFLICT (id) DO UPDATE SET"
                " name_de = EXCLUDED.name_de, name_lat = EXCLUDED.name_lat,"
                " kategorie = EXCLUDED.kategorie, kurztext = EXCLUDED.kurztext,"
                " content = EXCLUDED.content, aliases = EXCLUDED.aliases,"
                " image_path = EXCLUDED.image_path,"
                " image_credit = EXCLUDED.image_credit,"
                " audio_path = EXCLUDED.audio_path,"
                " icon_key = EXCLUDED.icon_key;"
            )
    slugs = resolve_names(t["arten"], lookup)
    print(f"DELETE FROM trail_species WHERE trail_id = {q(trail_id)};")
    for sid in slugs:
        print(
            "INSERT INTO trail_species (trail_id, species_id)"
            f"\nVALUES ({q(trail_id)}, {q(sid)})"
            "\nON CONFLICT DO NOTHING;"
        )
    print("COMMIT;")


if __name__ == "__main__":
    main()
