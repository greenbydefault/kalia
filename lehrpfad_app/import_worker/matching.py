"""Arten-Abgleich: Dossier-Arten -> species-IDs.

Reihenfolge: species_id (falls bekannt) -> wissenschaftlicher Name -> deutscher Name/Alias.
Mehrdeutig oder widerspruechlich = unsicher, nichts gefunden = unbekannt. In beiden Faellen entsteht
ein Kurzprofil-Vorschlag (species_suggestions), nie eine automatische Neuanlage.
"""
from __future__ import annotations

import re
from typing import Any, Dict, Iterable, List, Optional


def _n(s: Optional[str]) -> str:
    return re.sub(r"\s+", " ", (s or "").strip()).casefold()


def _genus_art(s: Optional[str]) -> str:
    """'Grus grus (Linnaeus, 1758)' -> 'grus grus'."""
    parts = _n(re.sub(r"\(.*?\)", "", s or "")).split(" ")
    return " ".join(parts[:2])


class SpeciesIndex:
    def __init__(self, rows: Iterable[Dict[str, Any]]):
        self.by_id: Dict[str, Dict[str, Any]] = {}
        self.by_lat: Dict[str, List[str]] = {}
        self.by_de: Dict[str, List[str]] = {}
        for r in rows:
            sid = r["id"]
            self.by_id[sid] = r
            lat = _genus_art(r.get("name_lat") or r.get("nameLat"))
            if lat:
                self.by_lat.setdefault(lat, []).append(sid)
            de = r.get("name_de") or r.get("nameDe")
            names = [de] + list(r.get("aliases") or [])
            for nm in names:
                k = _n(nm)
                if k and sid not in self.by_de.setdefault(k, []):
                    self.by_de[k].append(sid)

    def lat_of(self, sid: str) -> str:
        r = self.by_id[sid]
        return _genus_art(r.get("name_lat") or r.get("nameLat"))


def match_arten(arten: List[Dict[str, Any]], idx: SpeciesIndex) -> Dict[str, List[Dict[str, Any]]]:
    """-> {"zugeordnet": [...], "unbekannt": [...], "unsicher": [...]}.

    zugeordnet-Eintraege: {species_id, name_de, nachweis, sortierung, quelle, warnung?}.
    """
    out: Dict[str, List[Dict[str, Any]]] = {"zugeordnet": [], "unbekannt": [], "unsicher": []}
    gesehen: set = set()
    for i, a in enumerate(arten, 1):
        name_de, name_lat = a.get("name_de"), a.get("name_lat")
        lat_key = _genus_art(name_lat)
        base = {"name_de": name_de, "name_lat": name_lat, "nachweis": a.get("nachweis") or "typisch",
                "sortierung": a.get("sortierung") or i, "quelle": a.get("quelle")}

        sid: Optional[str] = None
        unsicher_grund: Optional[str] = None

        given = a.get("species_id")
        if given and given in idx.by_id:
            sid = given
        if sid is None and lat_key:
            hits = idx.by_lat.get(lat_key, [])
            if len(hits) == 1:
                sid = hits[0]
            elif len(hits) > 1:
                # Mehrere Eintraege fuer dieselbe Art: der deutsche Name entscheidet, sonst unsicher
                de_hits = [h for h in hits if h in idx.by_de.get(_n(name_de), [])]
                if len(de_hits) == 1:
                    sid = de_hits[0]
                else:
                    unsicher_grund = "mehrdeutig"
        if sid is None and unsicher_grund is None and name_de:
            hits = idx.by_de.get(_n(name_de), [])
            if len(hits) == 1:
                sid = hits[0]
            elif len(hits) > 1:
                unsicher_grund = "mehrdeutig"

        if sid is not None:
            # Widerspruch: Dossier-Latein oder deutscher Name passt nicht zur gefundenen Art
            have = idx.lat_of(sid)
            de_ids = idx.by_de.get(_n(name_de), [])
            if (lat_key and have and have != lat_key) or (de_ids and sid not in de_ids):
                out["unsicher"].append({**base, "species_id": sid, "grund": "widerspruch",
                                        "name_lat_guess": name_lat})
                continue
            if sid in gesehen:
                continue
            gesehen.add(sid)
            out["zugeordnet"].append({**base, "species_id": sid})
        elif unsicher_grund:
            out["unsicher"].append({**base, "species_id": None, "grund": unsicher_grund,
                                    "name_lat_guess": name_lat})
        else:
            out["unbekannt"].append({**base, "species_id": None, "grund": "unbekannt",
                                     "name_lat_guess": name_lat})
    return out
