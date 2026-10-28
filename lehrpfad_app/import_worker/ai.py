"""KI-Rueckfall (klein, optional). Ohne ANTHROPIC_API_KEY oder bei erreichtem Kosten-Deckel liefert alles None.

Zwei Aufgaben:
  normalize_with_ai(field, raw_value, allowed_values) -> value | None
      Wert ausserhalb von Anhang A zuordnen, oder (allowed_values=None) fehlenden
      wissenschaftlichen Namen ergaenzen. Antwort nur ueber ein Tool mit enum, nie Freitext in die DB.
  kuerzung(field, text, max_zeichen) -> str | None
      Kuerzungsvorschlag fuer TEXT_LAENGE. Wird nur als Vorschlag in den Report geschrieben.

Texte, Hoertext und Stationstexte kommen fertig vom Texte-Bot und werden nie von der KI umgeschrieben.
Modell nur in config.py (KI_MODELL / Env KALIA_KI_MODELL). Jeder Aufruf landet in `events` (-> field_meta,
import_events) mit Token und Kosten.
"""
from __future__ import annotations

import json
import re
import urllib.error
import urllib.request
from typing import Any, Callable, Dict, List, Optional, Sequence

from . import config

Transport = Callable[[Dict[str, Any]], Dict[str, Any]]

_LAT = re.compile(r"^[A-Z][a-z]+ [a-z][a-z-]+$")

SYSTEM = (
    "Du ordnest Werte aus Pfad-Dossiers fuer eine Naturlehrpfad-App ein. "
    "Antworte ausschliesslich ueber das Tool. Wenn nichts sicher passt, gib null zurueck. Raten ist falsch."
)
SYSTEM_KUERZEN = (
    "Du kuerzt deutsche Texte fuer eine Naturlehrpfad-App. Regeln: Inhalt und Fakten behalten, "
    "keine neuen Fakten, keine direkte Anrede (kein du/Sie/Ihr), nuechterne Doku-Stimme, kein Ausrufezeichen. "
    "Gib nur den gekuerzten Text zurueck, ohne Anfuehrungszeichen und Kommentar."
)


class Kostendeckel(Exception):
    pass


def kosten_usd(modell: str, tokens_in: int, tokens_out: int) -> float:
    pin, pout = config.KI_PREISE.get(modell, (0.0, 0.0))
    return (tokens_in * pin + tokens_out * pout) / 1_000_000.0


def _http(payload: Dict[str, Any]) -> Dict[str, Any]:
    import os
    req = urllib.request.Request(
        config.KI_API_URL, data=json.dumps(payload).encode("utf-8"), method="POST",
        headers={"content-type": "application/json", "x-api-key": os.environ.get("ANTHROPIC_API_KEY", ""),
                 "anthropic-version": config.KI_API_VERSION},
    )
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read().decode("utf-8"))


