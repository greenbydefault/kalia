"""Pruefregeln des Imports.

run_rules(ctx) -> Liste von Meldungen:
  {code, severity, feld, abschnitt, params, wert, vorschlag, status}

Schweregrade:
  hart            blockiert Anlegen immer
  uebersteuerbar  blockiert, bis im CMS mit Begruendung uebersteuert (import_override)
  warnung         Anlegen moeglich

ctx (alles optional ausser trail):
  trail        DB-Spalten (id, name, typ, ..., route, area)
  stationen    [{reihenfolge, km, lat, lon, titel, kurztext, erlebnisse, ...}]
  arten        [{name_de, name_lat, species_id, nachweis}]
  arten_offen  [{name_de, name_lat_guess, grund: unbekannt|unsicher}]   (species_suggestions)
  bilder       [{license, status, ...}]
  meta         {template_version, abschnitte, quellen_je_abschnitt, slug_gueltig, ...}
  hinweise     Parser-Hinweise (FORM, SCHEMA)
  list_fixes   [{feld, raw, mapped}]
  geo_issues, bild_issues   [{code, feld, wert}]
  duplicates   [{id, name, distanz_m, aehnlichkeit, art}]
  slug_kollision bool, kandidat_vorhanden bool|None
  kuerzung     callable(feld, text, max_zeichen) -> str | None   (KI-Rueckfall, optional)
  mit_dossier  True im Importlauf (Abschnittsstatus, Quellen, Dateien sind bekannt)
"""
from __future__ import annotations

import re
from typing import Any, Callable, Dict, List, Optional

from . import config, lists
from .geometry import distance_to_trail_m, haversine_m, length_km, max_jump_m

HART, UEBERSTEUERBAR, WARNUNG = "hart", "uebersteuerbar", "warnung"

SEVERITY: Dict[str, str] = {
    # hart
    "SCHEMA": HART, "PFLICHT": HART, "SLUG": HART, "KOORD_AUSSERHALB": HART,
    "TEMPLATE_VERSION": HART, "GEOMETRIE_FEHLT": HART,
    # uebersteuerbar
    "STATIONEN_MIN": UEBERSTEUERBAR, "WERT_UNPLAUSIBEL": UEBERSTEUERBAR,
    "DOSSIER_UNVOLLSTAENDIG": UEBERSTEUERBAR,
    # warnung
    "DATEI_FEHLT": WARNUNG, "FORM": WARNUNG, "TEXT_LAENGE": WARNUNG, "HOERTEXT_FEHLT": WARNUNG,
    "LEBENSRAUM_LEER": WARNUNG,
    "QUELLE_FEHLT": WARNUNG, "ART_UNBEKANNT": WARNUNG, "ART_UNSICHER": WARNUNG,
    "BILD_LIZENZ": WARNUNG, "BILD_FEHLT": WARNUNG, "BILD_DATEI": WARNUNG, "DUPLIKAT_NAH": WARNUNG,
    "DUPLIKAT_MOEGLICH": WARNUNG, "KANDIDAT_FEHLT": WARNUNG, "GEOMETRIE_LIZENZ": WARNUNG,
    "GEOMETRIE_DATEI": WARNUNG, "START_ABWEICHUNG": WARNUNG, "LAENGE_ABWEICHUNG": WARNUNG,
    "STATION_ABSEITS": WARNUNG,
    # Listenwerte: hart, wenn nicht zuordenbar; warnung, wenn zugeordnet (Severity je Eintrag)
    "TYP": HART, "NATURRAUM": HART, "LEBENSRAUM": HART, "TAG": HART, "ERLEBNIS": HART,
}
LIST_CODE = {"typ": "TYP", "naturraum": "NATURRAUM", "lebensraeume": "LEBENSRAUM",
             "tags": "TAG", "erlebnisse": "ERLEBNIS"}

