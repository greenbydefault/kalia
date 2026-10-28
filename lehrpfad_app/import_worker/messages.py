"""Meldungstexte rendern (gleiche Quelle wie das Admin-CMS: messages.json)."""
from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any, Dict

_PATH = Path(__file__).with_name("messages.json")
_DATA: Dict[str, Any] = json.loads(_PATH.read_text(encoding="utf-8"))
CODES: Dict[str, Dict[str, str]] = _DATA["codes"]
FELDER: Dict[str, str] = _DATA["felder"]
HILFE: Dict[str, str] = _DATA["hilfe"]

_PLATZHALTER = re.compile(r"\{(\w+)\}")


class _Leer(dict):
    def __missing__(self, key):
        return ""


def feld_label(feld: str) -> str:
    m = re.match(r"^(\w+)\[(\w+)\]$", feld or "")
    if m:
        basis, nr = m.groups()
        if basis == "stationen":
            return "Station %s" % nr
        if basis == "bilder":
            return "Bild %s" % nr
        return "%s %s" % (FELDER.get(basis, basis), nr)
    m = re.match(r"^abschnitt(\d+)$", feld or "")
    if m:
        return "Abschnitt %s" % m.group(1)
    return FELDER.get(feld, feld or "")


def _bereich(p: Dict[str, Any]) -> str:
    mn, mx = p.get("min") or 0, p.get("max") or 0
    if mn and mx:
        return "%s bis %s" % (mn, mx)
    if mx:
        return "bis %s" % mx
    return "mindestens %s" % mn


def platzhalter(code: str) -> set:
    m = CODES[code]
    return set(_PLATZHALTER.findall(" ".join(m[k] for k in ("was", "warum", "wie"))))


def render(e: Dict[str, Any]) -> Dict[str, str]:
    """Meldung -> {titel, was, warum, wie} mit eingesetzten Parametern."""
    m = CODES[e["code"]]
    p: Dict[str, Any] = dict(e.get("params") or {})
    p.setdefault("wert", e.get("wert"))
    p["feld"] = feld_label(e.get("feld", ""))
    if "was" in p and p["was"] in FELDER:
        p["was"] = FELDER[p["was"]]
    p.setdefault("einheit", "Zeichen")
    p["bereich"] = _bereich(p)
    if p.get("wert") is None:
        p["wert"] = ""
    ctx = _Leer({k: ("" if v is None else v) for k, v in p.items()})
    return {k: m[k].format_map(ctx) for k in ("titel", "was", "warum", "wie")}