class KI:
    """Ein Objekt je Batch: haelt Kosten, Cache und Ereignisse."""

    def __init__(self, aktiv: Optional[bool] = None, modell: Optional[str] = None,
                 deckel_usd: Optional[float] = None, transport: Optional[Transport] = None):
        self.aktiv = config.KI_AKTIV if aktiv is None else aktiv
        self.modell = modell or config.KI_MODELL
        self.deckel = config.KI_KOSTEN_DECKEL_USD_BATCH if deckel_usd is None else deckel_usd
        self.transport = transport or _http
        self.kosten = 0.0
        self.aufrufe = 0
        self.events: List[Dict[str, Any]] = []
        self._cache: Dict[Any, Any] = {}

    # -- intern -----------------------------------------------------------
    def _call(self, payload: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        if not self.aktiv:
            return None
        if self.kosten >= self.deckel:
            raise Kostendeckel("KI-Kosten-Deckel erreicht (%.2f USD)" % self.deckel)
        payload = {"model": self.modell, "max_tokens": config.KI_MAX_TOKENS, **payload}
        try:
            res = self.transport(payload)
        except (urllib.error.URLError, TimeoutError, OSError, ValueError):
            return None  # KI ist Rueckfall: Netzfehler heisst nur "kein Vorschlag"
        u = res.get("usage") or {}
        k = kosten_usd(self.modell, u.get("input_tokens", 0), u.get("output_tokens", 0))
        self.kosten += k
        self.aufrufe += 1
        res["_kosten"] = k
        return res

    def _log(self, feld: str, raw: Any, value: Any, res: Optional[Dict[str, Any]], aufgabe: str) -> None:
        self.events.append({
            "feld": feld, "aufgabe": aufgabe, "raw": raw, "value": value, "modell": self.modell,
            "kosten_usd": round((res or {}).get("_kosten", 0.0), 6),
        })

    # -- API ----------------------------------------------------------------
    def normalize_with_ai(self, field: str, raw_value: Any, allowed_values: Optional[Sequence[str]]) -> Optional[str]:
        key = ("n", field, str(raw_value), tuple(allowed_values or ()))
        if key in self._cache:
            return self._cache[key]
        if allowed_values:
            schema: Dict[str, Any] = {"type": "object", "required": ["value"], "properties": {
                "value": {"enum": list(allowed_values) + [None]}}}
            prompt = ("Feld: %s\nRohwert: %s\nErlaubte Werte: %s\nWelcher erlaubte Wert ist gemeint?"
                      % (field, raw_value, ", ".join(allowed_values)))
        else:
            schema = {"type": "object", "required": ["value"], "properties": {
                "value": {"type": ["string", "null"], "description": "Gattung und Art, z. B. 'Grus grus'"}}}
            prompt = ("Feld: %s\nRohwert: %s\nGib den wissenschaftlichen Namen (Gattung und Art) zurueck, "
                      "nur wenn eindeutig." % (field, raw_value))
        res = self._call({
            "system": SYSTEM, "messages": [{"role": "user", "content": prompt}],
            "tools": [{"name": "antwort", "description": "Eingeordneter Wert oder null",
                       "input_schema": schema}],
            "tool_choice": {"type": "tool", "name": "antwort"},
        })
        value = None
        if res:
            for blk in res.get("content") or []:
                if blk.get("type") == "tool_use":
                    value = (blk.get("input") or {}).get("value")
        if allowed_values:
            if value not in allowed_values:
                value = None
        elif not (isinstance(value, str) and _LAT.match(value.strip())):
            value = None
        else:
            value = value.strip()
        if res is not None:
            self._log(field, raw_value, value, res, "normalize")
        self._cache[key] = value
        return value

    def kuerzung(self, field: str, text: str, max_zeichen: int) -> Optional[str]:
        key = ("k", field, text, max_zeichen)
        if key in self._cache:
            return self._cache[key]
        res = self._call({
            "system": SYSTEM_KUERZEN,
            "messages": [{"role": "user", "content": "Hoechstens %d Zeichen (aktuell %d). Text:\n%s"
                                                     % (max_zeichen, len(text), text)}],
        })
        out = None
        if res:
            txt = "".join(b.get("text", "") for b in res.get("content") or [] if b.get("type") == "text").strip()
            if txt and len(txt) <= max_zeichen:
                out = txt
            self._log(field, len(text), out, res, "kuerzung")
        self._cache[key] = out
        return out

    # -- Adapter fuer lists_fix / rules -------------------------------------
    def suggest(self, feld: str, raw: str, allowed: Sequence[str]) -> Optional[str]:
        try:
            return self.normalize_with_ai(feld, raw, allowed)
        except Kostendeckel:
            return None

    def suggest_lat(self, name_de: str) -> Optional[str]:
        try:
            return self.normalize_with_ai("name_lat", name_de, None)
        except Kostendeckel:
            return None

    def kuerzen_cb(self, feld: str, text: str, mx: int) -> Optional[str]:
        try:
            return self.kuerzung(feld, text, mx)
        except Kostendeckel:
            return None

    def field_meta(self) -> Dict[str, Dict[str, Any]]:
        """Fuer trails.field_meta: welches Feld kam wie zustande (nur KI-Eintraege mit Wert)."""
        out: Dict[str, Dict[str, Any]] = {}
        for e in self.events:
            if e["aufgabe"] == "normalize" and e["value"] is not None:
                out[e["feld"]] = {"quelle": "ki", "modell": e["modell"], "roh": e["raw"]}
        return out

    def stats(self) -> Dict[str, Any]:
        return {"aufrufe": self.aufrufe, "kosten_usd": round(self.kosten, 6), "modell": self.modell}
