"""Liest ein Pfad-Dossier (Vorlage v2/v3, .docx) in eine rohe Struktur.

Anker ist die Spalte "Supabase" (Felder-Tabellen) bzw. der Spaltenkopf (Listen-Tabellen),
nicht die Ueberschrift. Der Dateiname ist egal, die ID steht in Abschnitt 1.

parse_docx(path) -> Dossier-Dict:
  template_version  int | None
  abschnitte        {"1": {"status": "fertig", "quellen": [...]}, ...}
  felder            {"trails.name": {"roh": "...", "abschnitt": 1, "label": "Name"}, ...}
  arten             [{sortierung, name_de, name_lat, species_id, nachweis, quelle}]
  pois, ausstattung (Abschnitt 5, nur roh)
  stationen         [{reihenfolge, km, lat, lon, osm_id, titel, thema, kurztext, erlebnisse, barrierefrei, quelle}]
  steckbrief        [{station, key, wert}]
  bilder            [{sort, kind, station, caption, datei, source_url, license, license_url, credit}]

Alle Werte sind noch Strings (leer = None). Typen und Hinweise macht normalize_dossier().
"""
from __future__ import annotations

import re
from typing import Any, Dict, List, Optional

import docx

from . import lists
from .docxutil import iter_body
from .normalize import (
    clean, split_latlon, to_bool, to_date, to_float, to_int, to_key, to_list,
)
from .slug import check_slug

_KEY_RE = re.compile(r"\b((?:trails|import|meta)\.[a-z_]+)")
_LABEL_KEYS_V2 = (
    ("Land", "trails.land"),
    ("Bundesland", "trails.bundesland"),
    ("Kreis", "trails.kreis"),
    ("Ort", "trails.ort"),
    ("Schutzgebiet", "trails.schutzgebiet"),
    ("Pfad-Status", "meta.pfad_status"),
    ("Grund bei verworfen", "meta.verworfen_grund"),
    ("Eignungskriterien", "meta.eignung"),
)


class DossierFehler(Exception):
    """Datei ist kein lesbares Dossier (kein docx, keine Abschnitte)."""


def _cell(c) -> Optional[str]:
    return clean(c.text)


def _supabase_key(supabase_cell: str, label: str) -> Optional[str]:
    cell = (supabase_cell or "").strip()
    # v2: "neu, Spalte geplant (bis dahin trails.region)" gehoert zu Land/Bundesland/..., nicht zu region
    m = None if cell.lower().startswith("neu") else _KEY_RE.search(cell)
    if m:
        return m.group(1)
    for prefix, key in _LABEL_KEYS_V2:
        if (label or "").startswith(prefix):
            return key
    return None


def _col_map(header: List[str], rules) -> Dict[int, str]:
    """Ordnet Spaltenindex -> Feldname ueber Praefixe des Spaltenkopfs (erste Regel gewinnt)."""
    out: Dict[int, str] = {}
    for i, h in enumerate(header):
        low = (h or "").lower().strip()
        for prefix, name in rules:
            if low.startswith(prefix):
                out[i] = name
                break
    return out


_ARTEN = (("sortierung", "sortierung"), ("art (deutsch)", "name_de"), ("wissenschaftlicher", "name_lat"),
          ("species_id", "species_id"), ("nachweis", "nachweis"), ("quelle", "quelle"))
_STATIONEN = (("reihenfolge", "reihenfolge"), ("km", "km"), ("lat", "lat"), ("lon", "lon"),
              ("osm", "osm_id"), ("titel", "titel"), ("thema", "thema"), ("kurztext", "kurztext"),
              ("erlebnisse", "erlebnisse"), ("barrierefrei", "barrierefrei"), ("quelle", "quelle"))
_BILDER = (("sort", "sort"), ("art", "kind"), ("station", "station"), ("bildunterschrift", "caption"),
           ("datei", "datei"), ("quelle", "source_url"), ("lizenz-url", "license_url"),
           ("lizenz", "license"), ("credit", "credit"), ("geo-check", "geo_check"))
_POIS = (("name", "name"), ("kategorie", "kategorie"), ("kurztext", "kurztext"), ("lat", "lat"),
         ("lon", "lon"), ("website", "website"), ("öffnungszeiten", "oeffnungszeiten"),
         ("telefon", "telefon"), ("quelle", "quelle"))
_AUSSTATTUNG = (("kategorie", "kategorie"), ("name", "name"), ("lat", "lat"), ("lon", "lon"),
                ("osm", "osm_id"))
