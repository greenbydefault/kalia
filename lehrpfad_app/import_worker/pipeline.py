"""Stufen eines Import-Jobs ohne Schreibzugriff auf trails.

  entpacken -> parsen -> Listen korrigieren -> Geometrie -> Bilder -> Arten -> Abgleich -> Regeln

build_draft(root, lookups, ki)     Importlauf, liefert den Entwurf samt Report
validate_state(state, ...)         Validate-Modus: Regeln auf dem DB-Stand neu rechnen

`lookups` kapselt alles, was aus der DB kommt (Arten, Duplikate, vorhandener Pfad, Kandidat).
Tests nutzen eine Fake-Variante.
"""
from __future__ import annotations

import io
import os
import zipfile
from typing import Any, Dict, List, Optional, Tuple

from . import config, geometry_source, matching, rules
from .ai import KI
from .geometry_source import derive_from_geometry, find_file, pick_geometry
from .images import process_bilder
from .lists_fix import fix_lists
from .parse_dossier import DossierFehler, normalize_dossier, parse_docx

MAX_DATEIEN = 600
MAX_ENTPACKT_BYTES = 600 * 1024 * 1024


class ImportFehler(Exception):
    """Dauerhafter Fehler mit Klartext fuer die Oberflaeche (kein Retry)."""