FIELD_ABSCHNITT = {
    **{k: 1 for k in ("id", "name", "typ", "form", "land", "bundesland", "kreis", "ort",
                      "schutzgebiet", "region", "betreiber", "website")},
    **{k: 2 for k in ("kurzbeschreibung", "beschreibung", "anreise", "besuchshinweise",
                      "markierung", "start_name", "hoertext")},
    **{k: 3 for k in ("start_lat", "start_lon", "route", "area", "laenge_km", "dauer_min",
                      "rundkurs", "eintritt", "eintritt_preise", "oeffnungszeiten", "tags")},
    **{k: 4 for k in ("naturraum", "lebensraeume", "arten")},
    "stationen": 6, "bilder": 7,
}

# Felder, die immer gefuellt sein muessen (laenge_km nur bei Linie)
PFLICHT_FELDER = ("name", "typ", "land", "kurzbeschreibung", "beschreibung", "markierung",
                  "betreiber", "region", "anreise", "start_name", "dauer_min", "naturraum")


def _abschnitt(feld: str) -> Optional[int]:
    base = re.split(r"\[", feld or "")[0]
    if base.startswith("abschnitt"):
        try:
            return int(base[len("abschnitt"):])
        except ValueError:
            return None
    return FIELD_ABSCHNITT.get(base)


def E(code: str, feld: str = "", severity: Optional[str] = None, wert: Any = None,
      vorschlag: Any = None, **params: Any) -> Dict[str, Any]:
    return {
        "code": code, "severity": severity or SEVERITY[code], "feld": feld,
        "abschnitt": _abschnitt(feld), "params": params, "wert": wert,
        "vorschlag": vorschlag, "status": "offen",
    }


def _blank(v: Any) -> bool:
    return v is None or (isinstance(v, str) and not v.strip()) or v == []


def _woerter(text: str) -> int:
    return len(re.findall(r"\S+", text or ""))


# --------------------------------------------------------------------------
# Einzelregeln
# --------------------------------------------------------------------------
def rule_dossier(ctx) -> List[Dict[str, Any]]:
    meta = ctx.get("meta") or {}
    out: List[Dict[str, Any]] = []
    if not ctx.get("mit_dossier"):
        return out
    tv = meta.get("template_version")
    if tv not in (2, 3):
        out.append(E("TEMPLATE_VERSION", "", gefunden=tv, erlaubt="2, 3"))
    abschn = meta.get("abschnitte") or {}
    for n in lists.PFLICHT_ABSCHNITTE:
        status = abschn.get(str(n))
        if status is not None and status not in lists.STATUS:
            out.append(E("SCHEMA", "abschnitt%d" % n, wert=status, was="Abschnittsstatus", erlaubt=", ".join(lists.STATUS)))
        elif status not in lists.STATUS_FERTIG:
            out.append(E("DOSSIER_UNVOLLSTAENDIG", "abschnitt%d" % n, wert=status, nummer=n,
                         status=status or "fehlt"))
    return out


def rule_hinweise(ctx) -> List[Dict[str, Any]]:
    out = []
    for h in ctx.get("hinweise") or []:
        if h["code"] == "SCHEMA":
            out.append(E("SCHEMA", h["feld"], wert=h.get("roh"), was=h["feld"]))
        elif h["code"] == "FORM":
            out.append(E("FORM", h["feld"], wert=h.get("roh"), vorschlag=h.get("wert")))
    return out


def rule_slug(ctx) -> List[Dict[str, Any]]:
    meta = ctx.get("meta") or {}
    out = []
    if ctx.get("mit_dossier") and meta.get("slug_gueltig") is False:
        out.append(E("SLUG", "id", wert=meta.get("slug_roh"), grund="ungueltig"))
    if ctx.get("slug_kollision"):
        out.append(E("SLUG", "id", wert=(ctx["trail"] or {}).get("id"), grund="kollision"))
    return out