_STECKBRIEF = (("station", "station"), ("schl", "key"), ("wert", "wert"))
_QUELLEN = (("#", "nr"), ("angabe", "angabe"), ("url", "url"), ("abgerufen", "abgerufen_am"))


def _rows(table, rules, ignore_if_only=("sortierung", "reihenfolge", "sort", "nr")) -> List[Dict[str, Any]]:
    header = [c.text.strip() for c in table.rows[0].cells]
    cmap = _col_map(header, rules)
    out = []
    for r in table.rows[1:]:
        cells = r.cells
        row = {cmap[i]: _cell(cells[i]) for i in cmap if i < len(cells)}
        # Zeilen, die nur die vorbefuellte Laufnummer tragen, sind leer
        gefuellt = [k for k, v in row.items() if v is not None and k not in ignore_if_only]
        if gefuellt:
            out.append(row)
    return out


def _classify(table) -> Optional[str]:
    if not table.rows:
        return None
    h = [c.text.strip().lower() for c in table.rows[0].cells]
    if len(h) >= 2 and h[0] == "feld" and h[1] == "supabase":
        return "felder"
    if h and h[0] == "#":
        return "quellen"
    if h and h[0].startswith("sortierung"):
        return "arten"
    if h and h[0] == "name" and len(h) > 1 and h[1].startswith("kategorie"):
        return "pois"
    if h and h[0].startswith("kategorie"):
        return "ausstattung"
    if h and h[0] == "reihenfolge":
        return "stationen"
    if h and h[0].startswith("station"):
        return "steckbrief"
    if h and h[0] == "sort":
        return "bilder"
    return None


def parse_docx(path: str) -> Dict[str, Any]:
    try:
        doc = docx.Document(path)
    except Exception as e:  # keine gueltige docx
        raise DossierFehler("Datei ist kein lesbares Word-Dokument: %s" % e)

    d: Dict[str, Any] = {
        "template_version": None, "stand": None,
        "abschnitte": {}, "felder": {}, "arten": [], "pois": [], "ausstattung": [],
        "stationen": [], "steckbrief": [], "bilder": [],
    }
    sec: Optional[int] = None

    def abschnitt(n: int) -> Dict[str, Any]:
        return d["abschnitte"].setdefault(str(n), {"status": None, "quellen": []})

    for kind, el in iter_body(doc):
        if kind == "p":
            text = el.text.strip()
            if not text:
                continue
            m = re.search(r"template_version:\s*(\d+)", text)
            if m:
                d["template_version"] = int(m.group(1))
                sm = re.search(r"Stand\s+([\d.]+)", text)
                d["stand"] = sm.group(1) if sm else None
                continue
            if el.style is not None and el.style.name.lower().startswith("heading 2"):
                hm = re.match(r"^(\d+)\.\s", text)
                if hm:
                    sec = int(hm.group(1))
                    abschnitt(sec)
                else:
                    sec = None  # Anhang A/B
                continue
            sm = re.match(r"^Status Abschnitt:\s*(.*)$", text)
            if sm and sec is not None:
                abschnitt(sec)["status"] = clean(sm.group(1))
            continue

        if sec is None:
            continue
        t = _classify(el)
        if t == "felder":
            for r in el.rows[1:]:
                c = r.cells
                if len(c) < 3:
                    continue
                label = c[0].text.strip()
                key = _supabase_key(c[1].text, label)
                if key is None:
                    continue
                d["felder"][key] = {"roh": _cell(c[2]), "abschnitt": sec, "label": label}
        elif t == "quellen":
            abschnitt(sec)["quellen"].extend(
                {k: v for k, v in q.items() if k != "nr"} for q in _rows(el, _QUELLEN))
        elif t == "arten":
            d["arten"].extend(_rows(el, _ARTEN))
        elif t == "pois":
            d["pois"].extend(_rows(el, _POIS, ignore_if_only=()))
        elif t == "ausstattung":
            d["ausstattung"].extend(_rows(el, _AUSSTATTUNG, ignore_if_only=()))
        elif t == "stationen":
            d["stationen"].extend(_rows(el, _STATIONEN))
        elif t == "steckbrief":
            d["steckbrief"].extend(_rows(el, _STECKBRIEF, ignore_if_only=()))
        elif t == "bilder":
            d["bilder"].extend(_rows(el, _BILDER))

    if not d["abschnitte"] or not d["felder"]:
        raise DossierFehler("Keine Abschnitte oder Felder gefunden: das ist nicht die Dossier-Vorlage.")
    return d