# --------------------------------------------------------------------------
# Entpacken
# --------------------------------------------------------------------------
def entpacken(zip_bytes: bytes, ziel: str) -> str:
    try:
        z = zipfile.ZipFile(io.BytesIO(zip_bytes))
    except zipfile.BadZipFile:
        raise ImportFehler("Die Datei ist kein gültiges ZIP.")
    infos = [i for i in z.infolist() if not i.is_dir()]
    if len(infos) > MAX_DATEIEN:
        raise ImportFehler("Das ZIP enthält zu viele Dateien (%d, erlaubt %d)." % (len(infos), MAX_DATEIEN))
    if sum(i.file_size for i in infos) > MAX_ENTPACKT_BYTES:
        raise ImportFehler("Das ZIP ist entpackt zu groß (mehr als %d MB)." % (MAX_ENTPACKT_BYTES // 1024 // 1024))
    base = os.path.realpath(ziel)
    for i in infos:
        name = i.filename.replace("\\", "/")
        if "__MACOSX/" in name or name.split("/")[-1] in (".DS_Store", "Thumbs.db"):
            continue
        target = os.path.realpath(os.path.join(base, name))
        if not target.startswith(base + os.sep):
            raise ImportFehler("Das ZIP enthält ungültige Pfade.")
        os.makedirs(os.path.dirname(target), exist_ok=True)
        with z.open(i) as src, open(target, "wb") as dst:
            dst.write(src.read())
    return base


def finde_dossier(root: str) -> str:
    docs = []
    for dp, _dn, fn in os.walk(root):
        for f in sorted(fn):
            if f.lower().endswith(".docx") and not f.startswith("~$"):
                docs.append(os.path.join(dp, f))
    if not docs:
        raise ImportFehler("Im ZIP liegt kein Dossier (.docx).")
    if len(docs) > 1:
        pref = [d for d in docs if "dossier" in os.path.basename(d).lower()]
        if len(pref) == 1:
            return pref[0]
        raise ImportFehler("Im ZIP liegen mehrere Word-Dateien (%s). Es darf nur das Dossier dabei sein."
                           % ", ".join(os.path.basename(d) for d in docs[:4]))
    return docs[0]


# --------------------------------------------------------------------------
# Entwurf
# --------------------------------------------------------------------------
def _leer(v: Any) -> bool:
    return v is None or (isinstance(v, str) and not v.strip())


def stationen_trennen(rows: List[Dict[str, Any]]) -> Tuple[List[Dict[str, Any]], List[Dict[str, Any]]]:
    """Vollstaendige Stationen (einfuegbar) und unvollstaendige (nur Meldung)."""
    ok: List[Dict[str, Any]] = []
    bad: List[Dict[str, Any]] = []
    seen: set = set()
    for pos, s in enumerate(rows, 1):
        fehlt = []
        if s.get("reihenfolge") is None:
            fehlt.append("reihenfolge")
        if _leer(s.get("titel")):
            fehlt.append("titel")
        if s.get("lat") is None:
            fehlt.append("lat")
        if s.get("lon") is None:
            fehlt.append("lon")
        if s.get("reihenfolge") in seen:
            fehlt.append("doppelte Nummer")
        if fehlt:
            bad.append({"reihenfolge": s.get("reihenfolge") if s.get("reihenfolge") is not None else pos,
                        "fehlt": ", ".join(fehlt)})
            continue
        seen.add(s["reihenfolge"])
        ok.append({**s, "km": s.get("km") if s.get("km") is not None else 0.0,
                   "thema": s.get("thema") or "", "kurztext": s.get("kurztext") or ""})
    return ok, bad


def build_draft(root: str, lookups, ki: Optional[KI] = None) -> Dict[str, Any]:
    ki = ki or KI(aktiv=False)
    docx_path = finde_dossier(root)
    try:
        roh = parse_docx(docx_path)
        draft = normalize_dossier(roh)
    except DossierFehler as e:
        raise ImportFehler(str(e))
    trail, meta = draft["trail"], draft["meta"]
    meta["lists_version"] = 1
    slug = trail.get("id")
    if not slug:
        raise ImportFehler("Im Dossier fehlt die ID des Pfads (Abschnitt 1).")

    # Listenwerte
    fixes = fix_lists(draft, ki.suggest)

    # Geometrie
    form = trail.get("form") or "linie"
    geo = pick_geometry(root, slug, form, meta)
    trail["route"] = geo["route"]
    trail["area"] = geo["area"]
    derive_from_geometry(trail, geo)

    # Bilder
    bild = process_bilder(root, slug, draft["bilder"], geo["route"], geo["area"], form == "flaeche", find_file)

    # Arten
    idx = matching.SpeciesIndex(lookups.species_rows())
    m = matching.match_arten(draft["arten"], idx)
    offen = m["unbekannt"] + m["unsicher"]
    for a in offen:
        if not a.get("name_lat_guess") and a.get("name_de"):
            a["name_lat_guess"] = ki.suggest_lat(a["name_de"])
    trail["arten"] = [a["species_id"] for a in m["zugeordnet"]]

    stationen, unvollstaendig = stationen_trennen(draft["stationen"])

    # Abgleich
    existing = lookups.trail(slug)
    kollision = bool(existing and not existing.get("source_job_id"))
    dups: List[Dict[str, Any]] = []
    if trail.get("start_lat") is not None and trail.get("start_lon") is not None and trail.get("name"):
        dups = lookups.duplicates(slug, trail["name"], trail["start_lat"], trail["start_lon"])

    ctx = {
        "trail": trail, "stationen": stationen, "stationen_unvollstaendig": unvollstaendig,
        "arten": m["zugeordnet"], "arten_offen": offen, "bilder": bild["bilder"], "meta": meta,
        "hinweise": draft["hinweise"], "list_fixes": fixes, "geo_issues": geo["issues"],
        "bild_issues": bild["issues"], "duplicates": dups, "slug_kollision": kollision,
        "kandidat_vorhanden": lookups.candidate_exists(slug), "kuerzung": ki.kuerzen_cb, "mit_dossier": True,
    }
    report = rules.run_rules(ctx)

    field_meta = ki.field_meta()
    if geo.get("herkunft"):
        key = "area" if form == "flaeche" else "route"
        field_meta[key] = {"quelle": geo["herkunft"], "lizenz": geo.get("lizenz"),
                           "angabe": geo.get("quelle"), "datei": geo.get("datei")}

    return {
        "trail": trail, "stationen": stationen, "stationen_unvollstaendig": unvollstaendig,
        "arten": m["zugeordnet"], "arten_offen": offen, "bilder": bild["bilder"],
        "quellen": draft["quellen"], "meta": meta, "hinweise": draft["hinweise"], "geo": {
            k: geo.get(k) for k in ("herkunft", "quelle", "lizenz", "datei")},
        "list_fixes": fixes, "report": report, "field_meta": field_meta, "roh": roh,
        "slug_kollision": kollision, "duplicates": dups, "existing": existing,
    }


def fuer_speicher(draft: Dict[str, Any]) -> Dict[str, Any]:
    """Draft als JSON fuer import_jobs.parsed (ohne Bild-Bytes und ohne Rohdaten-Dubletten)."""
    out = {k: draft[k] for k in ("trail", "stationen", "stationen_unvollstaendig", "arten", "arten_offen",
                                 "quellen", "meta", "hinweise", "geo", "list_fixes", "duplicates")}
    out["bilder"] = [{k: v for k, v in b.items() if k != "files"} for b in draft["bilder"]]
    out["roh"] = draft.get("roh")
    return out


# --------------------------------------------------------------------------
# Validate-Modus
# --------------------------------------------------------------------------
def validate_state(state: Dict[str, Any], alt_report: List[Dict[str, Any]], lookups,
                   ki: Optional[KI] = None) -> List[Dict[str, Any]]:
    """Regeln auf dem DB-Stand. state: {trail, stationen, arten, arten_offen, bilder}.

    Was nur das Dossier weiss (Abschnittsstatus, Quellen, Dateien, Formkorrekturen), kommt aus dem alten Report.
    """
    trail = state["trail"]
    ki = ki or KI(aktiv=False)
    stationen = [{"reihenfolge": s["reihenfolge"], "km": s.get("km"), "lat": s.get("lat"), "lon": s.get("lon"),
                  "titel": s.get("titel"), "kurztext": s.get("kurztext"), "erlebnisse": s.get("erlebnisse") or []}
                 for s in state.get("stationen") or []]
    dups: List[Dict[str, Any]] = []
    if trail.get("start_lat") is not None and trail.get("start_lon") is not None and trail.get("name"):
        dups = lookups.duplicates(trail["id"], trail["name"], trail["start_lat"], trail["start_lon"])
    ctx = {
        "trail": trail, "stationen": stationen, "arten": state.get("arten") or [],
        "arten_offen": state.get("arten_offen") or [], "bilder": state.get("bilder") or [],
        "meta": {}, "hinweise": [], "list_fixes": [], "geo_issues": [], "bild_issues": [],
        "duplicates": dups, "slug_kollision": False, "kandidat_vorhanden": None,
        "kuerzung": ki.kuerzen_cb, "mit_dossier": False,
    }
    neu = rules.run_rules(ctx)
    neu.extend(rules.carry_over(alt_report, [s["reihenfolge"] for s in stationen]))
    rules.apply_overrides(neu, alt_report)
    rules.carry_status(neu, alt_report)
    return neu
