"""trail_candidates aus research/Länder/**/_kandidaten.md.

Blatt = ### <slug> — <STATUS>   (STATUS: HAVE | OPEN | OPEN-GO | MAYBE | NOGO)
Land/Bundesland/Kreis stehen im Ordnerpfad: Länder/<Land>/<Unterland>/<Blatt>/_kandidaten.md
HAVE = Seed existiert, Pfad ist live -> status 'freigegeben'. NOGO oder Abschnitt '## NOGO' -> 'verworfen'.
"""
from __future__ import annotations

import os
import re
import unicodedata
from typing import Any, Dict, List

LAND_CODE = {"Deutschland": "DE", "Dänemark": "DK", "Spanien": "ES", "Österreich": "AT", "Schweiz": "CH",
             "Frankreich": "FR", "Italien": "IT"}
_H3 = re.compile(r"^###\s+([a-z0-9]+(?:-[a-z0-9]+)*)\s*(?:[—–-]+\s*(.*))?$")
_ROW = re.compile(r"^\|\s*(.+?)\s*\|\s*(.+?)\s*\|\s*$")


def _name(slug: str) -> str:
    return " ".join(w.capitalize() for w in slug.split("-"))


def _strip_md(s: str) -> str:
    s = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", s)
    return re.sub(r"[*`]", "", s).strip()


def parse_kandidaten(path: str, root: str) -> List[Dict[str, Any]]:
    rel = unicodedata.normalize("NFC", os.path.relpath(path, root).replace(os.sep, "/"))
    teile = rel.split("/")
    land = LAND_CODE.get(teile[0]) if len(teile) > 1 else None
    bundesland = teile[1] if len(teile) > 3 else None
    kreis = teile[2] if len(teile) > 3 else None
    out: List[Dict[str, Any]] = []
    cur: Dict[str, Any] = {}
    sektion = ""
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.rstrip("\n")
            if line.startswith("## "):
                sektion = line[3:].strip().upper()
                cur = {}
                continue
            m = _H3.match(line)
            if m:
                status_wort = (m.group(2) or "").strip().upper()
                if sektion.startswith("NOGO") or status_wort.startswith("NOGO"):
                    status = "verworfen"
                elif status_wort.startswith("HAVE"):
                    status = "freigegeben"
                else:
                    status = "offen"
                cur = {"id": m.group(1), "name": _name(m.group(1)), "land": land, "bundesland": bundesland,
                       "kreis": kreis, "ort": None, "quelle": "research/Länder/" + rel, "status": status,
                       "verworfen_grund": None, "notiz": status_wort or None}
                out.append(cur)
                continue
            if line.startswith("### "):
                cur = {}
                continue
            if cur:
                r = _ROW.match(line)
                if not r:
                    continue
                key, val = _strip_md(r.group(1)), _strip_md(r.group(2))
                if key == "Ort":
                    cur["ort"] = val
                elif key == "Status" and cur["status"] == "verworfen":
                    cur["verworfen_grund"] = val[:300]
    return out


def lade_alle(research_root: str) -> List[Dict[str, Any]]:
    seen: Dict[str, Dict[str, Any]] = {}
    for dp, _dn, fn in os.walk(research_root):
        for f in sorted(fn):
            if f == "_kandidaten.md":
                for c in parse_kandidaten(os.path.join(dp, f), research_root):
                    seen.setdefault(c["id"], c)
    return sorted(seen.values(), key=lambda c: c["id"])