def rule_pflicht(ctx) -> List[Dict[str, Any]]:
    t = ctx["trail"]
    fixed = {f["feld"] for f in ctx.get("list_fixes") or [] if f.get("mapped") is None}
    out = []
    for feld in PFLICHT_FELDER:
        if feld in fixed:
            continue
        if _blank(t.get(feld)):
            out.append(E("PFLICHT", feld))
    form = t.get("form") or "linie"
    if form not in lists.FORMEN:
        out.append(E("SCHEMA", "form", wert=form, was="form", erlaubt=", ".join(lists.FORMEN)))
    if form == "linie" and t.get("laenge_km") in (None, ""):
        out.append(E("PFLICHT", "laenge_km"))
    if t.get("start_lat") is None or t.get("start_lon") is None:
        out.append(E("PFLICHT", "start_lat"))
    if _blank(t.get("lebensraeume")) and "lebensraeume" not in fixed:
        # datenmodell.md: leer ist erlaubt (Spielplatz, Geopfad). Darum Warnung, kein harter Fehler.
        out.append(E("LEBENSRAUM_LEER", "lebensraeume"))
    land = t.get("land")
    if land and land not in lists.LAENDER:
        out.append(E("SCHEMA", "land", wert=land, was="land", erlaubt=", ".join(lists.LAENDER)))
    return out


def rule_listen(ctx) -> List[Dict[str, Any]]:
    out = []
    for fix in ctx.get("list_fixes") or []:
        feld = fix["feld"]
        base = "erlebnisse" if feld.startswith("stationen[") else feld
        code = LIST_CODE[base]
        mapped = fix.get("mapped")
        sev = WARNUNG if mapped else HART
        erlaubt = {"typ": lists.TYP, "naturraum": lists.NATURRAUM, "lebensraeume": lists.LEBENSRAEUME,
                   "tags": lists.TAGS, "erlebnisse": lists.ERLEBNISSE}[base]
        out.append(E(code, feld, severity=sev, wert=fix["raw"], vorschlag=mapped,
                     erlaubt=", ".join(erlaubt)))
    t = ctx["trail"]
    # Sicherheitsnetz (Validate-Modus, CMS-Eingaben): Werte ausserhalb von Anhang A
    gemeldet = {(f["feld"], f["raw"]) for f in ctx.get("list_fixes") or []}

    def pruefe(feld: str, werte, erlaubt, code: str, mit_feld: Optional[str] = None) -> None:
        for w in werte:
            if w and w not in erlaubt and (mit_feld or feld, w) not in gemeldet:
                out.append(E(code, mit_feld or feld, severity=HART, wert=w, erlaubt=", ".join(erlaubt)))

    pruefe("typ", [t.get("typ")], lists.TYP, "TYP")
    pruefe("naturraum", [t.get("naturraum")], lists.NATURRAUM, "NATURRAUM")
    pruefe("lebensraeume", t.get("lebensraeume") or [], lists.LEBENSRAEUME, "LEBENSRAUM")
    pruefe("tags", t.get("tags") or [], lists.TAGS, "TAG")
    for s in ctx.get("stationen") or []:
        pruefe("erlebnisse", s.get("erlebnisse") or [], lists.ERLEBNISSE, "ERLEBNIS",
               "stationen[%s]" % s.get("reihenfolge"))
    if len(t.get("lebensraeume") or []) > 3:
        out.append(E("WERT_UNPLAUSIBEL", "lebensraeume", wert=t["lebensraeume"], was="lebensraeume", max=3))
    return out


def rule_koordinaten(ctx) -> List[Dict[str, Any]]:
    t = ctx["trail"]
    lat, lon = t.get("start_lat"), t.get("start_lon")
    out = []
    if lat is None or lon is None:
        return out

    def in_box(land: str) -> bool:
        la0, la1, lo0, lo1 = config.LAENDER_BOX[land]
        return la0 <= lat <= la1 and lo0 <= lon <= lo1

    land = t.get("land")
    ok = in_box(land) if land in config.LAENDER_BOX else any(in_box(x) for x in config.LAENDER_BOX)
    if not ok:
        out.append(E("KOORD_AUSSERHALB", "start_lat", wert=[lat, lon], land=land or "DE, DK, ES"))
    return out


