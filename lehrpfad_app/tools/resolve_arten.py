#!/usr/bin/env python3
"""Loest Trail-Artennamen auf Species-Slugs auf.

Checklist neuer Trail:
  1. arten[] in tools/trails/<id>.json fuellen
  2. fehlende Arten in assets/seed/species.json anlegen (id, nameDe, …)
  3. python3 tools/validate_seeds.py  (muss gruen sein)

Nutzung als Modul:
  from resolve_arten import load_catalog, resolve_names, species_rows
"""
import json
import os

SEED_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "seed")
SPECIES_PATH = os.path.join(SEED_DIR, "species.json")


def load_catalog(path=None):
    """Liest species.json; liefert (by_id, lookup name→id)."""
    with open(path or SPECIES_PATH, encoding="utf-8") as f:
        rows = json.load(f)
    by_id = {}
    lookup = {}
    for s in rows:
        sid = s["id"]
        by_id[sid] = s
        for name in [s["nameDe"], *s.get("aliases", [])]:
            key = name.casefold()
            if key in lookup and lookup[key] != sid:
                raise ValueError(
                    f"Doppelter Artenname '{name}' → {lookup[key]} und {sid}"
                )
            lookup[key] = sid
    return by_id, lookup


def resolve_names(names, lookup=None):
    """Mappt Anzeigenamen auf Slugs. Wirft ValueError bei unbekannten Namen.

    Leere Liste ist ein Fehler (Trail ohne Arten).
    """
    if lookup is None:
        _, lookup = load_catalog()
    if not names:
        raise ValueError("arten[] ist leer – bitte Arten eintragen")
    slugs = []
    unknown = []
    seen = set()
    for name in names:
        sid = lookup.get(name.casefold())
        if sid is None:
            unknown.append(name)
            continue
        if sid not in seen:
            seen.add(sid)
            slugs.append(sid)
    if unknown:
        raise ValueError(
            "Unbekannte Arten (nicht in species.json): " + ", ".join(unknown)
        )
    return slugs


def species_rows(by_id=None):
    """DB-Rows (snake_case) fuer Upsert aller Species."""
    if by_id is None:
        by_id, _ = load_catalog()
    rows = []
    for s in by_id.values():
        rows.append({
            "id": s["id"],
            "name_de": s["nameDe"],
            "name_lat": s.get("nameLat", ""),
            "kategorie": s["kategorie"],
            "kurztext": s.get("kurztext", ""),
            "content": s.get("content") or {},
            "aliases": s.get("aliases", []),
            "image_path": s.get("imagePath"),
            "image_credit": s.get("imageCredit") or "",
            "audio_path": s.get("audioPath"),
            "icon_key": s.get("iconKey") or "",
        })
    return rows


if __name__ == "__main__":
    import sys
    names = sys.argv[1:]
    if not names:
        sys.exit("Nutzung: resolve_arten.py <Name> [<Name> …]")
    print(resolve_names(names))