# ---------------------------------------------------------------------------
# Normalisieren: Dossier -> Draft (DB-Spaltennamen) + Hinweise
# ---------------------------------------------------------------------------
def _feld(d: Dict[str, Any], key: str) -> Optional[str]:
    f = d["felder"].get(key)
    return f["roh"] if f else None


def normalize_dossier(d: Dict[str, Any]) -> Dict[str, Any]:
    """Draft = {"trail", "stationen", "arten", "bilder", "quellen", "meta", "hinweise"}.

    hinweise: [{"code": "FORM"|"SCHEMA", "feld", "roh", "wert", "abschnitt"}]
    FORM = Wert war lesbar und wurde korrigiert (Warnung). SCHEMA = Typ nicht lesbar (hart).
    """
    hinweise: List[Dict[str, Any]] = []

    def hint(code: str, feld: str, roh: Any, wert: Any = None) -> None:
        f = d["felder"].get("trails." + feld) or {}
        hinweise.append({"code": code, "feld": feld, "roh": roh, "wert": wert,
                         "abschnitt": f.get("abschnitt")})

    def text(feld: str) -> Optional[str]:
        return clean(_feld(d, "trails." + feld))

    def key_feld(feld: str) -> Optional[str]:
        k, korr = to_key(_feld(d, "trails." + feld))
        if korr:
            hint("FORM", feld, _feld(d, "trails." + feld), k)
        return k

    def num(feld: str, conv, raw_key: Optional[str] = None):
        raw = _feld(d, raw_key or "trails." + feld)
        v, korr = conv(raw)
        if clean(raw) is not None and v is None:
            hint("SCHEMA", feld, raw)
        elif korr:
            hint("FORM", feld, raw, v)
        return v

    def boolean(feld: str):
        raw = _feld(d, "trails." + feld)
        v, korr = to_bool(raw)
        if clean(raw) is not None and v is None:
            hint("SCHEMA", feld, raw)
        elif korr:
            hint("FORM", feld, raw, v)
        return v

    def liste(feld: str):
        raw = _feld(d, "trails." + feld)
        werte = [w.lower() for w in to_list(raw)]
        if clean(raw) is not None and [w.strip() for w in to_list(raw)] != werte:
            hint("FORM", feld, raw, werte)
        return werte

    slug_roh = text("id")
    slug, slug_korr, slug_ok = check_slug(slug_roh)
    if slug_korr:
        hint("FORM", "id", slug_roh, slug)

    start_raw = _feld(d, "trails.start_lat")
    lat, lon, _ = split_latlon(start_raw)
    if lat is None and clean(start_raw) is not None:
        hint("SCHEMA", "start_lat", start_raw)
    if lat is None:
        # v2-Fallback: getrennte Zeilen start_lat / start_lon
        lat, _ = to_float(start_raw) if clean(start_raw) else (None, False)
        lon, _ = to_float(_feld(d, "trails.start_lon")) if clean(_feld(d, "trails.start_lon")) else (None, False)

    form = key_feld("form") or "linie"
    rundkurs = boolean("rundkurs")
    eintritt = boolean("eintritt")

    trail: Dict[str, Any] = {
        "id": slug,
        "name": text("name"),
        "typ": key_feld("typ"),
        "form": form,
        "land": (text("land") or "").upper() or None,
        "bundesland": text("bundesland"),
        "kreis": text("kreis"),
        "ort": text("ort"),
        "schutzgebiet": text("schutzgebiet"),
        "region": text("region"),
        "betreiber": text("betreiber"),
        "website": text("website"),
        "kurzbeschreibung": text("kurzbeschreibung"),
        "beschreibung": text("beschreibung"),
        "anreise": text("anreise"),
        "besuchshinweise": text("besuchshinweise"),
        "markierung": text("markierung"),
        "start_name": text("start_name"),
        "hoertext": text("hoertext"),
        "start_lat": lat,
        "start_lon": lon,
        "laenge_km": num("laenge_km", to_float),
        "dauer_min": num("dauer_min", to_int),
        "rundkurs": rundkurs,
        "eintritt": eintritt,
        "eintritt_preise": text("eintritt_preise"),
        "oeffnungszeiten": text("oeffnungszeiten"),
        "tags": liste("tags"),
        "naturraum": key_feld("naturraum"),
        "lebensraeume": liste("lebensraeume"),
    }
    # Region: gefuellter Freitext gewinnt, sonst Ort, Kreis, Bundesland
    if not trail["region"]:
        teile = [trail[k] for k in ("ort", "kreis", "bundesland") if trail.get(k)]
        trail["region"] = ", ".join(teile) or None

    stationen = []
    for s in d["stationen"]:
        reihenfolge, k1 = to_int(s.get("reihenfolge"))
        km, k2 = to_float(s.get("km"))
        la, k3 = to_float(s.get("lat"))
        lo, k4 = to_float(s.get("lon"))
        osm_id, _ = to_int(s.get("osm_id"))
        barr, _ = to_bool(s.get("barrierefrei"))
        erleb = [e.lower() for e in to_list(s.get("erlebnisse"))]
        stationen.append({
            "reihenfolge": reihenfolge, "km": km, "lat": la, "lon": lo, "osm_id": osm_id,
            "titel": s.get("titel"), "thema": s.get("thema"), "kurztext": s.get("kurztext"),
            "erlebnisse": erleb, "barrierefrei": bool(barr), "quelle": s.get("quelle"),
            "steckbrief": None,
        })
    # Steckbrief je Station
    for sb in d["steckbrief"]:
        nr, _ = to_int(sb.get("station"))
        key = clean(sb.get("key"))
        if nr is None or key is None:
            continue
        for s in stationen:
            if s["reihenfolge"] == nr:
                s["steckbrief"] = (s["steckbrief"] or {})
                s["steckbrief"][key] = sb.get("wert")

    arten = []
    for a in d["arten"]:
        sort, _ = to_int(a.get("sortierung"))
        sid = clean(a.get("species_id"))
        arten.append({
            "sortierung": sort, "name_de": a.get("name_de"), "name_lat": a.get("name_lat"),
            "species_id": None if (sid is None or sid.upper() == "NEU") else sid,
            "neu": sid is not None and sid.upper() == "NEU",
            "nachweis": (clean(a.get("nachweis")) or "typisch").lower(),
            "quelle": a.get("quelle"),
        })

    bilder = []
    for b in d["bilder"]:
        sort, _ = to_int(b.get("sort"))
        st, _ = to_int(b.get("station"))
        bilder.append({
            "sort": sort, "kind": (clean(b.get("kind")) or "").lower() or None,
            "station_reihenfolge": st, "caption": b.get("caption"), "datei": b.get("datei"),
            "source_url": b.get("source_url"), "license": (clean(b.get("license")) or "").lower() or None,
            "license_url": b.get("license_url"), "credit": b.get("credit"),
        })

    quellen = []
    for nr, a in d["abschnitte"].items():
        for q in a["quellen"]:
            if not (q.get("angabe") or q.get("url")):
                continue
            quellen.append({
                "abschnitt": int(nr), "angabe": q.get("angabe") or "", "url": q.get("url") or "",
                "abgerufen_am": to_date(q.get("abgerufen_am")),
            })

    meta = {
        "template_version": d["template_version"],
        "abschnitte": {nr: a["status"] for nr, a in d["abschnitte"].items()},
        "slug_roh": slug_roh,
        "slug_gueltig": slug_ok,
        "geometrie_datei": clean(_feld(d, "trails.route")),
        "geometrie_quelle": clean(_feld(d, "import.geometrie_quelle")),
        "geometrie_lizenz": (clean(_feld(d, "import.geometrie_lizenz")) or "").lower() or None,
        "pfad_status": clean(_feld(d, "meta.pfad_status")),
        "verworfen_grund": clean(_feld(d, "meta.verworfen_grund")),
        "quellen_je_abschnitt": {nr: len([q for q in a["quellen"] if q.get("angabe") or q.get("url")])
                                 for nr, a in d["abschnitte"].items()},
        "pois_roh": d["pois"],
        "ausstattung_roh": d["ausstattung"],
        "gefuellte_felder": sorted(k for k, f in d["felder"].items() if f["roh"] is not None),
    }
    return {"trail": trail, "stationen": stationen, "arten": arten, "bilder": bilder,
            "quellen": quellen, "meta": meta, "hinweise": hinweise}


def parse_and_normalize(path: str) -> Dict[str, Any]:
    d = parse_docx(path)
    draft = normalize_dossier(d)
    draft["meta"]["lists_version"] = len(lists.LEBENSRAEUME)
    return draft