def rule_geometrie(ctx) -> List[Dict[str, Any]]:
    t = ctx["trail"]
    form = t.get("form") or "linie"
    route, area = t.get("route") or [], t.get("area") or []
    out = []
    for gi in ctx.get("geo_issues") or []:
        if gi["code"] in ("GEOMETRIE_LIZENZ", "GEOMETRIE_DATEI", "DATEI_FEHLT"):
            out.append(E(gi["code"], gi.get("feld") or ("area" if form == "flaeche" else "route"),
                         wert=gi.get("wert")))
    if form == "linie" and len(route) < 2:
        out.append(E("GEOMETRIE_FEHLT", "route", form=form))
        return out
    if form == "flaeche" and len(area) < 3:
        out.append(E("GEOMETRIE_FEHLT", "area", form=form))
        return out

    lat, lon = t.get("start_lat"), t.get("start_lon")
    if lat is not None and lon is not None:
        d = distance_to_trail_m([lat, lon], route if form == "linie" else None, area if form == "flaeche" else None)
        if d is not None and d > config.START_ABWEICHUNG_M:
            out.append(E("START_ABWEICHUNG", "start_lat", wert=round(d), meter=round(d),
                         max=config.START_ABWEICHUNG_M))
    if form == "linie":
        laenge = t.get("laenge_km")
        gps = length_km(route)
        if laenge and gps > 0 and abs(laenge - gps) / gps * 100 > config.LAENGE_ABWEICHUNG_PROZENT:
            out.append(E("LAENGE_ABWEICHUNG", "laenge_km", wert=laenge, vorschlag=round(gps, 2),
                         dossier=laenge, route=round(gps, 2), prozent=config.LAENGE_ABWEICHUNG_PROZENT))
        sprung = max_jump_m(route)
        if sprung > config.MAX_SPRUNG_M:
            out.append(E("WERT_UNPLAUSIBEL", "route", wert=round(sprung), was="route", sprung=round(sprung),
                         max=config.MAX_SPRUNG_M))
    for s in ctx.get("stationen") or []:
        if s.get("lat") is None or s.get("lon") is None:
            continue
        d = distance_to_trail_m([s["lat"], s["lon"]], route if form == "linie" else None,
                                area if form == "flaeche" else None)
        if d is not None and d > config.STATION_ABSEITS_M:
            out.append(E("STATION_ABSEITS", "stationen[%s]" % s.get("reihenfolge"), wert=round(d),
                         nummer=s.get("reihenfolge"), meter=round(d), max=config.STATION_ABSEITS_M))
    return out


def rule_werte(ctx) -> List[Dict[str, Any]]:
    t = ctx["trail"]
    form = t.get("form") or "linie"
    out = []
    laenge, dauer = t.get("laenge_km"), t.get("dauer_min")
    if form == "linie" and laenge is not None:
        if laenge <= 0 or laenge > config.MAX_LAENGE_KM:
            out.append(E("WERT_UNPLAUSIBEL", "laenge_km", wert=laenge, was="laenge_km", max=config.MAX_LAENGE_KM))
    if dauer is not None and (dauer <= 0 or dauer > config.MAX_DAUER_MIN):
        out.append(E("WERT_UNPLAUSIBEL", "dauer_min", wert=dauer, was="dauer_min", max=config.MAX_DAUER_MIN))
    if form == "linie" and laenge and dauer and laenge > 0 and dauer > 0:
        kmh = laenge / (dauer / 60.0)
        if kmh < config.DAUER_KMH_MIN or kmh > config.DAUER_KMH_MAX:
            out.append(E("WERT_UNPLAUSIBEL", "dauer_min", wert=dauer, was="tempo", kmh=round(kmh, 1),
                         min=config.DAUER_KMH_MIN, max=config.DAUER_KMH_MAX))
    return out


def rule_texte(ctx) -> List[Dict[str, Any]]:
    t = ctx["trail"]
    kuerzung: Optional[Callable] = ctx.get("kuerzung")
    out = []
    for feld, (mn, mx) in lists.LIMITS.items():
        text = (t.get(feld) or "").strip()
        if not text:
            continue
        n = len(text)
        if mx is not None and n > mx:
            vorschlag = kuerzung(feld, text, mx) if kuerzung else None
            out.append(E("TEXT_LAENGE", feld, wert=n, vorschlag=vorschlag, laenge=n, min=mn or 0, max=mx))
        elif mn is not None and n < mn:
            out.append(E("TEXT_LAENGE", feld, wert=n, laenge=n, min=mn, max=mx or 0))
    hoer = (t.get("hoertext") or "").strip()
    if not hoer:
        out.append(E("HOERTEXT_FEHLT", "hoertext"))
    else:
        w = _woerter(hoer)
        lo, hi = lists.HOERTEXT_WOERTER
        if w < lo or w > hi:
            out.append(E("TEXT_LAENGE", "hoertext", wert=w, laenge=w, min=lo, max=hi, einheit="Wörter"))
    for s in ctx.get("stationen") or []:
        kt = (s.get("kurztext") or "").strip()
        if kt and len(kt) < lists.STATION_KURZTEXT_MIN:
            out.append(E("TEXT_LAENGE", "stationen[%s]" % s.get("reihenfolge"), wert=len(kt),
                         laenge=len(kt), min=lists.STATION_KURZTEXT_MIN, max=0, nummer=s.get("reihenfolge")))
    return out


