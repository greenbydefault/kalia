"""Werte ausserhalb von Anhang A zuordnen: erst deterministisch, dann (optional) per KI-Rueckfall.

fix_lists(draft, suggest) veraendert den Draft und liefert Korrekturen:
  [{"feld": "typ"|"naturraum"|"lebensraeume"|"tags"|"stationen[n]", "raw": "...", "mapped": "key"|None}]
Nicht zuordenbare Werte werden entfernt (Einzelwert: None), der Rohwert steht in der Korrektur.
"""
from __future__ import annotations

import re
from typing import Any, Callable, Dict, List, Optional

from . import lists

SYNONYME: Dict[str, Dict[str, str]] = {
    "tags": {
        "kinderwagen": "kinderwagentauglich", "kinderwagen ok": "kinderwagentauglich",
        "kinderwagen geeignet": "kinderwagentauglich", "mit kinderwagen": "kinderwagentauglich",
        "rollstuhl": "rollstuhltauglich", "rollstuhl geeignet": "rollstuhltauglich",
        "barrierefrei": "rollstuhltauglich",
        "hunde": "hunde-erlaubt", "hunde erlaubt": "hunde-erlaubt", "hund erlaubt": "hunde-erlaubt",
        "kinder": "kinderfreundlich", "familie": "kinderfreundlich", "familienfreundlich": "kinderfreundlich",
        "gastronomie": "einkehr", "restaurant": "einkehr", "café": "einkehr", "cafe": "einkehr",
        "spielplatz vorhanden": "spielplatz", "rastplatz": "picknick", "grillplatz": "picknick",
        "barfuss": "barfusspfad", "barfuß": "barfusspfad", "barfußpfad": "barfusspfad",
    },
    "erlebnisse": {
        "infotafel": "tafel", "tafeln": "tafel", "lehrtafel": "tafel", "schautafel": "tafel",
        "rätsel": "quiz", "raetsel": "quiz", "quizfragen": "quiz",
        "holzsteg": "steg", "bohlenweg": "steg",
        "mitmachstation": "mitmach-modell", "mitmachen": "mitmach-modell", "modell": "mitmach-modell",
        "hörstation": "audio", "hoerstation": "audio", "audio-guide": "audio",
        "bestimmen": "bestimmung", "bestimmungshilfe": "bestimmung",
    },
    "typ": {
        "küstenpfad": "kueste", "kuestenpfad": "kueste", "küste": "kueste",
        "bauernhof": "kinderbauernhof", "barfußpfad": "barfusspfad", "barfuss": "barfusspfad",
    },
    "naturraum": {
        "norddeutsches tiefland": "norddt-tiefland", "tiefland": "norddt-tiefland",
        "nord see": "nordsee", "ost see": "ostsee", "katalonien (spanien)": "katalonien",
    },
    "lebensraeume": {
        "buchen": "buchenwald", "kiefernwald": "kiefernforst", "kiefer": "kiefernforst",
        "mischwald": "eichen-mischwald", "eichenwald": "eichen-mischwald", "aue": "auwald",
        "teich": "teich-tuempel", "tümpel": "teich-tuempel", "see": "see-ufer", "ufer": "see-ufer",
        "bach": "fliessgewaesser", "fluss": "fliessgewaesser", "fließgewässer": "fliessgewaesser",
        "dünen": "duene-strand", "duene": "duene-strand", "strand": "duene-strand", "düne": "duene-strand",
        "wattenmeer": "salzwiese-watt", "watt": "salzwiese-watt", "salzwiese": "salzwiese-watt",
        "streuobstwiese": "streuobst-hecke", "hecke": "streuobst-hecke",
        "nadelwald": "nadelforst", "fichtenforst": "nadelforst", "bergwald": "alpen-wald",
        "trockenrasen": "trockenrasen", "bauernhof": "hof-nutztier",
    },
}

ERLAUBT = {
    "typ": lists.TYP, "naturraum": lists.NATURRAUM, "lebensraeume": lists.LEBENSRAEUME,
    "tags": lists.TAGS, "erlebnisse": lists.ERLEBNISSE,
}


def _norm(s: str) -> str:
    s = s.strip().lower()
    return re.sub(r"\s+", " ", s)


def _dash(s: str) -> str:
    t = s
    for a, b in (("ä", "ae"), ("ö", "oe"), ("ü", "ue"), ("ß", "ss")):
        t = t.replace(a, b)
    return re.sub(r"[^a-z0-9]+", "-", t).strip("-")


def deterministisch(feld: str, raw: str) -> Optional[str]:
    allowed = ERLAUBT[feld]
    n = _norm(raw)
    if n in allowed:
        return n
    d = _dash(n)
    if d in allowed:
        return d
    return SYNONYME.get(feld, {}).get(n) or SYNONYME.get(feld, {}).get(d)


Suggest = Callable[[str, str, Any], Optional[str]]


def _map(feld: str, raw: str, suggest: Optional[Suggest]) -> Optional[str]:
    m = deterministisch(feld, raw)
    if m:
        return m
    if suggest:
        v = suggest(feld, raw, ERLAUBT[feld])
        if v in ERLAUBT[feld]:
            return v
    return None


def fix_list_values(feld: str, werte: List[str], suggest: Optional[Suggest]):
    """-> (neue Werte ohne Duplikate, Korrekturen). Gueltige Werte bleiben unveraendert und lautlos."""
    out: List[str] = []
    fixes: List[Dict[str, Any]] = []
    allowed = ERLAUBT[feld]
    for raw in werte:
        if raw in allowed:
            m, stumm = raw, True
        else:
            m, stumm = _map(feld, raw, suggest), False
        if not stumm:
            fixes.append({"raw": raw, "mapped": m})
        if m and m not in out:
            out.append(m)
    return out, fixes


def fix_lists(draft: Dict[str, Any], suggest: Optional[Suggest] = None) -> List[Dict[str, Any]]:
    t = draft["trail"]
    fixes: List[Dict[str, Any]] = []
    for feld in ("typ", "naturraum"):
        raw = t.get(feld)
        if raw and raw not in ERLAUBT[feld]:
            m = _map(feld, raw, suggest)
            fixes.append({"feld": feld, "raw": raw, "mapped": m})
            t[feld] = m
    for feld in ("lebensraeume", "tags"):
        neu, fx = fix_list_values(feld, t.get(feld) or [], suggest)
        t[feld] = neu
        fixes.extend({"feld": feld, **f} for f in fx)
    for s in draft.get("stationen") or []:
        neu, fx = fix_list_values("erlebnisse", s.get("erlebnisse") or [], suggest)
        s["erlebnisse"] = neu
        fixes.extend({"feld": "stationen[%s]" % s.get("reihenfolge"), **f} for f in fx)
    return fixes
