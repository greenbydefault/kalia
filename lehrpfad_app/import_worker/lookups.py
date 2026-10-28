"""DB-gestuetzte Abfragen fuer Pipeline und Worker (alles ueber db.DB, service_role)."""
from __future__ import annotations

from typing import Any, Dict, List, Optional

from . import config
from .db import DB, eq, in_


class DBLookups:
    def __init__(self, db: DB):
        self.db = db

    def species_rows(self) -> List[Dict[str, Any]]:
        return self.db.select("species", "id,name_de,name_lat,aliases", _order="id", _limit=20000)

    def duplicates(self, slug: str, name: str, lat: float, lon: float) -> List[Dict[str, Any]]:
        return self.db.rpc("find_trail_duplicates", {
            "p_slug": slug, "p_name": name, "p_lat": lat, "p_lon": lon,
            "p_nah_m": config.DUPLIKAT_NAH_M, "p_moeglich_m": config.DUPLIKAT_MOEGLICH_M,
            "p_trigram": config.DUPLIKAT_TRIGRAM}) or []

    def trail(self, slug: str) -> Optional[Dict[str, Any]]:
        rows = self.db.select("trails", "*", id=eq(slug))
        return rows[0] if rows else None

    def candidate_exists(self, slug: str) -> bool:
        return bool(self.db.select("trail_candidates", "id", id=eq(slug)))

    def state(self, slug: str) -> Optional[Dict[str, Any]]:
        """DB-Stand eines Pfads in der Form, die die Regeln erwarten."""
        t = self.trail(slug)
        if not t:
            return None
        stationen = self.db.select("stations", "*", trail_id=eq(slug), _order="reihenfolge")
        ts = self.db.select("trail_species", "species_id,nachweis,sortierung", trail_id=eq(slug), _order="sortierung")
        namen: Dict[str, Dict[str, Any]] = {}
        if ts:
            for r in self.db.select("species", "id,name_de,name_lat", id=in_([x["species_id"] for x in ts])):
                namen[r["id"]] = r
        arten = [{"species_id": x["species_id"], "nachweis": x["nachweis"], "sortierung": x["sortierung"],
                  "name_de": (namen.get(x["species_id"]) or {}).get("name_de"),
                  "name_lat": (namen.get(x["species_id"]) or {}).get("name_lat")} for x in ts]
        offen = [{"name_de": r["name_de"], "name_lat_guess": r.get("name_lat_guess"),
                  "grund": "unbekannt"} for r in
                 self.db.select("species_suggestions", "*", trail_id=eq(slug), status=eq("offen"))]
        bilder = self.db.select("images", "*", trail_id=eq(slug), source=eq("official"), _order="sort")
        return {"trail": t, "stationen": stationen, "arten": arten, "arten_offen": offen, "bilder": bilder}


class OfflineLookups:
    """Fuer `check` ohne Datenbank: Arten aus assets/seed/species.json, keine Duplikate, kein vorhandener Pfad."""

    def __init__(self, species_json: Optional[str] = None):
        import json
        import os
        path = species_json or os.path.join(os.path.dirname(__file__), "..", "assets", "seed", "species.json")
        with open(path, encoding="utf-8") as f:
            self._rows = [{"id": s["id"], "name_de": s["nameDe"], "name_lat": s.get("nameLat"),
                           "aliases": s.get("aliases", [])} for s in json.load(f)]

    def species_rows(self) -> List[Dict[str, Any]]:
        return self._rows

    def duplicates(self, slug, name, lat, lon) -> List[Dict[str, Any]]:
        return []

    def trail(self, slug: str) -> Optional[Dict[str, Any]]:
        return None

    def candidate_exists(self, slug: str) -> bool:
        return True
