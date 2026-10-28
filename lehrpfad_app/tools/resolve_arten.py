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
        tax = s.get("taxonomie") or {}
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
            "gruppe": s.get("gruppe") or "",
            "seltenheit": s.get("seltenheit") or "",
            "gefahr": s.get("gefahr") or 0,
            "nahrung": s.get("nahrung", []),
            "tax_reich": tax.get("reich", ""),
            "tax_stamm": tax.get("stamm", ""),
            "tax_klasse": tax.get("klasse", ""),
            "tax_ordnung": tax.get("ordnung", ""),
            "tax_familie": tax.get("familie", ""),
            "masse": s.get("masse", []),
        })
    return rows


MERKMALE_PATH = os.path.join(SEED_DIR, "merkmale.json")


def load_merkmale(path=None):
    """Liest merkmale.json; liefert by_id."""
    with open(path or MERKMALE_PATH, encoding="utf-8") as f:
        rows = json.load(f)
    return {m["id"]: m for m in rows}


def merkmale_rows(by_id=None):
    """DB-Rows (snake_case) fuer Upsert des Merkmale-Katalogs."""
    if by_id is None:
        by_id = load_merkmale()
    return [
        {
            "id": m["id"],
            "name_de": m["nameDe"],
            "beschreibung": m.get("beschreibung", ""),
            "icon_key": m.get("iconKey", ""),
            "gruppe": m.get("gruppe", ""),
            "sortierung": m.get("sortierung", 0),
        }
        for m in by_id.values()
    ]


def species_merkmale_rows(by_id=None):
    """Junction-Rows aus species.json (`merkmale`-IDs pro Art)."""
    if by_id is None:
        by_id, _ = load_catalog()
    rows = []
    for s in by_id.values():
        for mid in s.get("merkmale", []):
            rows.append({"species_id": s["id"], "merkmal_id": mid})
    return rows


def species_beziehungen_rows(by_id=None):
    """Beziehungs-Rows aus species.json (`beziehungen` pro Art)."""
    if by_id is None:
        by_id, _ = load_catalog()
    rows = []
    for s in by_id.values():
        for i, b in enumerate(s.get("beziehungen", [])):
            rows.append({
                "from_id": s["id"],
                "typ": b["typ"],
                "to_species_id": b.get("toSpeciesId") or b.get("speciesId") or None,
                "name_de": b.get("nameDe", ""),
                "name_lat": b.get("nameLat", ""),
                "kurztext": b.get("kurztext", ""),
                "sortierung": i,
            })
    return rows


if __name__ == "__main__":
    import sys
    names = sys.argv[1:]
    if not names:
        sys.exit("Nutzung: resolve_arten.py <Name> [<Name> …]")
    print(resolve_names(names))