def rule_stationen(ctx) -> List[Dict[str, Any]]:
    t = ctx["trail"]
    form = t.get("form") or "linie"
    st = ctx.get("stationen") or []
    out = []
    n = len(st)
    flaechentyp = t.get("typ") in lists.FLAECHEN_TYPEN or form == "flaeche"
    if n == 0:
        out.append(E("STATIONEN_MIN", "stationen", severity=HART, anzahl=0, min=3, grund="keine"))
    elif n < 3:
        out.append(E("STATIONEN_MIN", "stationen", severity=WARNUNG if flaechentyp else UEBERSTEUERBAR,
                     anzahl=n, min=3, grund="wenige"))
    nummern = [s.get("reihenfolge") for s in st]
    if n and nummern != list(range(1, n + 1)):
        out.append(E("STATIONEN_MIN", "stationen", severity=UEBERSTEUERBAR, anzahl=n, min=3, grund="luecke",
                     nummern=",".join(str(x) for x in nummern)))
    for s in ctx.get("stationen_unvollstaendig") or []:
        out.append(E("PFLICHT", "stationen[%s]" % s.get("reihenfolge"), nummer=s.get("reihenfolge"),
                     fehlt=s.get("fehlt")))
    return out


def rule_quellen(ctx) -> List[Dict[str, Any]]:
    if not ctx.get("mit_dossier"):
        return []
    meta = ctx.get("meta") or {}
    q = meta.get("quellen_je_abschnitt") or {}
    arten = ctx.get("arten") or []
    stationen = ctx.get("stationen") or []
    bilder = ctx.get("bilder") or []
    hat = {
        1: q.get("1", 0) > 0, 2: q.get("2", 0) > 0, 3: q.get("3", 0) > 0,
        4: q.get("4", 0) > 0 or any(a.get("quelle") for a in arten),
        6: q.get("6", 0) > 0 or any(s.get("quelle") for s in stationen),
        7: q.get("7", 0) > 0 or any(b.get("source_url") for b in bilder),
    }
    return [E("QUELLE_FEHLT", "abschnitt%d" % n, nummer=n) for n in lists.PFLICHT_ABSCHNITTE if not hat[n]]


def rule_arten(ctx) -> List[Dict[str, Any]]:
    out = []
    for a in ctx.get("arten_offen") or []:
        code = "ART_UNSICHER" if a.get("grund") == "unsicher" else "ART_UNBEKANNT"
        out.append(E(code, "arten", wert=a.get("name_de"), vorschlag=a.get("name_lat_guess"),
                     name=a.get("name_de"), lat=a.get("name_lat_guess") or a.get("name_lat") or ""))
    if not (ctx.get("arten") or ctx.get("arten_offen")) and ctx.get("mit_dossier"):
        out.append(E("PFLICHT", "arten"))
    return out


def rule_bilder(ctx) -> List[Dict[str, Any]]:
    out = []
    for bi in ctx.get("bild_issues") or []:
        if bi["code"] in ("DATEI_FEHLT", "BILD_DATEI"):
            out.append(E(bi["code"], bi.get("feld") or "bilder", wert=bi.get("wert")))
    bilder = ctx.get("bilder") or []
    for i, b in enumerate(bilder, 1):
        if (b.get("license") or "") not in lists.BILD_LIZENZ_APPROVED:
            out.append(E("BILD_LIZENZ", "bilder[%d]" % i, wert=b.get("license") or None,
                         datei=b.get("datei") or b.get("caption") or "Bild %d" % i, nummer=i))
    if not any((b.get("license") or "") in lists.BILD_LIZENZ_APPROVED for b in bilder):
        out.append(E("BILD_FEHLT", "bilder"))
    return out


def rule_abgleich(ctx) -> List[Dict[str, Any]]:
    out = []
    for d in ctx.get("duplicates") or []:
        code = "DUPLIKAT_NAH" if d.get("art") == "nah" else "DUPLIKAT_MOEGLICH"
        out.append(E(code, "id", wert=d.get("id"), id=d.get("id"), name=d.get("name"),
                     meter=round(d.get("distanz_m") or 0), aehnlichkeit=round(d.get("aehnlichkeit") or 0, 2)))
    if ctx.get("kandidat_vorhanden") is False:
        out.append(E("KANDIDAT_FEHLT", "id", wert=(ctx["trail"] or {}).get("id")))
    return out


RULES = (rule_dossier, rule_hinweise, rule_slug, rule_pflicht, rule_listen, rule_koordinaten,
         rule_geometrie, rule_werte, rule_texte, rule_stationen, rule_quellen, rule_arten,
         rule_bilder, rule_abgleich)


def run_rules(ctx: Dict[str, Any]) -> List[Dict[str, Any]]:
    out: List[Dict[str, Any]] = []
    for r in RULES:
        out.extend(r(ctx))
    return out


# --------------------------------------------------------------------------
# Hilfen fuer den Worker
# --------------------------------------------------------------------------
def apply_overrides(neu: List[Dict[str, Any]], alt: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Uebernimmt Uebersteuerungen (override) aus dem alten Report in den neuen, wenn Code und Feld gleich sind."""
    alt_map = {(e["code"], e.get("feld", "")): e["override"] for e in alt if e.get("override")}
    for e in neu:
        ov = alt_map.get((e["code"], e.get("feld", "")))
        if ov and e["severity"] == UEBERSTEUERBAR:
            e["override"] = ov
    return neu


def blockiert(report: List[Dict[str, Any]]) -> Dict[str, int]:
    """Wie public.import_open_blockers (SQL): offene harte und nicht uebersteuerte Meldungen."""
    hart = ueber = 0
    for e in report:
        if (e.get("status") or "offen") != "offen":
            continue
        if e["severity"] == HART:
            hart += 1
        elif e["severity"] == UEBERSTEUERBAR and not (e.get("override") or {}).get("reason"):
            ueber += 1
    return {"hart": hart, "uebersteuerbar": ueber}


# Meldungen, die im Validate-Modus aus dem alten Report uebernommen werden (nicht aus der DB ableitbar)
CARRY_CODES = {"FORM", "DATEI_FEHLT", "BILD_DATEI", "GEOMETRIE_LIZENZ", "GEOMETRIE_DATEI",
               "TEMPLATE_VERSION", "KANDIDAT_FEHLT", "DOSSIER_UNVOLLSTAENDIG", "QUELLE_FEHLT"}


def carry_over(alt: List[Dict[str, Any]], stationen_in_db: List[int]) -> List[Dict[str, Any]]:
    out = []
    for e in alt:
        c = e["code"]
        if c in CARRY_CODES:
            out.append(e)
        elif c in LIST_CODE.values() and e["severity"] == WARNUNG:
            out.append(e)
        elif c == "PFLICHT" and e.get("feld", "").startswith("stationen["):
            nr = (e.get("params") or {}).get("nummer")
            if nr not in stationen_in_db:
                out.append(e)
    return out


def carry_status(neu: List[Dict[str, Any]], alt: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Entscheidungen im CMS (status != offen, z. B. Duplikat 'Ist neu') bleiben bei Neuberechnung erhalten."""
    alt_map = {(e["code"], e.get("feld", ""), str(e.get("wert"))): e["status"]
               for e in alt if (e.get("status") or "offen") != "offen"}
    for e in neu:
        st = alt_map.get((e["code"], e.get("feld", ""), str(e.get("wert"))))
        if st:
            e["status"] = st
    return neu
